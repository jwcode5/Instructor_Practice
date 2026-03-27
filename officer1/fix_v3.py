import re

v3_file = r'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\officer1\officer1_v3.html'

# Answer key
answer_key = {
    'q1': 'b', 'q2': 'b', 'q3': 'a', 'q4': 'b', 'q5': 'a', 'q6': 'c', 'q7': 'd', 'q8': 'd', 'q9': 'a', 'q10': 'c',
    'q11': 'a', 'q12': 'c', 'q13': 'b', 'q14': 'b', 'q15': 'b', 'q16': 'a', 'q17': 'a', 'q18': 'c', 'q19': 'c', 'q20': 'b',
    'q21': 'b', 'q22': 'b', 'q23': 'a', 'q24': 'a', 'q25': 'c', 'q26': 'c', 'q27': 'b', 'q28': 'd', 'q29': 'b', 'q30': 'a',
    'q31': 'c', 'q32': 'a', 'q33': 'b', 'q34': 'a', 'q35': 'a', 'q36': 'b', 'q37': 'a', 'q38': 'd', 'q39': 'd', 'q40': 'd',
    'q41': 'c', 'q42': 'c', 'q43': 'd', 'q44': 'b', 'q45': 'd', 'q46': 'c', 'q47': 'd', 'q48': 'a', 'q49': 'a', 'q50': 'c',
    'q51': 'b', 'q52': 'a', 'q53': 'b', 'q54': 'a', 'q55': 'a', 'q56': 'b', 'q57': 'a', 'q58': 'b', 'q59': 'a', 'q60': 'a',
    'q61': 'd', 'q62': 'c', 'q63': 'c', 'q64': 'b', 'q65': 'a', 'q66': 'b', 'q67': 'a', 'q68': 'c', 'q69': 'b', 'q70': 'a',
    'q71': 'd', 'q72': 'a', 'q73': 'a', 'q74': 'c', 'q75': 'a', 'q76': 'd', 'q77': 'c', 'q78': 'c', 'q79': 'a', 'q80': 'd',
    'q81': 'b', 'q82': 'b', 'q83': 'c', 'q84': 'd', 'q85': 'b', 'q86': 'a', 'q87': 'b', 'q88': 'a', 'q89': 'b', 'q90': 'a',
    'q91': 'b', 'q92': 'b', 'q93': 'a', 'q94': 'b', 'q95': 'c', 'q96': 'd', 'q97': 'b', 'q98': 'd', 'q99': 'd', 'q100': 'd'
}

with open(v3_file, 'r', encoding='utf-8') as f:
    content = f.read()

# For each question 1-100, find the corresponding <div class="options"> and insert metadata after it
for q_num in range(1, 101):
    q_id = f'q{q_num}'
    answer = answer_key[q_id]
    
    # Find the pattern: id="qN" ... <div class="options">
    # Need to insert metadata block right after <div class="options">
    pattern = f'(id="{q_id}"[^>]*>.*?<div class="options">)'
    metadata = f'\n\t\t<div class="question-meta" data-section="TBD" data-page="--" data-correct="{answer}" style="display: none;"></div>'
    replacement = f'\\1{metadata}'
    
    content = re.sub(pattern, replacement, content, count=1, flags=re.DOTALL)

# Update .correct-answer display format
old_format = '''<div class="correct-answer" style="display: none;">
			Correct answer: <span class="answer-text"></span>
		</div>'''

new_format = '''<div class="correct-answer" style="display: none;">
			Correct answer: <span class="answer-text"></span><br>
			Section: <span class="section-text"></span> | Page: <span class="page-text"></span>
		</div>'''

content = content.replace(old_format, new_format)

with open(v3_file, 'w', encoding='utf-8') as f:
    f.write(content)

print("V3 metadata blocks added successfully!")
