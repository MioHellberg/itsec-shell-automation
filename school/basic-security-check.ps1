param(
    [string]$File = "README.md",
    [string]$User = $env:USERNAME
)

$LogFile = "security_log.txt"

function Write-Log {
    param([string]$Message)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    $entry | Out-File -FilePath $LogFile -Append -Encoding utf8
}


function Test-File {
    param([string]$Path)
    if (Test-Path $Path) {
        Write-Log "Filen '$Path' finns."
        $info = (Get-Item $Path | Format-List | Out-String)
        Write-Log $info
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