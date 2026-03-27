param(
  [Parameter(Mandatory = $true)]
  [string]$OcrDir,

  [Parameter(Mandatory = $true)]
  [string]$HtmlPath
)

$ErrorActionPreference = 'Stop'

if (!(Test-Path $OcrDir)) {
  throw "OCR directory not found: $OcrDir"
}
if (!(Test-Path $HtmlPath)) {
  throw "HTML file not found: $HtmlPath"
}

# 1) Parse answer key from OCR text files (answer pages contain MC[S] + letter)
$ocrAnswerKey = @{}
$ocrFiles = Get-ChildItem -Path $OcrDir -Filter *.txt | Sort-Object Name

foreach ($file in $ocrFiles) {
  $lines = Get-Content -Path $file.FullName
  foreach ($line in $lines) {
    if ($line -match '^\s*(\d{1,3})\.?\s+\S.*\s+MC[Ss]+\s+([ABCD])[a-z]?\s*$') {
      $num = [int]$Matches[1]
      $ans = $Matches[2].ToLower()
      if ($num -ge 1 -and $num -le 100 -and -not $ocrAnswerKey.ContainsKey($num)) {
        $ocrAnswerKey[$num] = $ans
      }
    }
  }
}

# Handle common OCR row-number artifacts seen in previous sets.
foreach ($file in $ocrFiles) {
  $lines = Get-Content -Path $file.FullName
  foreach ($line in $lines) {
    if ($line -match '^7B\s+\S.*\s+MC[Ss]+\s+([ABCD])[a-z]?\s*$' -and -not $ocrAnswerKey.ContainsKey(73)) {
      $ocrAnswerKey[73] = $Matches[1].ToLower()
    }
    if ($line -match '^79+\s+\S.*\s+MC[Ss]+\s+([ABCD])[a-z]?\s*$' -and -not $ocrAnswerKey.ContainsKey(79)) {
      $ocrAnswerKey[79] = $Matches[1].ToLower()
    }
  }
}

# 2) Parse answers from HTML metadata blocks.
$html = Get-Content -Raw -Path $HtmlPath
$htmlAnswerKey = @{}

$pattern = '<div class="question" id="q(?<n>\d+)"[\s\S]*?<div class="question-meta"[^>]*data-correct="(?<a>[a-dA-D])"[^>]*></div>'
$matches = [regex]::Matches($html, $pattern)
foreach ($m in $matches) {
  $num = [int]$m.Groups['n'].Value
  $ans = $m.Groups['a'].Value.ToLower()
  if ($num -ge 1 -and $num -le 100) {
    $htmlAnswerKey[$num] = $ans
  }
}

# 3) Compare.
$allNums = 1..100
$mismatches = @()
$missingInOcr = @()
$missingInHtml = @()

foreach ($n in $allNums) {
  $hasOcr = $ocrAnswerKey.ContainsKey($n)
  $hasHtml = $htmlAnswerKey.ContainsKey($n)

  if (-not $hasOcr) {
    $missingInOcr += $n
    continue
  }
  if (-not $hasHtml) {
    $missingInHtml += $n
    continue
  }

  if ($ocrAnswerKey[$n] -ne $htmlAnswerKey[$n]) {
    $mismatches += [PSCustomObject]@{
      Question = $n
      OCR = $ocrAnswerKey[$n]
      HTML = $htmlAnswerKey[$n]
    }
  }
}

Write-Host "OCR answers found: $($ocrAnswerKey.Count)"
Write-Host "HTML answers found: $($htmlAnswerKey.Count)"
Write-Host "Missing in OCR: $($missingInOcr.Count)"
Write-Host "Missing in HTML: $($missingInHtml.Count)"
Write-Host "Mismatches: $($mismatches.Count)"

if ($mismatches.Count -gt 0) {
  Write-Host "--- Mismatch detail (Question OCR HTML) ---"
  $mismatches | Sort-Object Question | ForEach-Object {
    Write-Host ("Q{0}: {1} vs {2}" -f $_.Question, $_.OCR.ToUpper(), $_.HTML.ToUpper())
  }
}
