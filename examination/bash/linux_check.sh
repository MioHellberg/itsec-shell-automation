#!/usr/bin/env bash
set -euo pipefail   # Exit on error, undefined var, or pipefail

# -------------------------------
# Variabler
# -------------------------------
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # Basmapp för projektet
OUTPUT="$BASE_DIR/data/linux_output.json"                  # JSON-fil för output
LOGFILE="$BASE_DIR/data/anomalies.log"                    # Loggfil
TMPFILE="/tmp/process_list.txt"                           # Temporär fil för processlistan
RISKFILE="/tmp/risk_results.txt"                          # Temporär fil för riskanalys

trap cleanup EXIT  # Rensa temporära filer om skriptet avbryts

RISK_PROCESSES=("nc" "netcat" "nmap" "hydra" "john" "hashcat")  # Lista riskabla processer

# -------------------------------
# Funktioner
# -------------------------------
log() {
    local LEVEL=$1
    local MESSAGE=$2
    # Skriv logg med timestamp till terminal + loggfil
    echo "$(date '+%Y-%m-%d %H:%M:%S') $LEVEL: $MESSAGE" | tee -a "$LOGFILE"
}

error_exit() {
    log "ERROR" "$1"  # Logga fel
    exit 1            # Avsluta skriptet
}

check_dependencies() {
    command -v ps >/dev/null 2>&1 || error_exit "ps saknas"  # Kontrollera att ps finns
}

get_processes() {
    log "INFO" "Hämtar aktiva processer..."
    ps -eo pid,user,comm --no-headers > "$TMPFILE"  # Skriv PID, user, kommando till tmpfil
    if [[ ! -s "$TMPFILE" ]]; then
        error_exit "Processlistan är tom"  # Avbryt om inget hittas
    fi
}

check_risks() {
    log "INFO" "Analyserar processer mot risklista..."
    : > "$RISKFILE"  # Rensa riskfil
    # Läs tmpfil rad för rad
    while read -r pid user cmd; do
        risk="LOW"
        # Jämför mot risklistan
        for rproc in "${RISK_PROCESSES[@]}"; do
            if [[ "$cmd" == *"$rproc"* ]]; then
                risk="HIGH"
                log "WARNING" "Riskprocess: $cmd (PID: $pid, User: $user)"  # Logga varning
                break
            fi
        done
        echo "$pid|$user|$cmd|$risk" >> "$RISKFILE"  # Skriv resultat till riskfil
    done < "$TMPFILE"
}

export_json() {
    log "INFO" "Exporterar JSON..."
    echo "[" > "$OUTPUT"  # Starta JSON-array
    FIRST=true
    # Läs riskfil och konvertera till JSON
    while IFS="|" read -r pid user cmd risk; do
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo "," >> "$OUTPUT"
        fi
        # Skriv JSON objekt
        cat <<EOF >> "$OUTPUT"
{
  "pid": "$pid",
  "user": "$user",
  "command": "$cmd",
  "risk": "$risk"
}
EOF
    done < "$RISKFILE"
    echo "]" >> "$OUTPUT"  # Avsluta JSON-array
    log "INFO" "JSON skapad: $OUTPUT"
}

cleanup() {
    rm -f "$TMPFILE" "$RISKFILE"  # Ta bort temporära filer
}

# -------------------------------
# Huvudflöde
# -------------------------------
main() {
    mkdir -p "$BASE_DIR/data"  # Skapa data-mapp om den saknas
    log "INFO" "Startar Linux Security Scanner: $(date '+%Y-%m-%d %H:%M:%S')"
    check_dependencies            # Kontrollera kommandon
    get_processes                 # Hämta processer
    check_risks                   # Kontrollera risker
    export_json                   # Skriv JSON
    cleanup                       # Rensa temporära filer
    log "INFO" "Scan klar: $(date '+%Y-%m-%d %H:%M:%S')"  # Slutlogg
}

main  # Kör skriptet