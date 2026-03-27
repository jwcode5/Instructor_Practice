# Fix officer1_v3.html: Add metadata blocks and update display format

$v3File = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\officer1\officer1_v3.html'
$content = Get-Content $v3File -Raw

# Answer key
$answerKey = @{
    q1='b'; q2='b'; q3='a'; q4='b'; q5='a'; q6='c'; q7='d'; q8='d'; q9='a'; q10='c';
    q11='a'; q12='c'; q13='b'; q14='b'; q15='b'; q16='a'; q17='a'; q18='c'; q19='c'; q20='b';
    q21='b'; q22='b'; q23='a'; q24='a'; q25='c'; q26='c'; q27='b'; q28='d'; q29='b'; q30='a';
    q31='c'; q32='a'; q33='b'; q34='a'; q35='a'; q36='b'; q37='a'; q38='d'; q39='d'; q40='d';
    q41='c'; q42='c'; q43='d'; q44='b'; q45='d'; q46='c'; q47='d'; q48='a'; q49='a'; q50='c';
    q51='b'; q52='a'; q53='b'; q54='a'; q55='a'; q56='b'; q57='a'; q58='b'; q59='a'; q60='a';
    q61='d'; q62='c'; q63='c'; q64='b'; q65='a'; q66='b'; q67='a'; q68='c'; q69='b'; q70='a';
    q71='d'; q72='a'; q73='a'; q74='c'; q75='a'; q76='d'; q77='c'; q78='c'; q79='a'; q80='d';
    q81='b'; q82='b'; q83='c'; q84='d'; q85='b'; q86='a'; q87='b'; q88='a'; q89='b'; q90='a';
    q91='b'; q92='b'; q93='a'; q94='b'; q95='c'; q96='d'; q97='b'; q98='d'; q99='d'; q100='d'
}

Write-Host "Starting v3 fix..."

# Add metadata blocks after <div class="options"> for each question
for ($i = 1; $i -le 100; $i++) {
    $qId = "q$i"
    $answer = $answerKey[$qId]
    
    # Look for pattern: <!-- Question N --> through <div class="options">
    # Insert metadata block right after <div class="options">
    $pattern = "(<div id=`"$qId`">\s*<p>.*?<div class=`"options`">)"
    $replacement = "`$1`n`t`t<div class=`"question-meta`" data-section=`"TBD`" data-page=`"--`" data-correct=`"$answer`" style=`"display: none;`"></div>"
    
    $content = $content -replace $pattern, $replacement, 'Singleline'
}

# Update all .correct-answer divs to include Section and Page fields
$oldCorrectAnswer = '<div class="correct-answer" style="display: none;">
			Correct answer: <span class="answer-text"></span>
		</div>'

$newCorrectAnswer = '<div class="correct-answer" style="display: none;">
			Correct answer: <span class="answer-text"></span><br>
			Section: <span class="section-text"></span> | Page: <span class="page-text"></span>
		</div>'

$content = $content -replace [regex]::Escape($oldCorrectAnswer), $newCorrectAnswer

# Save the file
Set-Content $v3File $content
Write-Host "V3 fix complete!"
