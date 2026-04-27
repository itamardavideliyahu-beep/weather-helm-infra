$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    'C:\Users\Admin\Desktop\WORK\DevOpsExperts\project\deploy.ps1',
    [ref]$null,
    [ref]$errors
) | Out-Null
if ($errors.Count -eq 0) {
    Write-Host "PARSE OK" -ForegroundColor Green
} else {
    $errors | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
}
