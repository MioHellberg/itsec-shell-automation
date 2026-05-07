#!/usr/bin/env python3
"""Analysmotor för Linux + Windows security data med loggning."""

import json, csv, logging
from pathlib import Path

# -------------------------------
# Variabler och filer
# -------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_LINUX = BASE_DIR / "data" / "linux_output.json"      # Linux JSON
DEFAULT_WINDOWS = BASE_DIR / "data" / "windows_output.csv"   # Windows CSV
DEFAULT_REPORT = BASE_DIR / "report" / "security_report.txt" # Rapport
RISKY_WINDOWS_SERVICES = {"Telnet","SMBv1","RemoteRegistry"}  # Riskabla tjänster

# -------------------------------
# Logging
# -------------------------------
logging.basicConfig(filename=BASE_DIR / 'report' / 'analysis.log',
                    level=logging.INFO,
                    format='%(asctime)s %(levelname)s: %(message)s')
logging.info("Startar analys...")  # Startlogg

# -------------------------------
# Funktioner
# -------------------------------
def parse_linux(path):
    logging.info(f"Läser Linux JSON från {path}")  # Logg
    if not path.exists():
        logging.warning("Linux JSON-fil saknas")  # Hantera saknad fil
        return []
    with path.open(encoding="utf-8") as f:
        return json.load(f)  # Läs JSON

def parse_windows(path):
    logging.info(f"Läser Windows CSV från {path}")  # Logg
    if not path.exists():
        logging.warning("Windows CSV-fil saknas")
        return []
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader([line for line in f if not line.startswith("#")])
        return [row for row in reader if row]  # Returnera list med rader

def summarize_linux(processes):
    total = len(processes)
    high = sum(1 for p in processes if p.get("risk","LOW")=="HIGH")
    return {"total_processes":total,"high_risk_processes":high,"processes":processes}

def summarize_windows(services):
    running = [s for s in services if s.get("Status","").lower()=="running"]
    risky = [s for s in running if s.get("Name") in RISKY_WINDOWS_SERVICES]
    return {"total_services":len(services),"running_services":len(running),
            "risky_services":risky,"services":services}

def build_report(linux_summary,windows_summary):
    lines=["Security report","================",""]
    if linux_summary:
        lines.append("Linux analysis:")
        lines.append(f"  Total processer: {linux_summary['total_processes']}")
        lines.append(f"  Hög risk: {linux_summary['high_risk_processes']}")
        if linux_summary['high_risk_processes']>0:
            lines.append("Riskprocesser:")
            for p in linux_summary["processes"]:
                if p.get("risk")=="HIGH":
                    lines.append(f"  - {p.get('command')} (PID {p.get('pid')}, user={p.get('user')})")
        lines.append("")
    if windows_summary:
        lines.append("Windows analysis:")
        lines.append(f"  Totalt antal tjänster: {windows_summary['total_services']}")
        lines.append(f"  Körande tjänster: {windows_summary['running_services']}")
        lines.append(f"  Riskabla körande tjänster: {len(windows_summary['risky_services'])}")
        for s in windows_summary["risky_services"]:
            lines.append(f"  - {s.get('Name')} ({s.get('Status')})")
        lines.append("")
    if not linux_summary and not windows_summary:
        lines.append("Ingen data hittades för analys.\n")
    return "\n".join(lines)

def write_report(report,path):
    path.parent.mkdir(parents=True,exist_ok=True)  # Skapa mapp om den saknas
    path.write_text(report+"\n",encoding="utf-8")  # Skriv rapport

# -------------------------------
# Main
# -------------------------------
def main():
    linux_data = parse_linux(DEFAULT_LINUX)
    windows_data = parse_windows(DEFAULT_WINDOWS)
    linux_summary = summarize_linux(linux_data) if linux_data else {}
    windows_summary = summarize_windows(windows_data) if windows_data else {}
    report = build_report(linux_summary,windows_summary)
    write_report(report,DEFAULT_REPORT)
    logging.info(f"Rapport skapad: {DEFAULT_REPORT}")  # Logg
    print(f"Rapport skapad: {DEFAULT_REPORT}")       # Terminalutskrift

if __name__=="__main__":
    main()
