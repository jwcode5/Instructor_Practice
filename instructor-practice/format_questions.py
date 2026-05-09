
import os
import sys
import re

def parse_questions(input_filename):
    with open(input_filename, 'r', encoding='utf-8') as f:
        lines = [line.rstrip() for line in f]
    questions = []
    i = 0
    # Skip all lines until the first question (numbered line)
    while i < len(lines) and not re.match(r'\d+\. ', lines[i]):
        i += 1
    while i < len(lines):
        # Find the start of a question (numbered)
        if re.match(r'\d+\. ', lines[i]):
            qtext = lines[i].split('. ', 1)[1].strip()
            # Next 4 lines are answers (A–D)
            answers = []
            for j in range(1, 5):
                if i + j < len(lines) and re.match(r'[A-D]\)', lines[i + j].strip()):
                    answers.append(lines[i + j].strip()[2:].strip())
                else:
                    answers.append('')
            # Skip to metadata (look for 'Ans:' or 'Answer:')
            meta = {}
            k = i + 5
            while k < len(lines) and not (lines[k].strip().lower().startswith('ans:') or lines[k].strip().lower().startswith('answer:')):
                k += 1
            if k < len(lines):
                if lines[k].strip().lower().startswith('ans:') or lines[k].strip().lower().startswith('answer:'):
                    meta['correct'] = lines[k].split(':', 1)[1].strip().lower()
            # Next lines: Complexity, A Head/Ahead, Subject, Title, Feedback
            field_map = {
                'complexity': ['complexity'],
                'a_head': ['a head', 'ahead'],
                'subject': ['subject'],
                'title': ['title'],
                'feedback': ['feedback']
            }
            for field, variants in field_map.items():
                k += 1
                if k < len(lines):
                    line_lower = lines[k].strip().lower()
                    for variant in variants:
                        if line_lower.startswith(variant + ':'):
                            meta[field] = lines[k].split(':', 1)[1].strip()
                            break
            questions.append({
                'question': qtext,
                'answers': answers,
                'meta': meta
            })
            # Move i to the next line after the last metadata field
            i = k + 1
            # Skip any blank or non-question lines until the next question or EOF
            while i < len(lines) and not re.match(r'\d+\. ', lines[i]):
                i += 1
        else:
            i += 1
    return questions

def format_question_html(qnum, q):
    meta_attrs = ' '.join([
        f'data-{k}="{v}"' for k, v in q['meta'].items()
    ])
    html = f'<div class="question" id="q{qnum}">\n'
    html += f'    <p><strong>{qnum}. {q["question"]}</strong></p>\n'
    html += '    <div class="options">\n'
    html += f'        <div class="question-meta" {meta_attrs} style="display: none;"></div>\n'
    for idx, ans in enumerate(q['answers']):
        letter = chr(ord('a') + idx)
        html += f'        <label><input type="radio" name="q{qnum}" value="{letter}"> {letter}) {ans}</label><br>\n'
    html += '        <div class="correct-answer" style="display: none;">\n'
    html += '            Correct answer: <span class="answer-text"></span><br>\n'
    html += '        </div>\n'
    html += '    </div>\n</div>\n'
    return html

def main():
    if len(sys.argv) < 2:
        print("Usage: python format_questions.py input_filename.txt")
        sys.exit(1)
    input_filename = sys.argv[1]
    chapter_match = re.search(r'(\d+)', input_filename)
    chapter_num = chapter_match.group(1) if chapter_match else 'X'
    # Write output HTML to same directory as input file
    input_dir = os.path.dirname(input_filename)
    output_filename = os.path.join(input_dir, f'Chapter_{chapter_num}.html')
    questions = parse_questions(input_filename)
    with open(output_filename, 'w', encoding='utf-8') as f:
        for i, q in enumerate(questions, 1):
            f.write(format_question_html(i, q))
    print(f"Formatted questions written to {output_filename}")

if __name__ == "__main__":
    main()
