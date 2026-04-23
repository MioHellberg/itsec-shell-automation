import json
import csv

# --- Läs JSON ---
# Öppnar filen och laddar in alla events i en lista
with open("events.json") as f:
    events = json.load(f)["events"]

# --- Läs CSV ---
# Skapar en dictionary (uppslagstabell) för användare
users = {}

with open("users.csv") as f:
    reader = csv.DictReader(f)
    for row in reader:
        # För varje användare sparar vi status + startar fail räknare på 0
        users[row["username"]] = {
            "status": row["status"],
            "fails": 0
        }

# --- Räkna failed logins ---
# Går igenom alla events och räknar misslyckade inloggningar
for event in events:
    if event["event"] == "failed_login":
        user = event["user"]

        # Om användaren finns i vår lista → öka fail-räknaren
        if user in users:
            users[user]["fails"] += 1

# --- Riskklassificering ---
# Funktion som avgör risknivå baserat på regler
def classify(userinfo):
    fails = userinfo["fails"]
    status = userinfo["status"]

    # BONUS: disabled + fails → CRITICAL
    if status == "disabled" and fails > 0:
        return "CRITICAL"

    # ≥ 3 fails → HIGH
    if fails >= 3:
        return "HIGH"

    # ≥ 1 fail → MEDIUM
    if fails >= 1:
        return "MEDIUM"

    # 0 fails → LOW
    return "LOW"

# --- Skapa rapport ---
# Skriver resultatet till en textfil
with open("risk_report.txt", "w") as report:
    for username, info in users.items():
        risk = classify(info)

        # Skriver en rad per användare
        report.write(
            f"{username}: {risk} (fails: {info['fails']}, status: {info['status']})\n"
        )

print("Analysen är klar. Se risk_report.txt.")