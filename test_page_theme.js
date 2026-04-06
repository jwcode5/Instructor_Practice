(() => {
	const body = document.body;
	if ("serviceWorker" in navigator && window.location.protocol !== "file:") {
		window.addEventListener("load", () => {
			navigator.serviceWorker.register("../service-worker.js", { scope: "../" })
				.catch((error) => console.warn("Service worker registration failed", error));
		});
	}

	if (!body || body.dataset.testPageEnhanced === "true") {
		return;
	}

	body.dataset.testPageEnhanced = "true";
	body.classList.add("test-page");

	const path = window.location.pathname.replace(/\\/g, "/");
	const folder = path.split("/").filter(Boolean).slice(-2, -1)[0] || "";
	const pageConfig = {
		instructor1: {
			practiceHref: "practice_instructor1.html"
		},
		officer1: {
			practiceHref: "practice_officer1.html"
		},
		officer2: {
			practiceHref: "practice_officer2.html"
		}
	};

	const config = pageConfig[folder];
	const existingTitle = document.querySelector("body > h1");
	const quizForm = document.getElementById("quizForm");
	const results = document.getElementById("results");
	if (!existingTitle || !quizForm || !results || !config) {
		return;
	}

	const titleText = existingTitle.textContent.trim();

	const header = document.createElement("header");
	header.className = "page-header";
	header.innerHTML = `
		<div class="maltese-cross header-cross"></div>
		<h1>${titleText}</h1>
		<p class="header-subtitle">Fixed 100-question test</p>
	`;
	body.insertBefore(header, body.firstChild);
	existingTitle.remove();

	const toolbar = document.createElement("div");
	toolbar.className = "test-toolbar";
	toolbar.innerHTML = `
		<a class="button-link" href="./index.html">Back to class</a>
		<a class="button-link" href="./${config.practiceHref}">Practice Builder</a>
		<a class="button-link" href="../index.html">Home</a>
	`;

	const main = document.createElement("main");
	body.insertBefore(main, results);
	main.appendChild(toolbar);
	main.appendChild(results);
	main.appendChild(quizForm);

	const disclaimer = document.createElement("p");
	disclaimer.className = "site-disclaimer";
	disclaimer.innerHTML = "<strong>Note:</strong> Practice content has not been independently validated. Use at your own discretion.";
	body.appendChild(disclaimer);

	const submitButton = quizForm.querySelector('button[type="button"]');
	if (submitButton) {
		submitButton.classList.add("primary-button");
		submitButton.textContent = "Submit Test";
	}

	results.innerHTML = `
		<div id="score"></div>
		<p id="resultsDetail"></p>
		<div id="answerKey"></div>
	`;

	function optionText(questionDiv, choiceId) {
		const option = questionDiv.querySelector(`input[value="${choiceId}"]`);
		return option ? option.parentElement.textContent.trim() : choiceId.toUpperCase();
	}

	window.gradeQuiz = function themedGradeQuiz() {
		let score = 0;
		const scoreDisplay = document.getElementById("score");
		const resultsDetail = document.getElementById("resultsDetail");
		const questionDivs = document.querySelectorAll(".question");
		const totalQuestions = questionDivs.length;

		questionDivs.forEach((questionDiv) => {
			const question = questionDiv.id;
			const selectedOption = document.querySelector(`input[name="${question}"]:checked`);
			const meta = questionDiv.querySelector(".question-meta");
			const correctAnswer = (meta?.dataset?.correct || "").toLowerCase();
			const review = questionDiv.querySelector(".correct-answer");

			questionDiv.classList.remove("correct", "incorrect");
			if (!correctAnswer) {
				if (review) {
					review.style.display = "none";
				}
				return;
			}

			if (selectedOption && selectedOption.value === correctAnswer) {
				score += 1;
				questionDiv.classList.add("correct");
				if (review) {
					review.style.display = "block";
					review.textContent = `Correct: ${optionText(questionDiv, correctAnswer)}`;
				}
			} else {
				questionDiv.classList.add("incorrect");
				const yourAnswer = selectedOption ? selectedOption.value.toUpperCase() : "No answer";
				if (review) {
					review.style.display = "block";
					review.textContent = `Your answer: ${yourAnswer}. Correct: ${optionText(questionDiv, correctAnswer)}`;
				}
			}
		});

		const percent = totalQuestions ? Math.round((score / totalQuestions) * 100) : 0;
		scoreDisplay.textContent = `Score: ${score} / ${totalQuestions} (${percent}%)`;
		resultsDetail.textContent = "Review highlighted questions below. Green cards are correct; red cards need review.";
		results.style.display = "block";
		window.scrollTo({ top: 0, behavior: "smooth" });
	};
})();