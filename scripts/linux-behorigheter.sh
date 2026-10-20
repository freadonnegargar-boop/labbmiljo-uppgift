#!/usr/bin/env bash
# Återskapar behörighetslabbens struktur i Ubuntu.
# Kör med: sudo bash linux-behorigheter.sh
# Ändrar endast mapparnas rättigheter, inte befintliga filers ACL.

set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo "Kör skriptet med sudo."
    exit 1
fi

if ! command -v setfacl >/dev/null 2>&1; then
    echo "Installera ACL-verktygen: sudo apt install acl"
    exit 1
fi

# Skapa grupper om de saknas.
for grupp in g_ledare g_personal; do
    if ! getent group "$grupp" >/dev/null; then
        groupadd "$grupp"
    fi
done

# Skapa användare om de saknas.
# Nya konton är låsta tills ett lösenord sätts med passwd.
if ! id alice >/dev/null 2>&1; then
    useradd -m -s /bin/bash -g g_ledare alice
fi

if ! id bob >/dev/null 2>&1; then
    useradd -m -s /bin/bash -g g_personal bob
fi

# Säkerställ medlemskap utan att ta bort andra grupper.
usermod -aG g_ledare alice
usermod -aG g_personal bob

mkdir -p /Projekt/Gemensamt /Projekt/Ledning

# Ta bort tidigare utökade ACL och standard-ACL på dessa mappar.
# Befintliga filer och undermappar ändras inte.
for mapp in /Projekt /Projekt/Gemensamt /Projekt/Ledning; do
    setfacl -b "$mapp"
    setfacl -k "$mapp"
done

chown root:root /Projekt
chmod 0755 /Projekt

# Gemensamt: båda grupperna får åtkomst.
chown root:g_ledare /Projekt/Gemensamt
chmod 2770 /Projekt/Gemensamt
setfacl -m g:g_personal:rwx /Projekt/Gemensamt
setfacl -d -m u::rwx,g::rwx,g:g_personal:rwx,m::rwx,o::--- \
    /Projekt/Gemensamt

# Ledning: endast g_ledare bland labbgrupperna.
chown root:g_ledare /Projekt/Ledning
chmod 2770 /Projekt/Ledning
setfacl -d -m u::rwx,g::rwx,o::--- /Projekt/Ledning

echo "Konfiguration klar. Kontrollera grupper och ACL:"
id alice
id bob
getfacl /Projekt/Gemensamt /Projekt/Ledning

echo "För nya konton: sätt lösenord med sudo passwd alice"
echo "och sudo passwd bob. Befintliga lösenord ändras inte."