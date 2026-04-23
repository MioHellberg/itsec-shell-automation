param(
    [string]$File = "README.md",
    [string]$User = $env:USERNAME
)

$LogFile = "security_log.txt"

function Write-Log {
    param([string]$Message)
    $entry = "$(Get-Date) - $Message"
    $entry | Tee-Object -FilePath $LogFile -Append
}

function Test-File {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Log "Filen '$Path' finns."
        (Get-Item $Path).Attributes | Out-String | Tee-Object -FilePath $LogFile -Append
    }
    else {
        Write-Log "VARNING: Filen '$Path' saknas."
    }
}

function Test-User {
    param([string]$User)
    try {
        Get-LocalUser -Name $User -ErrorAction Stop > $null
        Write-Log "Användaren '$User' finns."
    }
    catch {
        Write-Log "VARNING: Användaren '$User' saknas."
    }
}

Test-File -Path $File

Test-User -User $User

Write-Log "Kontroller slutförda."