<#

Windows Security Scanner - multilingual & robust
- Kontrollerar riskabla tjänster
- Listar administratörskonton
- Kontrollerar misslyckade logins
- Exporterar CSV och loggar allt
#>

# -------------------------------
# Globala variabler
# -------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path   # Skriptets mapp
$DataDir = Join-Path $ScriptDir "..\data"                     # Data-mapp
if (-not (Test-Path $DataDir)) { New-Item -Path $DataDir -ItemType Directory -Force | Out-Null }
$LogFile = Join-Path $DataDir "anomalies.log"                # Loggfil
$OutputCsv = Join-Path $DataDir "windows_output.csv"         # CSV-fil
$RiskyServices = @("Telnet", "SMBv1", "RemoteRegistry")     # Lista riskabla tjänster

# -------------------------------
# Funktion loggning
# -------------------------------
function Write-Log {
    param([string]$Message,[string]$Level="INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"       # Tidstämpel
    $entry = "$timestamp ${Level}: $Message"
    Write-Output $entry                                       # Skriv till terminal
    Add-Content -Path $LogFile -Value $entry                  # Skriv till loggfil
}

# -------------------------------
# Funktion Hämta alla tjänster
# -------------------------------
function Get-Services {
    try { Get-Service | Select-Object Name, Status }          # Hämta Name + Status
    catch { Write-Log "Kunde inte hämta tjänster: $_" "ERROR"; return @() }
}

# -------------------------------
# Funktion Kontrollera riskabla tjänster
# -------------------------------
function Test-Risks {
    param([array]$Services)
    foreach ($svc in $Services) {
        if ($RiskyServices -contains $svc.Name -and $svc.Status -eq "Running") {
            Write-Log "Riskabel tjänst upptäckt: $($svc.Name) körs" "HIGH"
        }
    }
}

# -------------------------------
# Funktion: Kontrollera privilegierade konton
# -------------------------------
function Test-PrivilegedAccounts {
    # Rätt gruppnamn beroende på språk
    $AdminGroupName = if ((Get-Culture).Name -like "sv-*") { "Administratörer" } else { "Administrators" }

    try {
        # Kontrollera om gruppen finns
        if (Get-LocalGroup -Name $AdminGroupName -ErrorAction SilentlyContinue) {
            $admins = Get-LocalGroupMember -Group $AdminGroupName | Select-Object Name,ObjectClass
            foreach ($a in $admins) { Write-Log "Administratörskonto: $($a.Name) ($($a.ObjectClass))" "MEDIUM" }
            return $admins
        } else {
            Write-Log "Administratörsgruppen hittades inte på detta system." "WARN"
            return @()
        }
    } catch { Write-Log "Kunde inte lista Administrators: $_" "ERROR"; return @() }
}

# -------------------------------
# Funktion: Misslyckade logins
# -------------------------------
function Test-FailedLogins {
    try {
        # Hämta Event ID 4625 (failed login), max 100 händelser, ignorera om inga
        $failedLogins = Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625} -MaxEvents 100 -ErrorAction SilentlyContinue |
            Select-Object TimeCreated,@{Name='Account';Expression={$_.Properties[5].Value}},@{Name='IP';Expression={$_.Properties[18].Value}}
        foreach ($f in $failedLogins) {
            Write-Log "Misslyckad login: $($f.Account) från $($f.IP) vid $($f.TimeCreated)" "MEDIUM"
        }
        return $failedLogins
    } catch { Write-Log "Kunde inte läsa Event Viewer: $_" "ERROR"; return @() }
}

# -------------------------------
# Huvudflöde
# -------------------------------
Write-Log "Windows Security Scan startar: $(Get-Date)" "INFO"  # Startlogg

$services = Get-Services
Test-Risks -Services $services
$admins = Test-PrivilegedAccounts
$failedLogins = Test-FailedLogins

# Exportera tjänster till CSV
$services | Export-Csv -Path $OutputCsv -NoTypeInformation -Force
Write-Log "Tjänster exporterade till $OutputCsv"
Write-Log "Windows Security Scan avslutad: $(Get-Date)" "INFO"   # Slutlogg