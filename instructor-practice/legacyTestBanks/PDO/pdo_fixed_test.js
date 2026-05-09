(() => {
	if ("serviceWorker" in navigator && window.location.protocol !== "file:") {
		window.addEventListener("load", () => {
			navigator.serviceWorker.register("../service-worker.js", { scope: "../" })
				.catch((error) => console.warn("Service worker registration failed", error));
		});
	}

	const testNumber = Number(document.body.dataset.testNumber || "1");
	const startIndex = Number(document.body.dataset.startIndex || "0");
	const questionsPerTest = 100;

	const segmentText = document.getElementById("segmentText");
	const quizForm = document.getElementById("quizForm");
	const submitButton = document.getElementById("submitButton");
	const resultsPanel = document.getElementById("resultsPanel");
	const resultsScore = document.getElementById("resultsScore");
	const resultsDetail = document.getElementById("resultsDetail");

	let activeQuestions = [];

	function buildIndices(totalQuestions, firstIndex, count) {
		const indices = [];
		for (let i = 0; i < count; i += 1) {
			indices.push((firstIndex + i) % totalQuestions);
		}
		return indices;
	}

	function buildSegmentLabel(totalQuestions, firstIndex, count) {
		const startHuman = firstIndex + 1;
		const endRaw = firstIndex + count;
		if (endRaw <= totalQuestions) {
			return `Source questions ${startHuman}-${endRaw}`;
		}
		const wrappedEnd = endRaw - totalQuestions;
		return `Source questions ${startHuman}-${totalQuestions} + 1-${wrappedEnd}`;
	}

	function createQuestionImage(question) {
		if (!question.image || !question.image.src) {
			return null;
		}

		const image = document.createElement("img");
		image.className = "question-image";
		image.src = question.image.src;
		image.alt = question.image.alt || "Question reference image";
		image.loading = "lazy";
		return image;
	}

	function buildFormattedPrompt(index, questionText) {
		const prompt = document.createElement("p");
		prompt.className = "question-text";
		const normalized = questionText.replace(/\s+/g, " ").trim();
		const hasStatements = /Statement \d+:/i.test(normalized);
		const introMatch = normalized.match(/^(.*?)(?=Statement \d+:)/i);

		if (hasStatements && introMatch && introMatch[1]) {
			prompt.appendChild(document.createTextNode(`${index + 1}. `));
			const introText = introMatch[1].trim();
			const labeledIntro = introText.match(/^([A-Za-z]+:)(.*)$/);

			if (labeledIntro) {
				const introLabel = document.createElement("strong");
				introLabel.textContent = labeledIntro[1];
				const introUnderline = document.createElement("u");
				introUnderline.appendChild(introLabel);
				prompt.appendChild(introUnderline);
				if (labeledIntro[2] && labeledIntro[2].trim()) {
					prompt.appendChild(document.createTextNode(` ${labeledIntro[2].trim()}`));
				}
			} else {
				prompt.appendChild(document.createTextNode(introText));
			}

			const statementsText = normalized.replace(/^.*?(?=Statement \d+:)/i, "").trim();
			const statementBlocks = statementsText.split(/(?=Statement \d+:)/g).filter(Boolean);

			statementBlocks.forEach((block, statementIndex) => {
				prompt.appendChild(document.createElement("br"));
				if (statementIndex === 0) {
					prompt.appendChild(document.createElement("br"));
				}

				const match = block.match(/^(Statement \d+:)\s*(.*)$/i);
				if (match) {
					const statementLabel = document.createElement("u");
					statementLabel.textContent = match[1];
					prompt.appendChild(statementLabel);
					prompt.appendChild(document.createTextNode(` ${match[2]}`));
				} else {
					prompt.appendChild(document.createTextNode(block));
				}
			});

			return prompt;
		}

		prompt.textContent = `${index + 1}. ${questionText}`;
		return prompt;
	}

	function renderQuiz(questions) {
		quizForm.innerHTML = "";
		const fragment = document.createDocumentFragment();

		questions.forEach((question, index) => {
			const card = document.createElement("section");
			card.className = "question-card";
			card.dataset.questionId = question.id;

			const prompt = buildFormattedPrompt(index, question.question);
			card.appendChild(prompt);

			const questionImage = createQuestionImage(question);
			if (questionImage) {
				card.appendChild(questionImage);
			}

			const options = document.createElement("div");
			options.className = "option-list";

			question.choices.forEach((choice) => {
				const label = document.createElement("label");
				const input = document.createElement("input");
				input.type = "radio";
				input.name = `q${index + 1}`;
				input.value = choice.id;
				label.appendChild(input);
				label.append(` ${choice.id.toUpperCase()}) ${choice.text}`);
				options.appendChild(label);
			});

			const review = document.createElement("p");
			review.className = "review-text";
			review.style.display = "none";
			review.dataset.reviewFor = `q${index + 1}`;

			card.appendChild(options);
			card.appendChild(review);
			fragment.appendChild(card);
		});

		quizForm.appendChild(fragment);
	}

	function gradeQuiz() {
		let score = 0;

		activeQuestions.forEach((question, index) => {
			const questionName = `q${index + 1}`;
			const selected = quizForm.querySelector(`input[name=\"${questionName}\"]:checked`);
			const review = quizForm.querySelector(`[data-review-for=\"${questionName}\"]`);
			const card = quizForm.querySelector(`[data-question-id=\"${question.id}\"]`);

			card.classList.remove("correct", "incorrect");
			review.style.display = "block";

			if (selected && selected.value === question.correctChoiceId) {
				score += 1;
				card.classList.add("correct");
				review.textContent = `Correct: ${question.correctChoiceId.toUpperCase()}) ${question.correctChoiceText}`;
			} else {
				card.classList.add("incorrect");
				const yourAnswer = selected ? selected.value.toUpperCase() : "No answer";
				review.textContent = `Your answer: ${yourAnswer}. Correct: ${question.correctChoiceId.toUpperCase()}) ${question.correctChoiceText}`;
			}

			if (question.reference && (question.reference.section || question.reference.page)) {
				const ref = `${question.reference.section || ""} ${question.reference.page || ""}`.trim();
				if (ref) {
					review.textContent += ` Reference: ${ref}`;
				}
			}
		});

		const percent = Math.round((score / activeQuestions.length) * 100);
		resultsScore.textContent = `Test ${testNumber} Score: ${score} / ${activeQuestions.length} (${percent}%)`;
		resultsDetail.textContent = "Review highlighted questions below. Green cards are correct; red cards need review.";
		resultsPanel.style.display = "block";
		window.scrollTo({ top: 0, behavior: "smooth" });
	}

	fetch("./bank_pdo.json")
		.then((response) => {
			if (!response.ok) {
				throw new Error("Unable to load PDO question bank.");
			}
			return response.json();
		})
		.then((bank) => {
			if (!Array.isArray(bank.questions) || bank.questions.length === 0) {
				throw new Error("PDO bank has no questions.");
			}

			const indices = buildIndices(bank.questions.length, startIndex, questionsPerTest);
			activeQuestions = indices.map((idx) => bank.questions[idx]);
			segmentText.textContent = `${buildSegmentLabel(bank.questions.length, startIndex, questionsPerTest)} | ${questionsPerTest} questions`;
			renderQuiz(activeQuestions);
		})
		.catch((error) => {
			segmentText.textContent = error.message;
			submitButton.disabled = true;
		});

	submitButton.addEventListener("click", gradeQuiz);
})();
