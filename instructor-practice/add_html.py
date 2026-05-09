import sys
import re
import os

def extract_chapter_number(filename):
    match = re.search(r'(?:ch|chapter)(\d+)', filename, re.IGNORECASE)
    if match:
        return match.group(1)
    match = re.search(r'(\d+)', filename)
    if match:
        return match.group(1)
    return "*"


# Use single curly braces in JS/CSS for output, double only for Python formatting
HEADER_TEMPLATE = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Bank Practice</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }}
        .question {{
            margin-bottom: 20px;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 5px;
        }}
        .options {{
            margin-left: 20px;
        }}
        .correct {{
            background-color: #e6ffe6;
            padding: 10px;
            margin-top: 10px;
            border-radius: 5px;
            border-left: 4px solid #4CAF50
        }}
        .incorrect {{
            background-color: #ffe6e6;
        }}
        .answer-text {{
            font-weight: bold;
            color: #2E7D32
        }}
        #results {{
            margin-top: 30px;
            padding: 15px;
            border: 1px solid #333;
            border-radius: 5px;
            display: none;
        }}
        #score {{
            font-weight: bold;
            font-size: 1.2em;
        }}
        button {{
            padding: 10px 15px;
            background-color: #4CAF50;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
           min-height: 44px;
            appearance: none;
            -webkit-appearance: none;
            -moz-appearance: none;
        }}
        button:hover {{
            background-color: #45a049;
        }}
    </style>
    <link rel="stylesheet" href="../style.css">
    <link rel="stylesheet" href="../test_page_theme.css">
</head>
<body>
    <h1>{classname} Chapter {chapter} Practice</h1>
    <form id="quizForm">
'''

FOOTER_TEMPLATE = '''    <button type="button" onclick="gradeQuiz()">Submit Answers</button>
    </form>
    <div id="results">
        <h2>Results</h2>
        <p id="score"></p>
        <div id="answerKey"></div>
    </div>
    <script>
        function gradeQuiz() {
            let score = 0;
            const resultsDiv = document.getElementById("results");
            const scoreDisplay = document.getElementById("score");
            const answerKeyDisplay = document.getElementById("answerKey");
            const questionDivs = document.querySelectorAll(".question");
            const totalQuestions = questionDivs.length;
            answerKeyDisplay.innerHTML = "";
            questionDivs.forEach((questionDiv) => {
                const question = questionDiv.id;
                const selectedOption = document.querySelector(`input[name="${question}"]:checked`);
                const meta = questionDiv.querySelector(".question-meta");
                const correctAnswer = (meta?.dataset?.correct || "").toLowerCase();
                const correctAnswerText = questionDiv.querySelector(".answer-text");
                const correctAnswerContainer = questionDiv.querySelector(".correct-answer");
                if (correctAnswer) {
                    const correctOption = questionDiv.querySelector(`input[value="${correctAnswer}"]`);
                    const correctText = correctOption ? correctOption.parentElement.textContent.trim() : correctAnswer.toUpperCase();
                    if (correctAnswerText) {
                        correctAnswerText.textContent = correctText;
                    }
                }
                if (correctAnswerContainer) {
                    correctAnswerContainer.style.display = "block";
                }
                if (selectedOption && correctAnswer) {
                    if (selectedOption.value === correctAnswer) {
                        score++;
                        questionDiv.classList.add("correct");
                        questionDiv.classList.remove("incorrect");
                    } else {
                        questionDiv.classList.add("incorrect");
                        questionDiv.classList.remove("correct");
                    }
                    answerKeyDisplay.innerHTML += `
                        <p><strong>Question ${question.substring(1)}:</strong>
                        You selected ${selectedOption.value.toUpperCase()}.
                        Correct answer is ${correctAnswer.toUpperCase()}.</p>`;
                } else {
                    questionDiv.classList.remove("correct", "incorrect");
                    const selectedText = selectedOption
                        ? `You selected ${selectedOption.value.toUpperCase()}.`
                        : "You didn't answer.";
                    answerKeyDisplay.innerHTML += `
                        <p><strong>Question ${question.substring(1)}:</strong>
                        ${selectedText}
                        Correct answer is ${correctAnswer ? correctAnswer.toUpperCase() : "N/A"}.</p>`;
                }
            });
            const percentage = totalQuestions ? Math.round((score / totalQuestions) * 100) : 0;
            scoreDisplay.textContent = `You scored ${score} out of ${totalQuestions} (${percentage}%)`;
            resultsDiv.style.display = "block";
        }
    </script>
    <script src="../test_page_theme.js"></script>
</body>
</html>
'''

def strip_existing_header(html):
    form_match = re.search(r'<form[^>]*id=["\']quizForm["\'][^>]*>', html, re.IGNORECASE)
    if form_match:
        start = form_match.end()
        return html[start:]
    body_match = re.search(r'<body[^>]*>', html, re.IGNORECASE)
    if body_match:
        start = body_match.end()
        return html[start:]
    return html

def strip_existing_footer(html):
    form_end = re.search(r'</form\s*>', html, re.IGNORECASE)
    if form_end:
        return html[:form_end.end()]
    results_div = re.search(r'<div[^>]+id=["\']results["\'][^>]*>', html, re.IGNORECASE)
    if results_div:
        return html[:results_div.start()]
    script_tag = re.search(r'<script', html, re.IGNORECASE)
    if script_tag:
        return html[:script_tag.start()]
    return html

def process_file(filename, classname):
    chapter = extract_chapter_number(os.path.basename(filename))
    with open(filename, 'r', encoding='utf-8') as f:
        html = f.read()
    body = strip_existing_header(html)
    body = strip_existing_footer(body)
    new_html = HEADER_TEMPLATE.format(classname=classname, chapter=chapter) + body + FOOTER_TEMPLATE
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(new_html)
    print(f"Header and footer added to {filename} (Class: {classname}, Chapter: {chapter})")

def main():
    if len(sys.argv) < 2:
        print("Usage: python add_html.py <html_file_or_folder> [Class Name]")
        sys.exit(1)
    target = sys.argv[1]
    classname = sys.argv[2] if len(sys.argv) > 2 else "HazMat A&O"
    files = []
    if os.path.isdir(target):
        for fname in os.listdir(target):
            if fname.lower().endswith('.html'):
                files.append(os.path.join(target, fname))
    else:
        files = [target]
    for f in files:
        process_file(f, classname)

if __name__ == "__main__":
    main()
