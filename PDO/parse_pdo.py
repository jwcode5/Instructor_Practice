"""
Parse pdo_docx_paragraphs.txt and generate pdo_v1.html in the index_v0.html format.
"""
import re
import html as htmllib
import sys

PARAGRAPHS_FILE = r'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\PDO\pdo_docx_paragraphs.txt'
OUTPUT_FILE = r'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\PDO\pdo_v1.html'

# Lines to skip entirely
SKIP_PATTERNS = [
    r'for PUMPER DRIVER OPERATOR',
    r'PUMPER DRIVER/OPERATOR',
    r'REFERENCE LIST FOR',
    r'REFERENCE UST FOR',
    r'Publisher/Title/Edition',
    r'^NFPA 1002\b',
    r'^IFSTA\b',
    r'^Jones and Bartlett\b',
    r'NFPA 1002 PUMP',
    r'^FIRE APPAR D/O',
    r'^D/O\s+\d',
    r'^SECTION\s+\d',
    r'^\d+\s*$',  # lone page numbers
    r'Reference Code',
]

def should_skip(text):
    for p in SKIP_PATTERNS:
        if re.search(p, text, re.IGNORECASE):
            return True
    return False

def strip_linenum(line):
    """Strip leading line number like '00001: '"""
    m = re.match(r'^\d{5}:\s*(.*)', line.rstrip())
    if m:
        return m.group(1)
    return None

# ---------------------------------------------------------------------------
# Correct-answer marker detection
# The original document marks the correct answer letter with some special
# OCR-corrupt suffix:  BY, AY, CY, DY, A'!', B'f', C-r, A\", Ai, Bt, etc.
# Also: 0-r means D-r (OCR read D as 0), [Y means D ([ read as D).
# ---------------------------------------------------------------------------
CORRECT_RE = re.compile(
    r'^([A-D])'                      # letter A-D
    r'(?:'
    r'[Yy]'                          # Y / y  (most common)
    r"|['\u2019][!f\"'1:r]"          # 'f  '!  '"  '1  ':  'r
    r"|'[!']"                        # '!'
    r'|[-][rt]'                      # -r  -t
    r'|\\\"'                         # \"
    r'|[it](?=\s)'                   # i/t only when followed by space (not alphanumeric)
    r'|[!]'                          # ! alone
    r')'
    r'\s*(.*)',
    re.DOTALL
)

# Special: 0 acts as D (OCR) followed by marker
CORRECT_0_RE = re.compile(
    r'^0(?:[-][rt]|[\'!])'
    r'\s*(.*)',
    re.DOTALL
)

# Special: [ acts as D (OCR): "[Y."
CORRECT_BRACKET_RE = re.compile(r'^\[Y[.!]?\s*(.*)', re.DOTALL)

# Non-ASCII single char at the start = correct marker (bullet/checkmark OCR'd weirdly)
CORRECT_NONASCII_RE = re.compile(r'^[\x80-\xFF\u0080-\uFFFF]\s*(.*)', re.DOTALL)


def check_correct(text):
    """
    Returns (True, letter, clean_text) if this text has a correct-answer marker.
    Returns (False, None, text) otherwise.
    """
    text = text.strip()
    m = CORRECT_RE.match(text)
    if m:
        return True, m.group(1).upper(), m.group(2).strip()

    m = CORRECT_0_RE.match(text)
    if m:
        return True, 'D', m.group(1).strip()

    m = CORRECT_BRACKET_RE.match(text)
    if m:
        return True, 'D', m.group(1).strip()

    m = CORRECT_NONASCII_RE.match(text)
    if m:
        return True, '?', m.group(1).strip()  # letter unknown

    return False, None, text


def get_label(text):
    """
    If text starts with A. B. C. or D. (wrong answer with label preserved),
    returns (letter, rest). Otherwise (None, text).
    Handles both 'A.' and 'A)' styles.
    """
    m = re.match(r'^([A-D])[.)]\s+(.*)', text.strip(), re.DOTALL)
    if m:
        return m.group(1).upper(), m.group(2).strip()
    return None, text.strip()


# ---------------------------------------------------------------------------
# Combined answer line parser
# E.g.: "repair.BY maintenance.C. reliability.D. trouble shooting."
#       "AY routineB. repairC. post-tripD. documentation"
# ---------------------------------------------------------------------------

# Pattern to find option delimiters within a line
# Match: letter + (correct_marker | period/paren + space)
OPTION_DELIM_RE = re.compile(
    r'(?<![A-Z0-9])'           # not preceded by uppercase or digit
    r'([A-D])'                 # letter
    r'('
    r'[Yy]'                    # correct marker Y
    r"|['\u2019][!f\"'1:r]"    # 'f  '!  '"  '1  ':  'r
    r"|'[!']"                  # '!'
    r'|[-][rt]'                # -r  -t
    r'|[!]'                    # !
    r'|[.)]'                   # . or ) for normal wrong answers
    r')'
    r'\s*'
)

def is_combined_line(text):
    """True if line has >=2 option delimiters (likely all answers on one line)."""
    return len(OPTION_DELIM_RE.findall(text)) >= 2


def parse_combined(text):
    """
    Parse a combined answer line into list of (letter, is_correct, answer_text).
    """
    matches = list(OPTION_DELIM_RE.finditer(text))
    if not matches:
        return []

    results = []
    for i, m in enumerate(matches):
        letter = m.group(1).upper()
        marker = m.group(2)
        is_correct = marker not in ('.', ')')

        # Text runs from end of this match to start of next match (or end of string)
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        answer_text = text[start:end].strip().rstrip('.')

        results.append((letter, is_correct, answer_text))

    return results


# ---------------------------------------------------------------------------
# Question parser
# ---------------------------------------------------------------------------

def parse_questions(paragraphs):
    questions = []
    i = 0
    n = len(paragraphs)

    while i < n:
        p = paragraphs[i]

        # Check if this paragraph is an answer line (all combined)
        if is_combined_line(p):
            # This is answer-only; no question text yet—attach to previous question
            if questions:
                q = questions[-1]
                opts = parse_combined(p)
                for letter, is_correct, ans_text in opts:
                    if ans_text:
                        idx = ord(letter) - ord('A')
                        q['options'][idx] = ans_text
                        if is_correct:
                            q['correct'] = letter
            i += 1
            continue

        # Check if this line is a correct-answer or labeled-answer line (separate line)
        is_corr, corr_letter, corr_text = check_correct(p)
        if is_corr:
            # This is a single correct-answer option on its own line
            if questions:
                q = questions[-1]
                idx = ord(corr_letter) - ord('A') if corr_letter != '?' else -1
                if idx >= 0:
                    q['options'][idx] = corr_text
                    q['correct'] = corr_letter
                else:
                    # unknown letter: find first empty slot
                    for sl in range(4):
                        if not q['options'][sl]:
                            q['options'][sl] = corr_text
                            q['correct'] = chr(ord('A') + sl)
                            break
            i += 1
            continue

        label, label_text = get_label(p)
        if label:
            # Wrong answer with label
            if questions:
                q = questions[-1]
                idx = ord(label) - ord('A')
                if not q['options'][idx]:
                    q['options'][idx] = label_text
            i += 1
            continue

        # Otherwise: this is question text (or unlabeled answer, or continuation)
        # Heuristic: if we already have some answers collected for the current
        # question, treat unlabeled text as an unlabeled wrong answer.
        if questions:
            q = questions[-1]
            answers_so_far = sum(1 for o in q['options'] if o)
            if answers_so_far > 0 and answers_so_far < 4:
                # This looks like an unlabeled wrong answer—fill next empty slot
                for sl in range(4):
                    if not q['options'][sl]:
                        q['options'][sl] = p.strip()
                        break
                i += 1
                continue

        # Start a new question
        q = {
            'text': p.strip(),
            'options': ['', '', '', ''],
            'correct': '',
        }
        questions.append(q)

        # Peek ahead: collect continuation lines for the question stem
        # (lines that don't look like answers)
        i += 1
        while i < n:
            nxt = paragraphs[i]
            # Stop collecting question text if the next line is an answer
            if is_combined_line(nxt):
                break
            is_c, _, _ = check_correct(nxt)
            if is_c:
                break
            lbl, _ = get_label(nxt)
            if lbl:
                break
            # If next line looks like more question text, append it
            # (it starts with a lowercase letter or number, or is a generic continuation)
            # But don't eat lines that are unlabeled wrong answers when we have context
            q['text'] = q['text'] + ' ' + nxt.strip()
            i += 1

    return questions


def fill_empty_slots(questions):
    """Post-process: assign correct letter to positional unknowns."""
    for q in questions:
        if q['correct'] == '?':
            # Already handled above (put in first empty)
            pass
        # If correct is still '', look for any non-empty slot (graceful degradation)
    return questions


def escape(s):
    return htmllib.escape(s or '')


def build_html(questions):
    head = '''<!DOCTYPE html>
<html lang="en">
<head>
\t<meta charset="UTF-8">
\t<meta name="viewport" content="width=device-width, initial-scale=1.0">
\t<title>PDO Test Bank Practice</title>
\t<style>
\t\tbody {
\t\t\tfont-family: Arial, sans-serif;
\t\t\tline-height: 1.6;
\t\t\tmax-width: 800px;
\t\t\tmargin: 0 auto;
\t\t\tpadding: 20px;
\t\t}

\t\t.question {
\t\t\tmargin-bottom: 20px;
\t\t\tpadding: 15px;
\t\t\tborder: 1px solid #ddd;
\t\t\tborder-radius: 5px;
\t\t}

\t\t.options {
\t\t\tmargin-left: 20px;
\t\t}

\t\t.correct {
\t\t\tbackground-color: #e6ffe6;
\t\t\tpadding: 10px;
\t\t\tmargin-top: 10px;
\t\t\tborder-radius: 5px;
\t\t\tborder-left: 4px solid #4CAF50
\t\t}

\t\t.incorrect {
\t\t\tbackground-color: #ffe6e6;
\t\t}

\t\t.answer-text {
\t\t\tfont-weight: bold;
\t\t\tcolor: #2E7D32
\t\t}

\t\t#results {
\t\t\tmargin-top: 30px;
\t\t\tpadding: 15px;
\t\t\tborder: 1px solid #333;
\t\t\tborder-radius: 5px;
\t\t\tdisplay: none;
\t\t}

\t\t#score {
\t\t\tfont-weight: bold;
\t\t\tfont-size: 1.2em;
\t\t}

\t\tbutton {
\t\t\tpadding: 10px 15px;
\t\t\tbackground-color: #4CAF50;
\t\t\tcolor: white;
\t\t\tborder: none;
\t\t\tborder-radius: 4px;
\t\t\tcursor: pointer;
\t\t\tfont-size: 16px;
\t\t\tmin-height: 44px;
\t\t\tappearance: none;
\t\t\t-webkit-appearance: none;
\t\t\t-moz-appearance: none;
\t\t}
\t\tbutton:hover {
\t\t\tbackground-color: #45a049;
\t\t}
\t</style>
</head>
<body>
\t<h1>PDO Test Bank Practice</h1>

\t<form id="quizForm">
'''

    body_parts = []
    for idx, q in enumerate(questions, 1):
        qnum = idx
        qtext = escape(q['text'])
        opts = [escape(o) for o in q['options']]
        correct_lower = q['correct'].lower() if q['correct'] else ''

        block = f'''<!-- Question {qnum} -->
<div class="question" id="q{qnum}">
\t<p>{qnum}.   {qtext}</p>
\t<div class="options">
\t\t<div class="question-meta" data-section="TBD" data-page="--" data-correct="{correct_lower}" style="display: none;"></div>
\t\t<label><input type="radio" name="q{qnum}" value="a"> a)    {opts[0]}</label><br>
\t\t<label><input type="radio" name="q{qnum}" value="b"> b)    {opts[1]}</label><br>
\t\t<label><input type="radio" name="q{qnum}" value="c"> c)    {opts[2]}</label><br>
\t\t<label><input type="radio" name="q{qnum}" value="d"> d)    {opts[3]}</label><br>
\t\t\t\t<div class="correct-answer" style="display: none;">
\t\t\tCorrect answer: <span class="answer-text"></span><br>
\t\t\tSection: <span class="section-text"></span> | Page: <span class="page-text"></span>
\t\t</div>
\t</div>
</div>
'''
        body_parts.append(block)

    tail = '''
\t\t<button type="button" onclick="gradeQuiz()">Submit Answers</button>

\t</form>

\t<div id="results">
\t\t<h2>Results</h2>
\t\t<p id="score"></p>
\t\t<div id="answerKey"></div>
\t</div>

\t<script>
\t\tfunction gradeQuiz() {
\t\t\tlet score = 0;
\t\t\tconst resultsDiv = document.getElementById("results");
\t\t\tconst scoreDisplay = document.getElementById("score");
\t\t\tconst answerKeyDisplay = document.getElementById("answerKey");
\t\t\tconst questionDivs = document.querySelectorAll(".question");
\t\t\tconst totalQuestions = questionDivs.length;

\t\t\tanswerKeyDisplay.innerHTML = "";

\t\t\tquestionDivs.forEach((questionDiv) => {
\t\t\t\tconst question = questionDiv.id;
\t\t\t\tconst selectedOption = document.querySelector(`input[name="${question}"]:checked`);
\t\t\t\tconst meta = questionDiv.querySelector(".question-meta");
\t\t\t\tconst correctAnswer = (meta?.dataset?.correct || "").toLowerCase();
\t\t\t\tconst section = meta?.dataset?.section || "TBD";
\t\t\t\tconst page = meta?.dataset?.page || "--";

\t\t\t\tconst correctAnswerText = questionDiv.querySelector(".answer-text");
\t\t\t\tconst sectionText = questionDiv.querySelector(".section-text");
\t\t\t\tconst pageText = questionDiv.querySelector(".page-text");
\t\t\t\tconst correctAnswerContainer = questionDiv.querySelector(".correct-answer");

\t\t\t\tif (correctAnswer) {
\t\t\t\t\tconst correctOption = questionDiv.querySelector(`input[value="${correctAnswer}"]`);
\t\t\t\t\tconst correctText = correctOption ? correctOption.parentElement.textContent.trim() : correctAnswer.toUpperCase();
\t\t\t\t\tif (correctAnswerText) {
\t\t\t\t\t\tcorrectAnswerText.textContent = correctText;
\t\t\t\t\t}
\t\t\t\t}

\t\t\t\tif (sectionText) {
\t\t\t\t\tsectionText.textContent = section;
\t\t\t\t}
\t\t\t\tif (pageText) {
\t\t\t\t\tpageText.textContent = page;
\t\t\t\t}
\t\t\t\tif (correctAnswerContainer) {
\t\t\t\t\tcorrectAnswerContainer.style.display = "block";
\t\t\t\t}

\t\t\t\tif (selectedOption && correctAnswer) {
\t\t\t\t\tif (selectedOption.value === correctAnswer) {
\t\t\t\t\t\tscore++;
\t\t\t\t\t\tquestionDiv.classList.add("correct");
\t\t\t\t\t\tquestionDiv.classList.remove("incorrect");
\t\t\t\t\t} else {
\t\t\t\t\t\tquestionDiv.classList.add("incorrect");
\t\t\t\t\t\tquestionDiv.classList.remove("correct");
\t\t\t\t\t}
\t\t\t\t\tanswerKeyDisplay.innerHTML += `
\t\t\t\t\t\t<p><strong>Question ${question.substring(1)}:</strong>
\t\t\t\t\t\tYou selected ${selectedOption.value.toUpperCase()}.
\t\t\t\t\t\tCorrect answer is ${correctAnswer.toUpperCase()}. (${section}, p. ${page})</p>`;
\t\t\t\t} else {
\t\t\t\t\tquestionDiv.classList.remove("correct", "incorrect");
\t\t\t\t\tconst selectedText = selectedOption
\t\t\t\t\t\t? `You selected ${selectedOption.value.toUpperCase()}.`
\t\t\t\t\t\t: "You didn't answer.";
\t\t\t\t\tanswerKeyDisplay.innerHTML += `
\t\t\t\t\t\t<p><strong>Question ${question.substring(1)}:</strong>
\t\t\t\t\t\t${selectedText}
\t\t\t\t\t\tCorrect answer is ${correctAnswer ? correctAnswer.toUpperCase() : "N/A"}. (${section}, p. ${page})</p>`;
\t\t\t\t}
\t\t\t});

\t\t\tconst percentage = totalQuestions ? Math.round((score / totalQuestions) * 100) : 0;
\t\t\tscoreDisplay.textContent = `You scored ${score} out of ${totalQuestions} (${percentage}%)`;
\t\t\tresultsDiv.style.display = "block";
\t\t}
\t</script>
</body>
</html>
'''

    return head + '\n'.join(body_parts) + tail


def main():
    # Read the paragraphs file
    raw_paragraphs = []
    with open(PARAGRAPHS_FILE, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            text = strip_linenum(line)
            if text is None:
                continue
            text = text.strip()
            if not text:
                continue
            if should_skip(text):
                continue
            raw_paragraphs.append(text)

    print(f"Loaded {len(raw_paragraphs)} non-empty paragraphs")

    # Now parse into questions
    questions = parse_questions(raw_paragraphs)
    questions = fill_empty_slots(questions)

    # Filter out questions with no meaningful content
    valid = [q for q in questions if q['text'] and any(q['options'])]
    print(f"Parsed {len(valid)} questions")

    # Stats
    with_correct = sum(1 for q in valid if q['correct'])
    print(f"  {with_correct} have a correct answer identified")
    four_options = sum(1 for q in valid if all(q['options']))
    print(f"  {four_options} have all 4 options filled")

    # Build HTML
    html_content = build_html(valid)

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(html_content)

    print(f"Wrote {OUTPUT_FILE}")


if __name__ == '__main__':
    main()
