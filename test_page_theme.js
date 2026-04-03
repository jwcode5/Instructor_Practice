(() => {
	const body = document.body;
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
		<p class="header-subtitle">Fixed question-bank test</p>
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
	}

	if (typeof window.gradeQuiz === "function") {
		const originalGradeQuiz = window.gradeQuiz;
		window.gradeQuiz = function themedGradeQuiz(...args) {
			originalGradeQuiz.apply(this, args);
			results.style.display = "block";
			window.scrollTo({ top: 0, behavior: "smooth" });
		};
	}
})();