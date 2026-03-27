# CleanPdoQuestions.ps1 - OCR cleanup with multi-option line handling
$inFile = "c:\Users\mecha\OneDrive\Documents\Coding Projects\Officer Docs\PDO Test Bank 1.docx.txt"
$lines = @(Get-Content $inFile -Encoding UTF8)
$output = @()

function IsQuestionHeader {
    param([string]$line)
    return $line -match '^\d+\.\s+\w'
}

function IsSeparator {
    param([string]$line)
    return ($line -match '^_+') -or ($line -match '^\s*$')
}

function NormalizeMarkers {
    param([string]$text)
    $text = $text -replace '\bAY\b', 'A.'
    $text = $text -replace '\bBY\b', 'B.'
    $text = $text -replace '\bCY\b', 'C.'
    $text = $text -replace '\bDY\b', 'D.'
    $text = $text -replace "A'!", 'A.'
    $text = $text -replace "B'!", 'B.'
    $text = $text -replace "C':", 'C.'
    $text = $text -replace "D'!", 'D.'
    $text = $text -replace 'A-', 'A.'
    $text = $text -replace 'B-', 'B.'
    $text = $text -replace 'C-', 'C.'
    $text = $text -replace 'D-', 'D.'
    return $text
}

function SplitOptionsLine {
    param([string]$line)
    $result = @()
    $aCount = ($line | Select-String -Pattern '\bA\.' -AllMatches).Matches.Count
    $bCount = ($line | Select-String -Pattern '\bB\.' -AllMatches).Matches.Count
    $cCount = ($line | Select-String -Pattern '\bC\.' -AllMatches).Matches.Count
    $dCount = ($line | Select-String -Pattern '\bD\.' -AllMatches).Matches.Count
    $total = $aCount + $bCount + $cCount + $dCount
    
    if ($total -ge 2) {
        $parts = $line -split '(?=\b[A-D]\.)'
        foreach ($part in $parts) {
            $part = $part.Trim()
            if ($part -match '^[A-D]\.' -and $part.Length -gt 2) {
                $result += $part
            }
        }
        return $result
    }
    return @($line)
}

$i = 0
while ($i -lt $lines.Count) {
    $line = $lines[$i]
    
    if (IsSeparator $line) {
        $i++
        continue
    }
    
    $line = NormalizeMarkers $line
    
    if (IsQuestionHeader $line) {
        $output += $line
        $i++
        
        while ($i -lt $lines.Count) {
            $testLine = $lines[$i]
            
            if (IsQuestionHeader $testLine) {
                break
            }
            if (IsSeparator $testLine) {
                $i++
                continue
            }
            
            $testLine = NormalizeMarkers $testLine
            $splitLines = SplitOptionsLine $testLine
            
            foreach ($splitLine in $splitLines) {
                $trimmed = $splitLine.Trim()
                if ($trimmed.Length -gt 0) {
                    $output += $splitLine
                }
            }
            
            $i++
        }
    } else {
        $trimmed = $line.Trim()
        if ($trimmed.Length -gt 0) {
            $output += $line
        }
        $i++
    }
}

$output -join "`n" | Out-File -FilePath $inFile -Encoding UTF8
Write-Host "Done. Processed $($output.Count) lines."
