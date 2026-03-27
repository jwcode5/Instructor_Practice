<#
.SYNOPSIS
Extract plain paragraph text from the PDO DOCX word/document.xml
and write a clean, editable .txt file (one line per paragraph).
#>

$DocXml  = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\PDO\pdo_docx_extract\word\document.xml'
$OutFile = 'c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice\PDO\pdo_raw_text.txt'

$xml = [xml](Get-Content $DocXml -Raw -Encoding UTF8)
$ns  = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$ns.AddNamespace('w','http://schemas.openxmlformats.org/wordprocessingml/2006/main')

$lines = [System.Collections.Generic.List[string]]::new()

foreach ($para in $xml.SelectNodes('//w:p', $ns)) {
    $parts = foreach ($r in $para.SelectNodes('.//w:r', $ns)) {
        $t = $r.SelectSingleNode('.//w:t', $ns)
        if ($t -and $t.'#text') { $t.'#text' }
    }
    $line = ($parts -join '').Trim()
    if ($line) { $lines.Add($line) }
}

$lines | Set-Content -Path $OutFile -Encoding UTF8
Write-Host "Done. $($lines.Count) lines written to:"
Write-Host "  $OutFile"
