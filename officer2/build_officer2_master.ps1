$inFile = "officer2/officer2_unique_questions_with_answer_text.json"
$outFile = "officer2/testbank_officer2.json"
$logFile = "officer2/testbank_officer2_resolution_log.json"
$unresolvedFile = "officer2/testbank_officer2_conflicts_unresolved.json"

$data = Get-Content $inFile -Raw | ConvertFrom-Json

function Normalize-Answer([string]$s) {
  if (-not $s) { return "" }
  $t = $s.Trim()
  $t = $t -replace "\\?", ""
  $t = $t -replace "\s+", " "
  $t = $t -replace "\bina\b", "in a"
  $t = $t -replace "\behancing\b", "enhancing"
  $t = $t -replace "\binvovled\b", "involved"
  $t = $t -replace "\bsearh\b", "search"
  $t = $t -replace "\bresonable\b", "reasonable"
  $t = $t -replace "\bquestion when\b", "questions when"
  $t = $t -replace "education tool\.$", "educational tool."
  $t = $t -replace "evaluation and use of", "evaluation, and use of"
  $t = $t -replace "specific schedule\. usually annually\.", "specific schedule, usually annually."
  $t = $t -replace "[\.!?]+$", ""
  return $t
}

$overrides = @{
  "Which is correct regarding groups?" = "A formal group usually defines common goals in a written document."
  "Which is correct regarding group dynamics?" = "Group interaction determines group productivity."
  "Which is correct regarding the post incident analysis?" = "It compares the actions taken with the appropriate Standard Operating Guide."
  "When interviewing persons from a fire scene, you should:" = "interview each person separately."
  "Which is correct regarding personnel evaluations?" = "Evaluations must include definite identifiable criteria."
  "Design requirements, accessories, warranty, training for operational personnel, technical support and penalty for non-delivery are all items to be included in:" = "bid specifications."
  "Which is correct regarding risk-benefit analysis?" = "There should be no firefighter risk when there is significant structural damage."
  "Directions: Read the following statements, then select the correct answer from choices A-D below. Statement 1: Any member of an informal group not just the leader, can positively influence and guide the group. Statement 2: The total production of a group is determined by the interaction of the group members on an individual basis. Statement 3: The company officer should strive to distance themselves from the informal group." = "Statements 1 and 2 are true; statement 3 is false."
  "A subordinate's perception of a supervisor's authority to administer discipline as referred to as ___ power." = "coercive"
  "A subordinate's perception of a supervisor's authority to administer discipline is referred to as ___ power." = "coercive"
  "Issuing a reprimand for not submitting a report on time is an example of ___ power." = "coercive"
}

$resolved = @()
$log = @()
$unresolved = @()
$id = 1

foreach ($q in $data) {
  $raw = [string]$q.answerText
  # Treat slash as a separator only when it has spaces around it, preserving terms like Division/group.
  $parts = @($raw -split "\s+/\s+" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
  $method = "single"
  $chosen = ""
  $hadConflict = $false

  if ($parts.Count -le 1) {
    $chosen = Normalize-Answer $raw
  } else {
    $hadConflict = $true
    $normalized = @($parts | ForEach-Object { Normalize-Answer $_ })
    $normKeys = @($normalized | ForEach-Object { $_.ToLowerInvariant() } | Select-Object -Unique)
    if ($normKeys.Count -eq 1) {
      $chosen = $normalized[0]
      $method = "normalized_merge"
    } elseif ($overrides.ContainsKey([string]$q.question)) {
      $chosen = $overrides[[string]$q.question]
      $method = "manual_override"
    } else {
      $chosen = $normalized[0]
      $method = "fallback_first"
      $unresolved += [pscustomobject]@{
        question = $q.question
        candidates = $normalized
      }
    }
  }

  $resolved += [pscustomobject]@{
    id = ("o2-u{0:d4}" -f $id)
    question = [string]$q.question
    correctAnswerText = $chosen
    files = [string]$q.files
    variants = [int]$q.variants
    hadConflict = $hadConflict
    resolutionMethod = $method
  }

  if ($hadConflict) {
    $log += [pscustomobject]@{
      id = ("o2-u{0:d4}" -f $id)
      question = [string]$q.question
      original = $parts
      chosen = $chosen
      method = $method
    }
  }

  $id++
}

$resolved | ConvertTo-Json -Depth 8 | Set-Content $outFile
$log | ConvertTo-Json -Depth 8 | Set-Content $logFile
$unresolved | ConvertTo-Json -Depth 8 | Set-Content $unresolvedFile

Write-Output "MASTER_COUNT=$($resolved.Count)"
Write-Output "CONFLICT_ROWS_RESOLVED=$($log.Count)"
Write-Output "UNRESOLVED_LEFT=$($unresolved.Count)"
