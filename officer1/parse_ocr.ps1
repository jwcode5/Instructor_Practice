param()

$ocrFile   = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\officer1\V1_FO1_ocr.txt'
$outputHtml= 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\officer1\officer1_v1_ocr_imported.html'

$lines = Get-Content $ocrFile

# == 1. Parse Answer Key ==
# Lines look like:  "1 4.4.2 ADMIN FUNCTION 19 1.00 MCS C"
# OCR artifacts observed:
#   - period after number: "13. 4.2.1 ..."
#   - answer doubled:      "McS Cc"  -> C
#   - number misread:      "7B" -> 73, "799" -> 79
$answerKey = @{}
foreach ($line in $lines) {
    # Allow optional period after number; allow lowercase-polluted type (McS, McsS);
    # allow trailing lowercase after answer letter (Cc -> C takes first char).
    if ($line -match '^\s*(\d{1,3})\.?\s+\S.*\s+MC[Ss]+\s+([ABCD])[a-z]?\s*$') {
        $num = [int]$Matches[1]
        $ans = $Matches[2].ToLower()
        if ($num -ge 1 -and $num -le 100 -and -not $answerKey.ContainsKey($num)) {
            $answerKey[$num] = $ans
        }
    }
}
# Fix OCR-mangled row numbers that fall outside 1-100.
# "7B ... MCS D" -> q73, "799 ... MCS B" -> q79
foreach ($line in $lines) {
    if ($line -match '^7B\s+\S.*\s+MC[Ss]+\s+([ABCD])[a-z]?\s*$' -and -not $answerKey.ContainsKey(73)) {
        $answerKey[73] = $Matches[1].ToLower()
    }
    if ($line -match '^79+\s+\S.*\s+MC[Ss]+\s+([ABCD])[a-z]?\s*$' -and -not $answerKey.ContainsKey(79)) {
        $answerKey[79] = $Matches[1].ToLower()
    }
}
Write-Host "Answer key entries parsed: $($answerKey.Count)"

# == 2. Parse Questions ==
# A question starts with 1-3 digits followed by a period and a non-space char.
# Collect the line index and question number for every match in range 1-100.
$qStarts = New-Object System.Collections.Generic.List[PSObject]
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*(\d{1,3})\.\s+\S') {
        $num = [int]$Matches[1]
        if ($num -ge 1 -and $num -le 100) {
            $qStarts.Add([PSCustomObject]@{ Idx = $i; Num = $num })
        }
    }
}
# Deduplicate: keep only the first occurrence of each question number.
$seen = @{}; $unique = @()
foreach ($qs in $qStarts) {
    if (-not $seen.ContainsKey($qs.Num)) { $seen[$qs.Num] = $true; $unique += $qs }
}
$qStarts = $unique | Sort-Object Num
Write-Host "Question starts found: $($qStarts.Count)"

# Helper – split a horizontal-choice line like:
#   "A. Ordinary B. Wood frame C. Heavy timber D. Fire-resistive"
#   "A. the employee. B. the Fire Chief."
# Returns ordered array of [letter, text] objects.
function Split-Horizontal($raw) {
    $results = @()
    # Split on transition from answer-text to the next letter (B-D followed by .)
    # Two or more spaces before the next letter, OR the letter appears after a word boundary
    $parts = [regex]::Split($raw.Trim(), '(?<=\S)\s{2,}(?=[B-D]\.\s)')
    foreach ($p in $parts) {
        if ($p -match '^([A-D])\.\s+(.+)$') {
            $results += [PSCustomObject]@{ L = $Matches[1].ToLower(); T = $Matches[2].Trim() }
        }
    }
    return $results
}

$questions = @()

for ($qi = 0; $qi -lt $qStarts.Count; $qi++) {
    $startIdx = $qStarts[$qi].Idx
    $num      = $qStarts[$qi].Num
    $endIdx   = if ($qi + 1 -lt $qStarts.Count) { $qStarts[$qi + 1].Idx - 1 } else { $lines.Count - 1 }
    $block    = $lines[$startIdx..$endIdx]

    # Strip leading "N. " from first line.
    $firstLine = $block[0] -replace '^\s*\d{1,3}\.\s+', ''

    $qTextParts  = [System.Collections.Generic.List[string]]::new()
    $qTextParts.Add($firstLine.Trim())
    $choices     = @{ a=''; b=''; c=''; d='' }
    $currentLtr  = $null
    $currentBuf  = [System.Collections.Generic.List[string]]::new()
    $inChoices   = $false

    # Process remaining lines in this block.
    for ($bi = 1; $bi -lt $block.Count; $bi++) {
        $bl = $block[$bi]
        if ([string]::IsNullOrWhiteSpace($bl)) { continue }
        $bl = $bl.Trim()

        # Detect transition into choices section.
        $isChoiceStart   = $bl -match '^([A-D])\.\s+'
        $isMultiChoice   = $bl -match '^[A-D]\.\s+.+\s{2,}[B-D]\.\s+'

        if ($isChoiceStart -or $isMultiChoice) { $inChoices = $true }

        if (-not $inChoices) {
            $qTextParts.Add($bl)
            continue
        }

        # ---- In choices section ----
        if ($isMultiChoice) {
            # Flush current single-choice buffer.
            if ($currentLtr) {
                $choices[$currentLtr] = ($currentBuf -join ' ').Trim()
                $currentLtr = $null; $currentBuf.Clear()
            }
            $parsedPairs = Split-Horizontal $bl
            foreach ($pair in $parsedPairs) {
                $choices[$pair.L] = $pair.T
            }
        }
        elseif ($isChoiceStart) {
            # Flush previous single-choice.
            if ($currentLtr) {
                $choices[$currentLtr] = ($currentBuf -join ' ').Trim()
                $currentBuf.Clear()
            }
            if ($bl -match '^([A-D])\.\s+(.*)$') {
                $currentLtr = $Matches[1].ToLower()
                $currentBuf.Add($Matches[2].Trim())
            }
        }
        else {
            # Continuation line for current choice or question.
            if ($currentLtr) { $currentBuf.Add($bl) }
        }
    }
    # Flush last choice.
    if ($currentLtr) { $choices[$currentLtr] = ($currentBuf -join ' ').Trim() }

    $questions += [PSCustomObject]@{
        Num = $num
        Q   = ($qTextParts | Where-Object {$_}) -join ' '
        A   = $choices['a']
        B   = $choices['b']
        C   = $choices['c']
        D   = $choices['d']
    }
}

Write-Host "Questions fully parsed: $($questions.Count)"

# == 3. Generate HTML ==
$qHtml = ''
foreach ($q in $questions | Sort-Object Num) {
    $n = $q.Num
    $qHtml += @"

<!-- Question $n -->
<div class="question" id="q$n">
	<p>$n.   $($q.Q)</p>
   <div class="options">
		<label><input type="radio" name="q$n" value="a"> a)    $($q.A)</label><br>
		<label><input type="radio" name="q$n" value="b"> b)    $($q.B)</label><br>
		<label><input type="radio" name="q$n" value="c"> c)    $($q.C)</label><br>
		<label><input type="radio" name="q$n" value="d"> d)    $($q.D)</label><br>
		<div class="correct-answer" style="display: none;">
			Correct answer: <span class="answer-text"></span>
		</div>
	</div>
</div>
"@
}

# Build the answer-key JS object  (q1: "c", q2: "a", ...)
$akLines = ($answerKey.GetEnumerator() | Sort-Object { [int]$_.Key } | ForEach-Object {
    "  q$($_.Key): `"$($_.Value)`""
}) -join ",`n"

$now = Get-Date -Format 'yyyy-MM-dd HH:mm'

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>v1 Officer 1 Test Bank Practice (OCR Import)</title>
	<link rel="stylesheet" href="../style.css">
	<style>
		.question {
			margin: 20px 0;
			padding: 10px;
			border: 1px solid #e0e0e0;
			border-radius: 5px;
		}
		.options label {
			display: block;
			margin: 5px 0;
			cursor: pointer;
		}
		.correct-answer {
			color: green;
			font-weight: bold;
			margin-top: 10px;
		}
		button {
			background-color: #4CAF50;
			color: white;
			padding: 10px 20px;
			border: none;
			cursor: pointer;
			border-radius: 5px;
			font-size: 16px;
			margin-top: 20px;
		}
		button:hover {
			background-color: #45a049;
		}
	</style>
</head>
<body>
	<h1>v1 Officer 1 Test Bank Practice (OCR Import)</h1>
	<!-- Generated $now from V1 FO-1.pdf via Tesseract OCR -->

	<form id="quizForm">
$qHtml
	</form>

	<button type="button" onclick="gradeQuiz()">Submit Quiz</button>
	<div id="score"></div>
	<div id="answerKey"></div>

	<script>
		// Correct answers parsed from PDF answer-key pages via OCR
		const answerKey = {
$akLines
		};

		function gradeQuiz() {
			let score = 0;
			const totalQuestions = Object.keys(answerKey).length;
			const answerKeyDisplay = document.getElementById('answerKey');
			answerKeyDisplay.innerHTML = '';

			for (const [question, correctAnswer] of Object.entries(answerKey)) {
				const questionDiv = document.getElementById(question);
				if (!questionDiv) continue;
				const correctAnswerText = questionDiv.querySelector('.answer-text');
				const correctAnswerContainer = questionDiv.querySelector('.correct-answer');
				const correctOption = questionDiv.querySelector('input[value="' + correctAnswer + '"]');
				const correctText = correctOption ? correctOption.parentElement.textContent.trim() : correctAnswer;
				correctAnswerText.textContent = correctText;

				const selected = document.querySelector('input[name="' + question + '"]:checked');
				if (selected && selected.value === correctAnswer) {
					score++;
					correctAnswerContainer.style.display = 'block';
					correctAnswerContainer.style.color = 'green';
				} else {
					correctAnswerContainer.style.display = 'block';
					correctAnswerContainer.style.color = 'red';
				}
			}
			document.getElementById('score').innerHTML = '<h2>Score: ' + score + ' / ' + totalQuestions + '</h2>';
		}
	</script>
</body>
</html>
"@

$html | Set-Content $outputHtml -Encoding UTF8
Write-Host "Output written to: $outputHtml"
Write-Host "File size: $((Get-Item $outputHtml).Length) bytes"
