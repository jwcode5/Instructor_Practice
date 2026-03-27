# Fix officer1_v3.html - Add metadata blocks for all 100 questions

$v3File = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\officer1\officer1_v3.html'
$v3Content = Get-Content $v3File -Raw

$answerKey = @{
    1='b'; 2='b'; 3='a'; 4='b'; 5='a'; 6='c'; 7='d'; 8='d'; 9='a'; 10='c';
    11='a'; 12='c'; 13='b'; 14='b'; 15='b'; 16='a'; 17='a'; 18='c'; 19='c'; 20='b';
    21='b'; 22='b'; 23='a'; 24='a'; 25='c'; 26='c'; 27='b'; 28='d'; 29='b'; 30='a';
    31='c'; 32='a'; 33='b'; 34='a'; 35='a'; 36='b'; 37='a'; 38='d'; 39='d'; 40='d';
    41='c'; 42='c'; 43='d'; 44='b'; 45='d'; 46='c'; 47='d'; 48='a'; 49='a'; 50='c';
    51='b'; 52='a'; 53='b'; 54='a'; 55='a'; 56='b'; 57='a'; 58='b'; 59='a'; 60='a';
    61='d'; 62='c'; 63='c'; 64='b'; 65='a'; 66='b'; 67='a'; 68='c'; 69='b'; 70='a';
    71='d'; 72='a'; 73='a'; 74='c'; 75='a'; 76='d'; 77='c'; 78='c'; 79='a'; 80='d';
    81='b'; 82='b'; 83='c'; 84='d'; 85='b'; 86='a'; 87='b'; 88='a'; 89='b'; 90='a';
    91='b'; 92='b'; 93='a'; 94='b'; 95='c'; 96='d'; 97='b'; 98='d'; 99='d'; 100='d'
}

Write-Host "Starting comprehensive v3 fix..."

# For each question number 1-100
for ($qNum = 1; $qNum -le 100; $qNum++) {
    $answer = $answerKey[$qNum]
    
    # Pattern: find <div id="qN"> ... <div class="options">
    # Replace with same + metadata block on next line
    $pattern = "(id=`"q$qNum`"[^>]*>[^<]*<div class=`"options`">)"
    $replacement = "`$1`n`t`t<div class=`"question-meta`" data-section=`"TBD`" data-page=`"--`" data-correct=`"$answer`" style=`"display: none;`"></div>"
    
    $v3Content = $v3Content -replace $pattern, $replacement, 'Singleline'
    
    if ($qNum % 10 -eq 0) {
        Write-Host "Added metadata for questions 1-$qNum"
    }
}

# Update all Correct answer displays
$oldFormat = '<div class="correct-answer" style="display: none;">
			Correct answer: <span class="answer-text"></span>
		</div>'

$newFormat = '<div class="correct-answer" style="display: none;">
			Correct answer: <span class="answer-text"></span><br>
			Section: <span class="section-text"></span> | Page: <span class="page-text"></span>
		</div>'

$v3Content = $v3Content -replace [regex]::Escape($oldFormat), $newFormat

Set-Content $v3File $v3Content
Write-Host "V3 file updated successfully with metadata for all 100 questions!"
