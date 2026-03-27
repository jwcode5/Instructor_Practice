# Fix v3.html - Add metadata blocks and update display
$v3path = "c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\officer1\officer1_v3.html"
$v3content = Get-Content -Raw -Path $v3path

# Extract answer keys from JavaScript
$answers = @{}
$keyMatch = $v3content | Select-String -Pattern 'const answerKey = \{([\s\S]*?)\};'
if ($keyMatch) {
    $keyText = $keyMatch.Matches.Groups[1].Value
    $keyText -split ',' | ForEach-Object {
        if ($_ -match 'q(\d+):\s*"([a-d])"') {
            $answers[[int]$matches[1]] = $matches[2]
        }
    }
}

Write-Output "Found $($answers.Count) answers in v3"

# Update correct-answer display format first
$v3content = $v3content -replace '<div class="correct-answer" style="display: none;">\s*Correct answer: <span class="answer-text"></span>\s*</div>', '<div class="correct-answer" style="display: none;">
			Correct answer: <span class="answer-text"></span><br>
			Section: <span class="section-text"></span> | Page: <span class="page-text"></span>
		</div>'

# Add metadata blocks - process each question
for ($i = 1; $i -le 100; $i++) {
    $answer = $answers[$i]
    if ($answer) {
        # Find pattern: <div class="options"> and add metadata right after
        $pattern = "(<div class=`"question`" id=`"q$i`">[^]*?<div class=`"options`">)"
        $replacement = "`$1`n`t`t<div class=`"question-meta`" data-section=`"TBD`" data-page=`"--`" data-correct=`"$answer`" style=`"display: none;`"></div>"
        $v3content = $v3content -replace $pattern, $replacement
    }
}

Set-Content -Path $v3path -Value $v3content -NoNewline
Write-Output "v3 updated with metadata blocks"

# Fix v4.html - Normalize metadata to TBD/--
$v4path = "c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\officer1\officer1_v4.html"
$v4content = Get-Content -Raw -Path $v4path

# First update correct-answer display format
$v4content = $v4content -replace '<div class="correct-answer" style="display: none;">\s*Correct answer: <span class="answer-text"></span><br>\s*Section: <span class="section-text"></span> \| Page: <span class="page-text"></span>\s*</div>', '<div class="correct-answer" style="display: none;">
			Correct answer: <span class="answer-text"></span><br>
			Section: <span class="section-text"></span> | Page: <span class="page-text"></span>
		</div>'

# Now replace Officer 1 section/page with TBD/-- keeping correct answers
$v4content = [regex]::Replace($v4content, 
    '<div class="question-meta" data-section="[^"]*" data-page="[^"]*" data-correct="([a-d])"([^>]*)></div>', 
    '<div class="question-meta" data-section="TBD" data-page="--" data-correct="$1"$2></div>')

Set-Content -Path $v4path -Value $v4content -NoNewline
Write-Output "v4 updated - metadata normalized to TBD/--"

Write-Output "All updates complete!"
