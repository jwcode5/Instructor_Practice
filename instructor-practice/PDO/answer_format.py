import os
import re
from bs4 import BeautifulSoup

# --- CONFIG ---

QUIZ_FOLDER = 'Quizzes'
TEST_FOLDER = 'Tests'
ANSWER_FOLDER = 'Answers'

# Helper: map answer file to quiz file
# e.g., Chapter 03 Answers.txt -> Chapter_03_Quiz.html


# Map answer file to possible quiz/test files
def answer_to_target_filenames(answer_filename):
    match = re.search(r'Chapter\s*(\d+)', answer_filename)
    if match:
        num = match.group(1).zfill(2)
        return [
            f'Chapter_{num}_Quiz.html',
            f'Chapter_{num}.html'  # For tests
        ]
    # Handle Addendum
    if 'addendum' in answer_filename.lower():
        return [
            'Chapter_Addendum_Quiz.html',
            'Chapter_Addendum.html'
        ]
    return []

# Parse answers, handling * as line break for short answers
def parse_answers(answer_path):
    answers = []
    with open(answer_path, encoding='utf-8') as f:
        lines = [line.rstrip() for line in f if line.strip()]
    i = 0
    while i < len(lines):
        line = lines[i]
        # Only process lines that start with a number and period (e.g., '1.        D' or '12.        Answers...')
        m = re.match(r'^\s*(\d+)\.\s*(.+)', line)
        if m:
            answer = m.group(2)
            # Collect continuation lines for multi-line short answers
            while i + 1 < len(lines) and lines[i + 1].startswith('*'):
                answer += '<br>' + lines[i + 1][1:].lstrip()
                i += 1
            answers.append(answer.strip())
        i += 1
    return answers

# Embed answers into quiz HTML

def embed_answers(quiz_path, answers):
    with open(quiz_path, encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')
    questions = soup.find_all('div', class_='question')
    for i, (qdiv, ans) in enumerate(zip(questions, answers)):
        # Find the .question-meta div inside this question
        meta = qdiv.find('div', class_='question-meta')
        if meta is not None:
            meta['data-correct'] = ans
        # Optionally, also fill the .answer-text span for preview
        ans_span = qdiv.find('span', class_='answer-text')
        if ans_span is not None:
            ans_span.clear()
            ans_span.append(BeautifulSoup(ans, 'html.parser'))
    with open(quiz_path, 'w', encoding='utf-8') as f:
        f.write(str(soup))

# Main batch process

def main():
    for fname in os.listdir(ANSWER_FOLDER):
        if not fname.lower().endswith('.txt'):
            continue
        target_fnames = answer_to_target_filenames(fname)
        if not target_fnames:
            print(f"[WARN] Could not map {fname} to quiz/test file.")
            continue
        answer_path = os.path.join(ANSWER_FOLDER, fname)
        found = False
        for target_fname in target_fnames:
            # Try Quizzes folder first, then Tests folder
            for folder in [QUIZ_FOLDER, TEST_FOLDER]:
                target_path = os.path.join(folder, target_fname)
                if os.path.exists(target_path):
                    answers = parse_answers(answer_path)
                    embed_answers(target_path, answers)
                    print(f"Embedded answers into {target_fname} in {folder}")
                    found = True
        if not found:
            print(f"[WARN] No quiz/test file found for: {fname}")

if __name__ == '__main__':
    main()
