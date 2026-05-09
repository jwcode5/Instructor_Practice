import sys
import os
import re
import json
from bs4 import BeautifulSoup
from datetime import datetime

def extract_number(filename):
    match = re.search(r'(\d+)', filename)
    return int(match.group(1)) if match else None

def get_range_files(start_file, end_file, folder):
    files = [f for f in os.listdir(folder) if f.startswith('Chapter_') and f.endswith('.html')]
    files_with_num = [(f, extract_number(f)) for f in files]
    numbered = [t for t in files_with_num if t[1] is not None]
    numbered.sort(key=lambda x: x[1])
    # If start or end file is not numbered, use min/max chapter number
    start_num = extract_number(start_file)
    end_num = extract_number(end_file)
    if start_num is None and numbered:
        start_num = min(n for _, n in numbered)
    if end_num is None and numbered:
        end_num = max(n for _, n in numbered)
    # Numbered files in range
    ranged_files = [os.path.join(folder, f) for f, n in numbered if start_num <= n <= end_num]
    # Addendum and quiz files (not numbered, e.g., Chapter_Addendum.html, Chapter_Addendum_Quiz.html, Chapter_01_Quiz.html)
    extra_files = [os.path.join(folder, f) for f, n in files_with_num if n is None]
    return ranged_files + sorted(extra_files)

def parse_questions_from_html(html_path, file_id_prefix):
    with open(html_path, encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')
    questions = []
    for idx, qdiv in enumerate(soup.find_all('div', class_='question'), 1):
        # Ignore short answer (no options)
        options = []
        for label in qdiv.find_all('label'):
            input_tag = label.find('input')
            if input_tag:
                cid = input_tag.get('value')
                ctext = label.get_text(strip=True)
                options.append({'id': cid, 'text': ctext[cid.__len__()+2:] if ctext.startswith(f'{cid})') else ctext})
        if not options or all(not o['text'].strip() for o in options):
            continue  # skip short answer or empty
        qid = f"{file_id_prefix}-q{str(idx).zfill(4)}"
        p = qdiv.find('p')
        question_text = p.get_text(strip=True) if p else ''
        question_text = re.sub(r'^\d+\.\s*', '', question_text)
        meta = qdiv.find('div', class_='question-meta')
        correct_id = ''
        correct_text = ''
        # Use data-correct for answer id
        if meta and meta.get('data-correct'):
            correct_id = meta.get('data-correct').strip()
        # Always set correctChoiceText to the text of the matching choice
        if correct_id:
            for o in options:
                if o['id'].lower() == correct_id.lower():
                    correct_text = o['text']
                    break
        qdata = {
            'id': qid,
            'question': question_text,
            'choices': options,
            'correctChoiceId': correct_id,
            'correctChoiceText': correct_text,
            'reference': {
                'section': meta.get('data-a_head', '') if meta else '',
                'page': meta.get('data-feedback', '') if meta else ''
            },
            'source': {
                'firstSeenFile': os.path.basename(html_path),
                'firstSeenQuestionNumber': idx,
                'firstSeenVersion': 1
            },
            'complexity': meta.get('data-complexity', '') if meta else '',
            'a_head': meta.get('data-a_head', '') if meta else '',
            'subject': meta.get('data-subject', '') if meta else '',
            'title': meta.get('data-title', '') if meta else '',
            'feedback': meta.get('data-feedback', '') if meta else ''
        }
        questions.append(qdata)
    return questions

def main():
    if len(sys.argv) != 4:
        print("Usage: python build_bank.py <folder> <start_file.html> <end_file.html>")
        sys.exit(1)
    folder = sys.argv[1]
    start_file = sys.argv[2]
    end_file = sys.argv[3]
    files = get_range_files(start_file, end_file, folder)
    if not files:
        print("No files found in range.")
        sys.exit(1)
    bank = {
        "bank": os.path.basename(folder),
        "generatedAtUtc": datetime.utcnow().isoformat() + "Z",
        "sourceFiles": [],
        "totalSourceQuestions": 0,
        "uniqueQuestions": 0,
        "dedupeMethod": "exact_normalized_question_text_keep_first_version",
        "questions": []
    }
    for html_file in files:
        file_id_prefix = os.path.splitext(os.path.basename(html_file))[0].lower()
        questions = parse_questions_from_html(html_file, file_id_prefix)
        bank["questions"].extend(questions)
        bank["sourceFiles"].append(os.path.basename(html_file))
        bank["totalSourceQuestions"] += len(questions)
    bank["uniqueQuestions"] = len(bank["questions"])
    out_path = os.path.join(folder, "bank.json")
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(bank, f, indent=4, ensure_ascii=False)
    print(f"Bank file written to {out_path} with {bank['uniqueQuestions']} questions.")

if __name__ == "__main__":
    main()
