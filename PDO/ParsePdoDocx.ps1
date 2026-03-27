<#
.SYNOPSIS
Parse pdo_docx_paragraphs.txt and generate pdo_v1.html in the index_v0.html format.
#>

$ParaFile  = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\PDO\pdo_docx_paragraphs.txt'
$OutputHtml = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\PDO\pdo_v1.html'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Escape-Html([string]$s) {
    if (-not $s) { return '' }
    $s.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Trim()
}

# Lines/paragraphs to skip
function Should-Skip([string]$text) {
    $skipList = @(
        'for PUMPER DRIVER OPERATOR',
        'PUMPER DRIVER/OPERATOR',
        'REFERENCE LIST FOR',
        'REFERENCE UST FOR',
        'Publisher/Title/Edition',
        'Reference Code',
        'NFPA 1002 PUMP',
        'NFPA 1002 AERIAL',
        'FIRE APPAR D/O',
        'D/O 3',
        'IFSTA, Pumping',
        'Jones and Bartlett, Fire',
        'NFPA 1002, Standard'
    )
    foreach ($pat in $skipList) {
        if ($text -match [regex]::Escape($pat)) { return $true }
    }
    # lone page number
    if ($text -match '^\d+\s*$') { return $true }
    return $false
}

# ---------------------------------------------------------------------------
# Correct-answer marker detection
# AY, BY, CY  /  A'!  B'f  C-r  A\"  Ai  Bt  A!  etc.
# Also: 0-r => D correct,  [Y => D correct
# ---------------------------------------------------------------------------
# Master regex: letter followed by OCR-corruption marker
$CorrectRx = [regex]'^([A-D])(?:[Yy]|[''`][!f"''1:r]|[''`][!'']|[-][rt]|\\"|[!]|[it](?=\s))\s*(.*)'

function Test-CorrectMarker([string]$text) {
    # Returns [bool, letter, cleanText]
    $t = $text.Trim()

    $m = $CorrectRx.Match($t)
    if ($m.Success) {
        return $true, $m.Groups[1].Value.ToUpper(), $m.Groups[2].Value.Trim()
    }

    # 0 as D  (OCR confusion)
    $m2 = [regex]'^0(?:[-][rt]|[''!])\s*(.*)'.Match($t)
    if ($m2.Success) {
        return $true, 'D', $m2.Groups[1].Value.Trim()
    }

    # [ as D
    $m3 = [regex]'^\[Y[.!]?\s*(.*)'.Match($t)
    if ($m3.Success) {
        return $true, 'D', $m3.Groups[1].Value.Trim()
    }

    # Non-ASCII single char at start (bullet/checkmark OCR artifact)
    if ($t.Length -gt 0 -and [int][char]$t[0] -gt 127) {
        return $true, '?', $t.Substring(1).Trim()
    }

    return $false, $null, $t
}

function Test-WrongAnswerLabel([string]$text) {
    # Returns [letter, cleanText] if "A. text" or "A) text" else [null, text]
    $m = [regex]'^([A-D])[.)]\s+(.*)'.Match($text.Trim())
    if ($m.Success) {
        return $m.Groups[1].Value.ToUpper(), $m.Groups[2].Value.Trim()
    }
    return $null, $text.Trim()
}

# Check if a line contains multiple concatenated answers (e.g., "AY text B. text C. text D. text")
$OptionDelimRx = [regex]'(?<![A-Z0-9])([A-D])([Yy''`!\-\\.])\s*'

function Test-CombinedLine([string]$text) {
    $matches = $OptionDelimRx.Matches($text)
    return ($matches.Count -ge 2)
}

function Parse-CombinedLine([string]$text) {
    # Returns array of [letter, isCorrect, answerText]
    $delims = $OptionDelimRx.Matches($text)
    if ($delims.Count -eq 0) { return @() }

    $results = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $delims.Count; $i++) {
        $m = $delims[$i]
        $letter = $m.Groups[1].Value.ToUpper()
        $marker = $m.Groups[2].Value
        $isCorrect = ($marker -ne '.' -and $marker -ne ')')

        $start = $m.Index + $m.Length
        $end   = if ($i + 1 -lt $delims.Count) { $delims[$i+1].Index } else { $text.Length }
        $ansText = $text.Substring($start, ($end - $start)).Trim().TrimEnd('.')

        if ($ansText) {
            $results.Add([PSCustomObject]@{
                Letter    = $letter
                IsCorrect = $isCorrect
                Text      = $ansText
            })
        }
    }
    return $results
}

# ---------------------------------------------------------------------------
# Load paragraphs
# ---------------------------------------------------------------------------
Write-Host 'Loading paragraphs...'
$lineRx = [regex]'^\d{5}:\s*(.*)'
$rawParas = [System.Collections.Generic.List[string]]::new()

foreach ($line in (Get-Content $ParaFile -Encoding UTF8)) {
    $m = $lineRx.Match($line)
    if ($m.Success) {
        $t = $m.Groups[1].Value.Trim()
        if ($t -and -not (Should-Skip $t)) {
            $rawParas.Add($t)
        }
    }
}
Write-Host "  $($rawParas.Count) paragraphs loaded"

# ---------------------------------------------------------------------------
# Parse into questions
# ---------------------------------------------------------------------------
Write-Host 'Parsing questions...'
$questions = [System.Collections.Generic.List[object]]::new()

function New-Q([string]$stem) {
    return [PSCustomObject]@{
        Text    = $stem
        Options = @('','','','')   # A B C D
        Correct = ''
    }
}

function Assign-Option($q, [string]$letter, [string]$text, [bool]$isCorrect) {
    $idx = switch ($letter) { 'A' {0} 'B' {1} 'C' {2} 'D' {3} default {-1} }
    if ($idx -ge 0) {
        if (-not $q.Options[$idx]) { $q.Options[$idx] = $text }
        if ($isCorrect) { $q.Correct = $letter }
    } else {
        # Unknown letter: put in first empty slot
        for ($sl = 0; $sl -lt 4; $sl++) {
            if (-not $q.Options[$sl]) {
                $q.Options[$sl] = $text
                if ($isCorrect) { $q.Correct = [char]([int][char]'A' + $sl) }
                break
            }
        }
    }
}

$i = 0
$n = $rawParas.Count

while ($i -lt $n) {
    $p = $rawParas[$i]

    # --- Combined answer line (all 4 options on one line)? ---
    if (Test-CombinedLine $p) {
        if ($questions.Count -gt 0) {
            $q = $questions[$questions.Count - 1]
            $opts = Parse-CombinedLine $p
            foreach ($opt in $opts) {
                Assign-Option $q $opt.Letter $opt.Text $opt.IsCorrect
            }
        }
        $i++
        continue
    }

    # --- Single correct-answer option line? ---
    $isCorr, $corrLetter, $corrText = Test-CorrectMarker $p
    if ($isCorr) {
        if ($questions.Count -gt 0) {
            $q = $questions[$questions.Count - 1]
            Assign-Option $q $corrLetter $corrText $true
        }
        $i++
        continue
    }

    # --- Wrong answer with label (A. text)? ---
    $lbl, $lblText = Test-WrongAnswerLabel $p
    if ($lbl) {
        if ($questions.Count -gt 0) {
            $q = $questions[$questions.Count - 1]
            Assign-Option $q $lbl $lblText $false
        }
        $i++
        continue
    }

    # --- Otherwise: question stem or unlabeled wrong answer ---
    if ($questions.Count -gt 0) {
        $q = $questions[$questions.Count - 1]
        $filled = ($q.Options | Where-Object { $_ }).Count
        if ($filled -gt 0 -and $filled -lt 4) {
            # Treat as unlabeled wrong answer for current question
            Assign-Option $q '?' $p $false
            $i++
            continue
        }
    }

    # Start a new question
    $newQ = New-Q $p
    $questions.Add($newQ)

    # Peek ahead to collect multi-line question stem
    $i++
    while ($i -lt $n) {
        $nxt = $rawParas[$i]
        if (Test-CombinedLine $nxt) { break }
        $nc, $nl, $nt = Test-CorrectMarker $nxt
        if ($nc) { break }
        $wl, $wt = Test-WrongAnswerLabel $nxt
        if ($wl) { break }
        # Append continuation
        $newQ.Text = ($newQ.Text + ' ' + $nxt).Trim()
        $i++
    }
}

# Keep only questions with at least some content
$valid = $questions | Where-Object { $_.Text -and ($_.Options | Where-Object { $_ }) }
Write-Host "  $($valid.Count) questions parsed"
$withCorrect = ($valid | Where-Object { $_.Correct }).Count
Write-Host "  $withCorrect have correct answer identified"
$allFour = ($valid | Where-Object { ($_.Options | Where-Object { $_ }).Count -eq 4 }).Count
Write-Host "  $allFour have all 4 options"

# ---------------------------------------------------------------------------
# Generate HTML
# ---------------------------------------------------------------------------
Write-Host 'Building HTML...'

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('<!DOCTYPE html>')
[void]$sb.AppendLine('<html lang="en">')
[void]$sb.AppendLine('<head>')
[void]$sb.AppendLine("`t<meta charset=`"UTF-8`">")
[void]$sb.AppendLine("`t<meta name=`"viewport`" content=`"width=device-width, initial-scale=1.0`">")
[void]$sb.AppendLine("`t<title>PDO Test Bank Practice</title>")
[void]$sb.AppendLine("`t<style>")
@'
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
'@ -split "`n" | ForEach-Object { [void]$sb.AppendLine($_) }
[void]$sb.AppendLine("`t</style>")
[void]$sb.AppendLine('</head>')
[void]$sb.AppendLine('<body>')
[void]$sb.AppendLine("`t<h1>PDO Test Bank Practice</h1>")
[void]$sb.AppendLine()
[void]$sb.AppendLine("`t<form id=`"quizForm`">")

$qNum = 0
foreach ($q in $valid) {
    $qNum++
    $qText = Escape-Html $q.Text
    $oa    = Escape-Html $q.Options[0]
    $ob    = Escape-Html $q.Options[1]
    $oc    = Escape-Html $q.Options[2]
    $od    = Escape-Html $q.Options[3]
    $corr  = if ($q.Correct) { $q.Correct.ToLower() } else { '' }

    [void]$sb.AppendLine("<!-- Question $qNum -->")
    [void]$sb.AppendLine("<div class=`"question`" id=`"q$qNum`">")
    [void]$sb.AppendLine("`t<p>$qNum.   $qText</p>")
    [void]$sb.AppendLine("`t<div class=`"options`">")
    [void]$sb.AppendLine("`t`t<div class=`"question-meta`" data-section=`"TBD`" data-page=`"--`" data-correct=`"$corr`" style=`"display: none;`"></div>")
    [void]$sb.AppendLine("`t`t<label><input type=`"radio`" name=`"q$qNum`" value=`"a`"> a)    $oa</label><br>")
    [void]$sb.AppendLine("`t`t<label><input type=`"radio`" name=`"q$qNum`" value=`"b`"> b)    $ob</label><br>")
    [void]$sb.AppendLine("`t`t<label><input type=`"radio`" name=`"q$qNum`" value=`"c`"> c)    $oc</label><br>")
    [void]$sb.AppendLine("`t`t<label><input type=`"radio`" name=`"q$qNum`" value=`"d`"> d)    $od</label><br>")
    [void]$sb.AppendLine("`t`t`t`t<div class=`"correct-answer`" style=`"display: none;`">")
    [void]$sb.AppendLine("`t`t`tCorrect answer: <span class=`"answer-text`"></span><br>")
    [void]$sb.AppendLine("`t`t`tSection: <span class=`"section-text`"></span> | Page: <span class=`"page-text`"></span>")
    [void]$sb.AppendLine("`t`t</div>")
    [void]$sb.AppendLine("`t</div>")
    [void]$sb.AppendLine("</div>")
    [void]$sb.AppendLine()
}

[void]$sb.AppendLine("`t`t<button type=`"button`" onclick=`"gradeQuiz()`">Submit Answers</button>")
[void]$sb.AppendLine()
[void]$sb.AppendLine("`t</form>")
[void]$sb.AppendLine()
[void]$sb.AppendLine("`t<div id=`"results`">")
[void]$sb.AppendLine("`t`t<h2>Results</h2>")
[void]$sb.AppendLine("`t`t<p id=`"score`"></p>")
[void]$sb.AppendLine("`t`t<div id=`"answerKey`"></div>")
[void]$sb.AppendLine("`t</div>")
[void]$sb.AppendLine()
[void]$sb.AppendLine("`t<script>")
@'
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
'@ -split "`n" | ForEach-Object { [void]$sb.AppendLine($_) }
[void]$sb.AppendLine("`t</script>")
[void]$sb.AppendLine('</body>')
[void]$sb.AppendLine('</html>')

$sb.ToString() | Set-Content -Path $OutputHtml -Encoding UTF8
Write-Host "Written to: $OutputHtml"
