param(
  [Parameter(Mandatory=$true)]
  [string]$PdfPath,
  
  [Parameter(Mandatory=$true)]
  [string]$HtmlPath,
  
  [string]$ProjectRoot = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice'
)

$ErrorActionPreference = 'Stop'
$StartTime = Get-Date

function Log {
  param([string]$Message, [string]$Level = "INFO")
  $timestamp = Get-Date -Format "HH:mm:ss"
  Write-Host "[$timestamp] [$Level] $Message"
}

function LogError {
  param([string]$Message)
  Log $Message "ERROR"
}

function LogSuccess {
  param([string]$Message)
  Log $Message "SUCCESS"
}

try {
  # Validate inputs
  if (!(Test-Path $PdfPath)) {
    throw "PDF not found: $PdfPath"
  }
  if (!(Test-Path $HtmlPath)) {
    throw "HTML not found: $HtmlPath"
  }

  $pdfName = (Split-Path -Leaf $PdfPath) -replace '\.pdf$'
  $htmlDir = Split-Path -Path $HtmlPath
  $htmlName = (Split-Path -Leaf $HtmlPath) -replace '\.html$'
  
  Log "Starting automation for: $pdfName -> $htmlName"
  
  # Create working directories
  $imageDir = Join-Path $htmlDir "${htmlName}_images"
  $ocrDir = Join-Path $htmlDir "${htmlName}_ocr_text"
  
  if (!(Test-Path $imageDir)) { New-Item -ItemType Directory -Path $imageDir | Out-Null }
  if (!(Test-Path $ocrDir)) { New-Item -ItemType Directory -Path $ocrDir | Out-Null }
  
  Log "Working directories: $imageDir, $ocrDir"
  
  # Step 1: Extract PDF to images
  Log "Step 1/5: Extracting PDF to images..."
  $pdfimages = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\.tools\pdf\xpdf-tools-win-4.06\bin64\pdfimages.exe'
  & $pdfimages $PdfPath (Join-Path $imageDir "page")
  $imageCount = @(Get-ChildItem "$imageDir\*.ppm", "$imageDir\*.pbm" -ErrorAction SilentlyContinue).Count
  LogSuccess "Extracted $imageCount image files"
  
  # Step 2: Run OCR on all images
  Log "Step 2/5: Running OCR on $imageCount images..."
  $tesseract = 'C:\Program Files\Tesseract-OCR\tesseract.exe'
  $allImages = @(Get-ChildItem "$imageDir\*.ppm", "$imageDir\*.pbm" -ErrorAction SilentlyContinue | Sort-Object Name)
  
  $ocrCount = 0
  $allImages | ForEach-Object {
    $base = $_.BaseName
    $outFile = Join-Path $ocrDir $base
    & $tesseract $_.FullName $outFile -l eng quiet 2>$null
    $ocrCount++
    if ($ocrCount % 10 -eq 0) {
      Log "OCR progress: $ocrCount/$($allImages.Count)"
    }
  }
  LogSuccess "OCR complete: $ocrCount files processed"
  
  # Step 3: Extract answers from existing HTML
  Log "Step 3/5: Extracting answers from existing HTML..."
  $htmlContent = Get-Content -Raw -Path $HtmlPath
  $answerMap = @{}
  
  [regex]::Matches($htmlContent, 'q(?<n>\d+)\s*:\s*["''](?<a>[a-dA-D])["'']') | ForEach-Object {
    $qNum = [int]$_.Groups['n'].Value
    $ans = $_.Groups['a'].Value.ToLower()
    $answerMap[$qNum] = $ans
  }
  
  if ($answerMap.Count -eq 0) {
    throw "No answer key found in HTML"
  }
  LogSuccess "Extracted $($answerMap.Count) answers"
  
  # Step 4: Inject metadata into HTML
  Log "Step 4/5: Injecting metadata into HTML..."
  
  # First, replace ALL existing question-meta blocks with normalized TBD/-- version
  $htmlContent = [regex]::Replace(
    $htmlContent,
    '<div class="question-meta"[^>]*data-correct="([a-d])"[^>]*></div>',
    {
      param($m)
      $answer = $m.Groups[1].Value
      $metaDiv = '<div class="question-meta" data-section="TBD" data-page="--" data-correct="' + $answer + '" style="display: none;"></div>'
      return $metaDiv
    },
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
  )
  
  # For any questions without metadata, inject it
  $pattern = '(<div class="question" id="q(?<n>\d+)">[\s\S]*?<div class="options">\s*)(?!<div class="question-meta")'
  $htmlContent = [regex]::Replace(
    $htmlContent,
    $pattern,
    {
      param($m)
      $qNum = [int]$m.Groups['n'].Value
      $prefix = $m.Groups[1].Value
      
      $answer = if ($answerMap.ContainsKey($qNum)) { $answerMap[$qNum] } else { '' }
      
      $metaDiv = '<div class="question-meta" data-section="TBD" data-page="--" data-correct="' + $answer + '" style="display: none;"></div>'
      
      return $prefix + $metaDiv
    },
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
  )
  
  $metaCount = ([regex]::Matches($htmlContent, 'class="question-meta"')).Count
  $questionCount = ([regex]::Matches($htmlContent, 'id="q\d+"')).Count
  
  if ($metaCount -ne $questionCount) {
    throw "Mismatch: $metaCount metadata blocks but $questionCount questions"
  }
  
  Set-Content -Path $HtmlPath -Value $htmlContent -NoNewline
  LogSuccess "Injected metadata into all $questionCount questions"
  
  # Step 5: Cleanup
  Log "Step 5/5: Cleaning up temporary files..."
  Remove-Item -Recurse -Force $imageDir, $ocrDir -ErrorAction SilentlyContinue
  LogSuccess "Temporary files cleaned up"
  
  # Final validation
  Log "Validating HTML..."
  $testContent = Get-Content -Raw -Path $HtmlPath
  if ($testContent -match '<script>[\s\S]*?function gradeQuiz') {
    LogSuccess "HTML validation passed - gradeQuiz function present"
  } else {
    throw "HTML validation failed - gradeQuiz function missing"
  }
  
  $elapsed = ((Get-Date) - $StartTime).TotalSeconds
  LogSuccess "Automation complete in $([math]::Round($elapsed, 1)) seconds"
  LogSuccess "Updated: $HtmlPath"
  
} catch {
  $elapsed = ((Get-Date) - $StartTime).TotalSeconds
  LogError "Automation failed after $([math]::Round($elapsed, 1)) seconds"
  LogError $_.Exception.Message
  exit 1
}
