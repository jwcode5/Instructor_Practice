import os
import re
import sys

def parse_quiz_questions(lines):
    questions = []
    i = 0
    questions = []
    while i < len(lines):
        line = lines[i]
        # Skip blank lines
        if not line.strip():
            i += 1
            continue
        # Question: any whitespace then number and period
        if re.match(r'^\s*\d+\.', line):
            qtext_raw = line.strip().split('. ', 1)[1] if '. ' in line.strip() else line.strip()[2:]
            # Remove trailing (###) and extract page number
            match = re.match(r'^(.*?)(?:\s*\((\w+-?\w*)\))?$', qtext_raw)
            if match:
                qtext = match.group(1).strip()
                page = match.group(2) or ''
            else:
                qtext = qtext_raw
                page = ''
            options = []
            for j in range(1, 5):
                if i + j < len(lines) and re.match(r'^\s*[A-D]\. ', lines[i + j]):
                    options.append(lines[i + j].strip()[3:])
                else:
                    options.append('')
            # Placeholder metadata for demonstration; update extraction as needed
            questions.append({
                'question': qtext,
                'options': options,
                'answer': '',
                'page': page,
                'complexity': '',
                'a_head': '',
                'subject': '',
                'title': '',
                'feedback': ''
            })
            i += 5
            continue
        # Debug: print lines that look like questions but don't match regex
        elif '.        ' in line:
            pass
        i += 1
    return questions

def extract_page_number(qtext_raw):
    # Remove trailing (###) and return page number
    match = re.match(r'^(.*?)(?:\s*\((\w+-?\w*)\))?$', qtext_raw)
    if match:
        qtext = match.group(1).strip()
        page = match.group(2) or ''
        return qtext, page
    return qtext_raw, ''

def format_question_html(qnum, q):
    # Compose metadata attributes for .question-meta
    meta_attrs = [
        f'data-correct="{q.get("answer", "")}"',
        f'data-complexity="{q.get("complexity", "")}"',
        f'data-a_head="{q.get("a_head", "")}"',
        f'data-subject="{q.get("subject", "")}"',
        f'data-title="{q.get("title", "")}"',
        f'data-feedback="{q.get("feedback", "")}"'
    ]
    if q.get("page"): meta_attrs.append(f'data-page="{q["page"]}"')
    html = f'<div class="question" id="q{qnum}">\n'
    html += f'    <p><strong>{qnum}. {q["question"]}</strong></p>\n'
    html += '    <div class="options">\n'
    html += f'        <div class="question-meta" {' '.join(meta_attrs)} style="display: none;"></div>\n'
    # Check if all options are empty (short answer)
    if all(opt.strip() == '' for opt in q['options']):
        html += '        <input type="text" name="q{0}" class="short-answer" placeholder="Type your answer here..."><br>\n'.format(qnum)
    else:
        for idx, opt in enumerate(q['options']):
            letter = chr(ord('a') + idx)
            html += f'        <label><input type="radio" name="q{qnum}" value="{letter}"> {letter}) {opt}</label><br>\n'
    html += '        <div class="correct-answer" style="display: none;">\n'
    html += '            Correct answer: <span class="answer-text"></span><br>\n'
    html += '        </div>\n'
    html += '    </div>\n</div>\n'
    return html

def process_file(input_path, output_path):
    with open(input_path, 'r', encoding='utf-8') as f:
        lines = [line.rstrip('\n') for line in f]
    questions = parse_quiz_questions(lines)
    with open(output_path, 'w', encoding='utf-8') as f:
        for i, q in enumerate(questions, 1):
            f.write(format_question_html(i, q))
    print(f"Formatted questions written to {output_path}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python quiz_format.py <folder>")
        sys.exit(1)
    folder = sys.argv[1]
    files = [f for f in os.listdir(folder) if os.path.isfile(os.path.join(folder, f)) and f.lower().endswith('.txt')]
    files.sort()
    for fname in files:
        input_path = os.path.join(folder, fname)
        chapter_match = re.search(r'(\d+)', fname)
        if 'addendum' in fname.lower():
            outname = 'Chapter_Addendum_Quiz.html'
        else:
            chapter_num = chapter_match.group(1) if chapter_match else 'X'
            outname = f'Chapter_{chapter_num}_Quiz.html'
        output_path = os.path.join(folder, outname)
        process_file(input_path, output_path)

if __name__ == "__main__":
    main()
