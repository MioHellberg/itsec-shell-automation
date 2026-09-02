# IT Security Shell Automation

## Beskrivning

Detta projekt automatiserar grundläggande säkerhetskontroller i Linux och Windows med hjälp av Bash, PowerShell och Python.

* **Bash** används för att analysera Linux-processer.
* **PowerShell** används för att kontrollera Windows-tjänster, administratörskonton och misslyckade inloggningar.
* **Python** analyserar resultaten och skapar en säkerhetsrapport.

## Projektstruktur

```text
examination/
├── bash/
├── powershell/
├── python/
├── data/
├── report/
└── README.md
```

## Körning

### Linux

```bash
chmod +x bash/linux_check.sh
./bash/linux_check.sh
```

### Windows

```powershell
.\powershell\windows_check.ps1
```

### Python

```bash
python3 python/analysis_engine.py
```

## Resultat

Projektet skapar följande filer:

* `data/linux_output.json`
* `data/windows_output.csv`
* `data/anomalies.log`
* `report/security_report.txt`
* `report/analysis.log`

## Syfte

Syftet med projektet är att visa hur olika skriptspråk kan användas för att automatisera säkerhetskontroller och skapa en sammanfattande rapport över potentiella risker i ett system.
