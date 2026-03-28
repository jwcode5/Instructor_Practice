$basePath = "c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice"

function CleanFile($path, $isV1) {
    $content = [System.IO.File]::ReadAllText($path)
    $original = $content

    if ($isV1) {
        # officer1_v1.html — non-optional chaining, "Section: X. Page: Y." template format
        $content = [regex]::Replace($content, '\r?\n\t+const section = meta\.dataset\.section \|\| "[^"]*";', '')
        $content = [regex]::Replace($content, '\r?\n\t+const page = meta\.dataset\.page \|\| "[^"]*";', '')
        $content = [regex]::Replace($content, '\r?\n\t+const sectionText = questionDiv\.querySelector\("\.section-text"\);', '')
        $content = [regex]::Replace($content, '\r?\n\t+const pageText = questionDiv\.querySelector\("\.page-text"\);', '')
        $content = [regex]::Replace($content, '\r?\n\t+sectionText\.textContent = section;', '')
        $content = [regex]::Replace($content, '\r?\n\t+pageText\.textContent = page;', '')
        $content = [regex]::Replace($content, '\r?\n\t+Section: \$\{section\}\. Page: \$\{page\}\.', '')
    } else {
        # Common structure — optional chaining, if-blocks, "(section, p. page)" inline
        $content = [regex]::Replace($content, '\r?\n\t+const section = meta\?\.dataset\?\.section \|\| "[^"]*";', '')
        $content = [regex]::Replace($content, '\r?\n\t+const page = meta\?\.dataset\?\.page \|\| "[^"]*";', '')
        $content = [regex]::Replace($content, '\r?\n\t+const sectionText = questionDiv\.querySelector\("\.section-text"\);', '')
        $content = [regex]::Replace($content, '\r?\n\t+const pageText = questionDiv\.querySelector\("\.page-text"\);', '')
        $content = [regex]::Replace($content, '\r?\n\t+if \(sectionText\) \{\r?\n\t+sectionText\.textContent = section;\r?\n\t+\}', '')
        $content = [regex]::Replace($content, '\r?\n\t+if \(pageText\) \{\r?\n\t+pageText\.textContent = page;\r?\n\t+\}', '')
        $content = [regex]::Replace($content, ' \(\$\{section\}, p\. \$\{page\}\)', '')
    }

    if ($content -ne $original) {
        [System.IO.File]::WriteAllText($path, $content)
        Write-Host "Updated: $(Split-Path $path -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "No change: $(Split-Path $path -Leaf)" -ForegroundColor Yellow
    }
}

# officer1_v1.html - unique structure
CleanFile "$basePath\officer1\officer1_v1.html" $true

# All other officer1 html files
Get-ChildItem "$basePath\officer1" -Filter "*.html" | Where-Object { $_.Name -ne "officer1_v1.html" } | ForEach-Object { CleanFile $_.FullName $false }

# All officer2 html files
Get-ChildItem "$basePath\officer2" -Filter "*.html" | ForEach-Object { CleanFile $_.FullName $false }

# All instructor1 html files
Get-ChildItem "$basePath\instructor1" -Filter "*.html" | ForEach-Object { CleanFile $_.FullName $false }

# index_v0.html
CleanFile "$basePath\index_v0.html" $false

Write-Host "`nDone." -ForegroundColor Cyan
