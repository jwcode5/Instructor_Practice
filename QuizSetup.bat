@echo off
REM Quick Quiz Setup Automation Wrapper
REM Usage: QuizSetup.bat "path/to/source.pdf" "path/to/target.html"

if "%~1"=="" (
  echo Usage: QuizSetup.bat "C:\path\to\SourcePDF.pdf" "C:\path\to\target.html"
  echo.
  echo Examples:
  echo   QuizSetup.bat "Officer Docs\V3 FO-1.pdf" "officer1\officer1_v3.html"
  echo   QuizSetup.bat "Officer Docs\V1 FOII.pdf" "officer2\officer2_v1.html"
  exit /b 1
)

if "%~2"=="" (
  echo Error: Please specify both PDF path and target HTML file
  exit /b 1
)

setlocal enabledelayedexpansion
cd /d "c:\Users\mecha\OneDrive\Documents\Coding Projects\Instructor_Practice"

echo ============================================
echo  Quiz Setup Automation
echo ============================================
echo PDF Source: %~1
echo Target HTML: %~2
echo.
echo Starting automation...
echo Time: %date% %time%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& '.\AutomateQuizSetup.ps1' -PdfPath '%~1' -HtmlPath '%~2'" 

if %ERRORLEVEL% EQU 0 (
  echo.
  echo ============================================
  echo  SUCCESS - Quiz setup complete!
  echo ============================================
  exit /b 0
) else (
  echo.
  echo ============================================
  echo  ERROR - Setup failed. Check output above.
  echo ============================================
  exit /b 1
)
