$LogFile = "process_check.log"

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $Message"

    # Visa i terminalen
    Write-Output $entry

    # Skriv till fil i UTF-8 (fixar NUL-problemet)
    Add-Content -Path $LogFile -Value $entry -Encoding utf8
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
        if ($proc.Trim() -ne "") {
            Test-Process -Name $proc.Trim()
        }
    }
}

Clear-Content $LogFile -ErrorAction SilentlyContinue

Invoke-Checks "processlist.txt"
Write-Log "Kontroller slutförda."