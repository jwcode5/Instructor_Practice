param(
  [string]$OcrDir = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\PDO\pdo_v1_ocr_text',
  [string]$OutHtml = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\PDO\pdo_v1.html'
)

$ErrorActionPreference = 'Stop'

if (!(Test-Path $OcrDir)) { throw "OCR directory not found: $OcrDir" }

function Escape-Html {
  param([string]$s)
  if ($null -eq $s) { return '' }
  return $s.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Trim()
}

function Normalize-ChoiceMarkers {
  param([string]$line)
  $x = $line
  # Common OCR artifacts: Ay / By / Cy / Dy instead of A./B./C./D.
  $x = [regex]::Replace($x, '(^|\s)([A-D])[yY](\s+)', '$1$2. ')
  # Also normalize A) style to A.
  $x = [regex]::Replace($x, '(^|\s)([A-D])\)(\s+)', '$1$2. ')
  return $x
}

function Get-ChoiceSegments {
  param([string]$line)
  $line = Normalize-ChoiceMarkers $line
  $segments = @()
  $matches = [regex]::Matches($line, '(?<![A-Z0-9])([A-D])\.\s+')
  if ($matches.Count -eq 0) { return $segments }

  for ($i = 0; $i -lt $matches.Count; $i++) {
    $m = $matches[$i]
    $letter = $m.Groups[1].Value.ToLower()
    $start = $m.Index + $m.Length
    $end = if ($i + 1 -lt $matches.Count) { $matches[$i + 1].Index } else { $line.Length }
	$txt = $line.Substring($start, $end - $start).Trim(' ', [char]9, '_')
    if ($txt) {
      $segments += [PSCustomObject]@{ Letter = $letter; Text = $txt }
    }
  }
  return $segments
}

# Load all OCR lines in page order.
$files = Get-ChildItem -Path $OcrDir -Filter '*.txt' | Sort-Object {
  if ($_.BaseName -match 'page-(\d+)') { [int]$matches[1] } else { 999999 }
}

$lines = New-Object System.Collections.Generic.List[string]
foreach ($f in $files) {
  (Get-Content -Path $f.FullName) | ForEach-Object { $lines.Add($_) }
}

$questions = @()
$current = $null
$currentChoice = $null

function New-QuestionObj {
  param([int]$n,[string]$q)
  return [PSCustomObject]@{
    Num = $n
    Q = $q
    A = ''
    B = ''
    C = ''
    D = ''
  }
}

function Flush-Question {
  param($q)
  if ($null -eq $q) { return }
  # Basic completeness filter: must have at least question text and one option.
  if (($q.Q -and $q.Q.Trim().Length -gt 0) -and ($q.A -or $q.B -or $q.C -or $q.D)) {
    $script:questions += $q
  }
}

foreach ($raw in $lines) {
  if ($null -eq $raw) { continue }
  $line = $raw.Trim()
  if (-not $line) { continue }

  # Skip recurring report headers/footers.
  if ($line -match '^(QUESTIONS REPORT|for PUMPER DRIVER OPERATOR|Monday,|Tuesday,|Reference Code|Publisher/Title/Edition|SECTION 1 \()') { continue }
  if ($line -match '^\d+\s*$') { continue }

  # New question start, e.g., "123. text" or "123) text"
  if ($line -match '^(\d{1,3})[\.|\)]\s+(.+)$') {
    $num = [int]$Matches[1]
    $qText = $Matches[2].Trim()

    # Question numbers are expected monotonic in this report.
    if ($num -ge 1 -and $num -le 1200) {
      Flush-Question $current
      $current = New-QuestionObj -n $num -q $qText
      $currentChoice = $null
      continue
    }
  }

  if ($null -eq $current) { continue }

  $choiceSegments = Get-ChoiceSegments $line
  if ($choiceSegments.Count -gt 0) {
    foreach ($seg in $choiceSegments) {
      switch ($seg.Letter) {
        'a' { $current.A = ($current.A + ' ' + $seg.Text).Trim() ; $currentChoice = 'a' }
        'b' { $current.B = ($current.B + ' ' + $seg.Text).Trim() ; $currentChoice = 'b' }
        'c' { $current.C = ($current.C + ' ' + $seg.Text).Trim() ; $currentChoice = 'c' }
        'd' { $current.D = ($current.D + ' ' + $seg.Text).Trim() ; $currentChoice = 'd' }
      }
    }
    continue
  }

  # Continuation line: append to latest choice if we are inside choices, else question text.
  if ($currentChoice) {
    switch ($currentChoice) {
      'a' { $current.A = ($current.A + ' ' + $line).Trim() }
      'b' { $current.B = ($current.B + ' ' + $line).Trim() }
      'c' { $current.C = ($current.C + ' ' + $line).Trim() }
      'd' { $current.D = ($current.D + ' ' + $line).Trim() }
    }
  } else {
    $current.Q = ($current.Q + ' ' + $line).Trim()
  }
}

Flush-Question $current

# Deduplicate by question number, keeping first parsed instance.
$seen = @{}
$unique = @()
foreach ($q in ($questions | Sort-Object Num)) {
  if (-not $seen.ContainsKey($q.Num)) {
    $seen[$q.Num] = $true
    $unique += $q
  }
}
$questions = $unique

# Build HTML questions block in index_v0 format.
$qHtmlBuilder = New-Object System.Text.StringBuilder
$idx = 0
foreach ($q in $questions) {
	$idx++
	$idNum = $idx
	$displayNum = $q.Num
	$qText = Escape-Html $q.Q
  $a = Escape-Html $q.A
  $b = Escape-Html $q.B
  $c = Escape-Html $q.C
  $d = Escape-Html $q.D

	[void]$qHtmlBuilder.AppendLine("<!-- Question $idNum -->")
	[void]$qHtmlBuilder.AppendLine("<div class=`"question`" id=`"q$idNum`">")
	[void]$qHtmlBuilder.AppendLine("`t<p>$displayNum.   $qText</p>")
	[void]$qHtmlBuilder.AppendLine("`t<div class=`"options`">")
	[void]$qHtmlBuilder.AppendLine("`t`t<div class=`"question-meta`" data-section=`"TBD`" data-page=`"--`" data-correct=`"`" style=`"display: none;`"></div>")
	[void]$qHtmlBuilder.AppendLine("`t`t<label><input type=`"radio`" name=`"q$idNum`" value=`"a`"> a)    $a</label><br>")
	[void]$qHtmlBuilder.AppendLine("`t`t<label><input type=`"radio`" name=`"q$idNum`" value=`"b`"> b)    $b</label><br>")
	[void]$qHtmlBuilder.AppendLine("`t`t<label><input type=`"radio`" name=`"q$idNum`" value=`"c`"> c)    $c</label><br>")
	[void]$qHtmlBuilder.AppendLine("`t`t<label><input type=`"radio`" name=`"q$idNum`" value=`"d`"> d)    $d</label><br>")
	[void]$qHtmlBuilder.AppendLine("`t`t`t`t<div class=`"correct-answer`" style=`"display: none;`">")
	[void]$qHtmlBuilder.AppendLine("`t`t`tCorrect answer: <span class=`"answer-text`"></span><br>")
	[void]$qHtmlBuilder.AppendLine("`t`t`tSection: <span class=`"section-text`"></span> | Page: <span class=`"page-text`"></span>")
  [void]$qHtmlBuilder.AppendLine("`t`t</div>")
  [void]$qHtmlBuilder.AppendLine("`t</div>")
  [void]$qHtmlBuilder.AppendLine("</div>")
  [void]$qHtmlBuilder.AppendLine()
}

$questionsHtml = $qHtmlBuilder.ToString().TrimEnd()

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Test Bank Practice</title>
	<style>
		body {
			font-family: Arial, sans-serif;
			line-height: 1.6;
			max-width: 800px;
			margin: 0 auto;
			padding: 20px;
		}

		.question {
			margin-bottom: 20px;
			padding: 15px;
			border: 1px solid #ddd;
			border-radius: 5px;
		}

		.options {
			margin-left: 20px;
		}

		.correct {
			background-color: #e6ffe6;
            padding: 10px;
            margin-top: 10px;
            border-radius: 5px;
            border-left: 4px solid #4CAF50
		}

		.incorrect {
			background-color: #ffe6e6;
		}

      .answer-text {
            font-weight: bold;
            color: #2E7D32
        }

		#results {
			margin-top: 30px;
			padding: 15px;
			border: 1px solid #333;
			border-radius: 5px;
			display: none;
		}

		#score {
			font-weight: bold;
			font-size: 1.2em;
		}

		button {
			padding: 10px 15px;
			background-color: #4CAF50;
			color: white;
			border: none;
			border-radius: 4px;
			cursor: pointer;
			font-size: 16px;
		   	min-height: 44px;
    	appearance: none;
    	-webkit-appearance: none;
    	-moz-appearance: none;
		}
		button:hover {
			background-color: #45a049;
		}
	</style>
</head>
<body>
	<h1>PDO v1 Test Bank Practice</h1>
	
	<form id="quizForm">
$questionsHtml
		<button type="button" onclick="gradeQuiz()">Submit Answers</button>
		
	</form>
	
	<div id="results">
		<h2>Results</h2>
		<p id="score"></p>
		<div id="answerKey"></div>
	</div>
	
	<script>
		function gradeQuiz() {
			let score = 0;
			const resultsDiv = document.getElementById("results");
			const scoreDisplay = document.getElementById("score");
			const answerKeyDisplay = document.getElementById("answerKey");
			const questionDivs = document.querySelectorAll(".question");
			const totalQuestions = questionDivs.length;
			
			answerKeyDisplay.innerHTML = "";
			
			questionDivs.forEach((questionDiv) => {
				const question = questionDiv.id;
				const selectedOption = document.querySelector(`input[name="${question}"]:checked`);
				const meta = questionDiv.querySelector(".question-meta");
				const correctAnswer = (meta?.dataset?.correct || "").toLowerCase();
				const section = meta?.dataset?.section || "TBD";
				const page = meta?.dataset?.page || "--";
				
				const correctAnswerText = questionDiv.querySelector(".answer-text");
				const sectionText = questionDiv.querySelector(".section-text");
				const pageText = questionDiv.querySelector(".page-text");
				const correctAnswerContainer = questionDiv.querySelector(".correct-answer");
				
				if (correctAnswer) {
					const correctOption = questionDiv.querySelector(`input[value="${correctAnswer}"]`);
					const correctText = correctOption ? correctOption.parentElement.textContent.trim() : correctAnswer.toUpperCase();
					if (correctAnswerText) {
						correctAnswerText.textContent = correctText;
					}
				}
				
				if (sectionText) {
					sectionText.textContent = section;
				}
				if (pageText) {
					pageText.textContent = page;
				}
				if (correctAnswerContainer) {
					correctAnswerContainer.style.display = "block";
				}
				
				if (selectedOption && correctAnswer) {
					if (selectedOption.value === correctAnswer) {
						score++;
						questionDiv.classList.add("correct");
						questionDiv.classList.remove("incorrect");
					} else {
						questionDiv.classList.add("incorrect");
						questionDiv.classList.remove("correct");
					}
					answerKeyDisplay.innerHTML += `
						<p><strong>Question ${question.substring(1)}:</strong>
						You selected ${selectedOption.value.toUpperCase()}.
						Correct answer is ${correctAnswer.toUpperCase()}. (${section}, p. ${page})</p>`;
				} else {
					questionDiv.classList.remove("correct", "incorrect");
					const selectedText = selectedOption
						? `You selected ${selectedOption.value.toUpperCase()}.`
						: "You didn't answer.";
					answerKeyDisplay.innerHTML += `
						<p><strong>Question ${question.substring(1)}:</strong>
						${selectedText}
						Correct answer is ${correctAnswer ? correctAnswer.toUpperCase() : "N/A"}. (${section}, p. ${page})</p>`;
				}
			});
			
			const percentage = totalQuestions ? Math.round((score / totalQuestions) * 100) : 0;
			scoreDisplay.textContent = `You scored ${score} out of ${totalQuestions} (${percentage}%)`;
			resultsDiv.style.display = "block";
		}
	</script>
</body>
</html>
"@

Set-Content -Path $OutHtml -Value $html -NoNewline
Write-Host "questions_parsed=$($questions.Count)"
Write-Host "wrote=$OutHtml"
