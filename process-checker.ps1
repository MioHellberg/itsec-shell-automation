$LogFile = "process_check.log"

function Write-Log {
    param([string]$Message)
    $entry = "$(Get-Date) - $Message"
    $entry | Tee-Object -FilePath $LogFile -Append
}

function Test-Process {
    param([string]$Name)

    if (Get-Process -Name $Name -ErrorAction SilentlyContinue) {
        Write-Log "Processen '$Name' körs."
    }
    else {
        Write-Log "VARNING: Processen '$Name' körs inte."
    }
}

function Invoke-Checks {
    param([string]$Path)

    if (-Not (Test-Path $Path)) {
        Write-Log "FEL: Filen $Path saknas."
        exit
    }

    foreach ($proc in Get-Content $Path) {
        Test-Process -Name $proc
    }
}

Invoke-Checks "processlist.txt"
Write-Log "Kontroller slutförda."