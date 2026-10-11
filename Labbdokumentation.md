# Individuell inlämning – Labbmiljö, Git, CLI och AI

**Namn:** Freadon Negargar  
**Labbdatum enligt ursprungsrapport:** 27 september 2026  
**Dokumentation sammanställd:** 9 oktober 2026  
**Kurs:** Introduktion till yrkesrollen och grunderna i IT-infrastruktur secure cloud

## 1. Introduktion

Syftet är att dokumentera en virtuell labbmiljö med Windows och Ubuntu, nätverkskonfiguration och felsökning, kommandoradsarbete, versionshantering samt kritisk granskning av AI-stöd. Miljön beskrivs i mina tidigare labbunderlag som två virtuella maskiner i Oracle VirtualBox på ett gemensamt internt nätverk.

Denna sammanställning följer den individuella uppgiftens fyra delar. Mina tidigare uppladdade PDF rapporter och skärmdumpar används som underlag för genomförande och resultat. Övningsinstruktioner räknas inte som bevis för att jag har utfört ett moment.

### 2. Labbmiljö och nätverk

Enligt och skapades två virtuella maskiner i VirtualBox. Båda placerades på **Internal Network** med namnet **LabNet**. Statiska adresser dokumenterades i subnätet `192.168.1.0/24`.

| VM-namn i underlaget | Hostname i gästens operativsystem | Operativsystem | Dokumenterad statisk IP | Subnätmask | Standard gateway |
| --- | --- | --- | --- | --- | --- |
| WindowsLab | Saknar utskrift från `hostname` | Windows 11, exakt version saknas | 192.168.1.50 | 255.255.255.0 (/24) | Ingen enligt rapporten |
| Ubuntu | `fraidon-VirtualBox` syns i terminalprompt behöver bekräftas med `hostname` | Ubuntu Linux, version och serverutgåva behöver bekräftas | 192.168.1.51 | 255.255.255.0 (/24) | Ingen enligt rapporten |

VM-namnet i VirtualBox behöver inte vara samma som operativsystemets hostname. Skärmdumpen visar Ubuntu med grafiskt skrivbord detta fastställer inte att den installerade utgåvan är Ubuntu Server, vilket behöver kontrolleras mot uppgiftens krav på en Linux-server.

För kommunikation inom samma subnät används ingen standard gateway. Underlaget beskriver ett isolerat nät utan router. Internet och externa DNS tester är därför inte bevis för den interna kommunikationen och förutsätter en separat väg ut från miljön. Ett ytterligare nätverkskort kan ändra isoleringen samtliga aktiva adaptrar behöver verifieras.

### 2.2 Dokumenterad Linux-konfiguration

Nätverksrapporten anger följande Netplan-konfiguration och `sudo netplan apply`:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses: [192.168.1.51/24]
```

```bash
sudo netplan apply
```

Detta återger rapportens konfiguration. Ingen faktisk konfigurationsfil eller utskrift från `ip addr show` finns i det granskade underlaget som bekräftar filnamn, gränssnitt eller aktuell adress. Rapporten nämner `/etc/netplan/01-netcfg.yaml` det verkliga filnamnet måste kontrolleras i VMen.

Windows-adressen uppges ha konfigurerats manuellt. Den exakta inställningsproceduren och `ipconfig /all`utskriften saknas.

### 2.3 Observerade nätverkstester

Följande är avskrivna utdrag ur de befintliga skärmdumparna, inte nya terminalkörningar.

**Windows till Ubuntu – misslyckat test** (`felsöka nätverket labbmiljö..pdf`)

```text
PS C:\WINDOWS\system32> ping 192.168.1.51
Reply from 192.168.1.50: Destination host unreachable.
Reply from 192.168.1.50: Destination host unreachable.
Reply from 192.168.1.50: Destination host unreachable.
Reply from 192.168.1.50: Destination host unreachable.
Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

Trots texten `Received = 4`visar detta felmeddelanden från `192.168.1.50`, inte lyckade ekosvar från Ubuntu. Testet styrker därför inte fungerande Windows,Ubuntu,kommunikation.

**Ubuntu till Windows lyckat test**

```text
64 bytes from 192.168.1.50: icmp_seq=193 ttl=128 time=0.820 ms
...
64 bytes from 192.168.1.50: icmp_seq=218 ttl=128 time=0.786 ms
192.168.1.50 ping statistics
218 packets transmitted, 218 received, 0% packet loss
```

Mellanliggande rader har utelämnats i utdraget. Bilden visar lyckade svar från Windows-adressen. Den visar inte Ubuntus egen IP-konfiguration.

**Windows till egen dokumenterad adress**

```powershell
ping 192.168.1.50
```

Windows får svar, men enligt nätverkstabellen är detta Windows egen adress. Det ersätter inte det obligatoriska testet från Windows till Ubuntu på `192.168.1.51`.

### 2.4 Felsökning och bedömning

Nätverksrapporten beskriver kontroll av nätverksläge, IP-adresser och nätmask samt en tillfällig avstängning av Windows brandväggen. Skärmdumpen visar faktiskt:

```powershell
Set NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

Detta är en historisk åtgärd som stänger av samtliga tre brandväggsprofiler. Bilden visar lyckad ping från Ubuntu samtidigt, men bevisar inte att brandväggen var den enda orsaken till det tidigare felet. Ingen återaktivering visas. Slutlig verifiering bör göras med brandväggen aktiverad och en avgränsad regel för nödvändig labbtrafik, om sådan regel behövs.

Rapportens uppgift att borttagning av gateway gjorde nätverket identifierat saknar resultatbild. Att ett isolerat nät saknar gateway innebär inte i sig att Windows måste ändra etiketten `Unidentified Network`.

## 3. Kommandoradsgenomförande

### 3.1 Linux Bash

Följande steg finns dokumenterade i. De återges som dokumenterat genomförande men resultat för gruppägarskap och rättigheter behöver kompletteras med faktisk terminalutskrift.

**Steg 1 skapa mapp och fil:**

```bash
sudo mkdir -p /var/systementor/konsultdata
sudo touch /var/systementor/konsultdata/anteckningar.txt
```

**Steg 2 skapa gruppen:**

```bash
sudo groupadd konsulter
```

**Steg 3 tilldela grupp och begränsa rättigheter:**

```bash
sudo chown :konsulter /var/systementor/konsultdata
sudo chown :konsulter /var/systementor/konsultdata/anteckningar.txt
sudo chmod 750 /var/systementor/konsultdata
sudo chmod 640 /var/systementor/konsultdata/anteckningar.txt
```

`chown :konsulter` ändrar gruppen utan att uttryckligen ändra ägaren. Den faktiska ägaren behöver därför visas i resultatet.

| Objekt | Avsedd rättighet | Ägare | Gruppen konsulter | Övriga |
| --- | --- | --- | --- | --- |
| Mapp | 750 (`rwxr-x---`) | Läsa, skriva och traversera | Läsa och traversera | Ingen åtkomst |
| Textfil | 640 (`rw-r-----`) | Läsa och skriva | Läsa | Ingen åtkomst |

Detta följer principen om minsta möjliga behörighet: gruppen får endast de rättigheter som behövs och övriga får ingen åtkomst. Gruppmedlemmar får inte skriva i filen med dessa rättigheter. Mappens `x` betyder rätt att traversera katalogen textfilen behöver ingen körbehörighet.

**Steg 4 inspektera:**

```bash
ls -la /var/systementor/konsultdata
```

**Saknat bevis:** faktisk utskrift som visar gruppen på filen och rättigheterna på både mappen och filen. En lämplig kompletterande kontroll är:

```bash
getent group konsulter
ls -ld /var/systementor/konsultdata
ls -la /var/systementor/konsultdata
```

**Steg 5 nätverkskontroll:**

```bash
ping 192.168.1.50
ip addr show
```
Pingresultat finns i avsnitt 2.3. Utskrift från `ip addr show` saknas.

### 3.2 Windows PowerShell

**Steg 1 skapa mapp** dokumenterat i ursprungsrapporten:

```powershell
New-Item -ItemType Directory -Path "C:\Systementor\KonsultData"
```

**Steg 2 inspektera ACL:**

```powershell
Get-Acl "C:\Systementor\KonsultData"
```

```text
Directory: C:\Systementor
Path: KonsultData
Owner: BUILTIN\Administrators
Access: BUILTIN\Administrators Allow FullControl...
```

Åtkomstlistan är avkortad i bilden. Det går därför inte att fastställa alla konton, rättigheter eller arv från detta utdrag. En kompletterande läskontroll som visar fullständigare information är:

```powershell
Get-Acl "C:\Systementor\KonsultData" | Format-List Path,Owner,AccessToString
(Get-Acl "C:\Systementor\KonsultData").Access |
    Format-Table IdentityReference,FileSystemRights,AccessControlType,IsInherited -AutoSize
```

**Steg 3 nätverkskontroll**, dokumenterat i rapporten:

```powershell
ping 192.168.1.51
ipconfig /all
```

Det befintliga pingresultatet är misslyckat, se avsnitt 2.3. Ett nytt lyckat test mot Ubuntu samt faktisk `ipconfig /all`-utskrift behöver läggas till.

## 4. Git och versionshantering

### 4.1 Projekt och arbetsprocess

Jag kontrollerade min Git-historik med kommandona `git status` och `git log --oneline` i VS Code. Först upptäckte jag att mappen Downloads inte var ett Git-repository. Därefter hittade jag mitt tidigare projekt `labbmiljo-uppgift` på skrivbordet. Jag öppnade projektet i VS Code, kontrollerade mina tidigare commits och lade till min kompletterade labbdokumentation. Sedan skapade jag en ny commit för att dokumentera ändringarna.

Den tidigare Git-historiken dokumenteras i `Git Repo Historisk.pdf`. Skärmdumpen visar projektets ursprungliga commits och används som underlag för jämförelse med den aktuella Git-historiken.

Dokumenterade grundkommandon:

```bash
git init
git add .
git commit -m "<meddelande>"
git log --oneline
```

`<meddelande>` är en platshållare från underlaget. Den är inte ett faktiskt commit-meddelande. Inga GitHub ändringar eller nya commits har utförts vid denna sammanställning.

### 4.2 Faktisk synlig commit-historik

```text
6f89b32 (HEAD -> main, origin/main) Lägger till innehåll i Del 1 om Git-repå
3d749c6 Initierar repo och skapar dokumentationsfil
```

Skärmdumpen visar **två commits**. Markeringen `origin/main` är en lokalt lagrad referens och fastställer inte aktuell status på GitHub.

Övriga rapporter listar fem exempel på commit-meddelanden och påstår att commits har pushats. Dessa exempel saknar hashvärden och faktisk loggutskrift. De används därför inte som bevis för uppgiftens krav på minst 4–5 separata commits som speglar arbetsprocessen.

Bilden visar även ett felskrivet kommando:

```text
git log --online
fatal: unrecognized argument: --online
```

Felet korrigerades i bilden till `git log --oneline` vilket gav historiken ovan.

### 4.3 Återstående Git-verifiering

Kör läskontrollerna i det riktiga projektet och lägg till aktuell utskrift:

```bash
git remote -v
git status
git log --oneline
```

Om historiken fortfarande bara har två commits återstår verkligt arbete och separata commits för de faktiska kompletteringarna. Historiken ska spegla arbetsprocessen exempel eller påhittade äldre commits ersätter inte den. GitHub-publicering sker först efter separat godkännande. Canvas-inlämningen ska enligt uppgiften vara en länk till rätt GitHub-repository.

## 5. AI logg 

Den mer detaljerade AI loggen om `chmod` används som huvudsakligt underlag. Den kortare Git-förklaringen i ursprungsrapporten är ofullständig och ersätter inte denna logg.

**AI-verktyg och modell:** Inte angivet i underlaget.  
**Datum för AI-interaktionen:** Inte angivet.  
**Syfte:** Förstå Linux-filrättigheter och symbolisk respektive numerisk notation.

### 5.1 Dokumenterad prompt 

Ta bort rättigheter för andra

Detta är den prompt som sparats i rapporten. Ursprunglig chatt saknas, så exakt överensstämmelse med den skickade prompten kan inte kontrolleras.

### 5.2 Sparad sammanfattning av AI-svaret

Underlaget betecknar svaret som **sammanfattat, ordagrant där det är viktigt**. Nedanstående är återgivning av den sparade sammanfattningen, inte ett fullständigt originaltranskript.

AI svaret beskrev `chmod` som ett kommando för filers och katalogers behörigheter. Kategorierna var ägare (`u`) grupp (`g`) och övriga (`o`) med rättigheterna läsa (`r`) skriva (`w`) och köra (`x`) Symboliska exempel var:

```bash
chmod u+x fil.sh
chmod u+rw,g+r fil.txt
chmod o-rwx fil.txt
```

Numerisk notation förklarades som summor av `r=4`, `w=2` och `x=1`. `750` förklarades som ägare `rwx`, grupp `r-x` och övriga `---`.

Följande ytterligare:

```bash
chmod u+x,go-x fil.sh
chmod 740 fil.sh
chmod u+rw,g+r,o-rwx fil.txt
chmod 640 fil.txt
```

### 5.3 Kritisk granskning

Grundförklaringen av ägare, grupp, övriga och de oktala värdena är användbar. Det finns dock viktiga begränsningar som den tidigare loggen inte tydligt identifierade:

- `chmod u+x` lägger till körbehörighet för ägaren men tar inte bort befintlig körbehörighet för andra. För kravet att endast ägaren ska kunna köra behöver dessa rättigheter också tas bort, såsom i det sparade exemplet `u+x,go-x`.
- `chmod u+rw,g+r,o-rwx` tar bort övrigas rättigheter men tar inte bort befintlig skriv- eller körbehörighet för gruppen, eller ägarens körbehörighet. Det garanterar därför inte exakt `640` från alla utgångslägen.
- Numeriska `640` sätter de vanliga ägar grupp och övrigrättigheterna för textfilen till det avsedda mönstret. Symbolisk notation som exempelvis `u=rw,g=r,o=` uttrycker samma avsedda vanliga rättigheter explicit.
- Loggen anger att `chmod 640 fil.sh` visade `-rw-r-------`. Detta stämmer inte med `640` vars vanliga rättighetssträng är `-rw-r-----`. Den gamla raden kan vara ett skrivfel men utan originalutskrift går det inte att fastställa vad terminalen faktiskt visade.
- Ingen uppenbart påhittad kommandobeteckning har identifierats i de sparade exemplen. Den ofullständiga sammanfattningen räcker däremot inte för att granska hela originalsvaret.
- AI-svaret bör förstås före körning. För breda behörigheter kan ge obehörig åtkomst. I denna labb används begränsade rättigheter på den specifika katalogen och filen.

### 5.4 Dokumenterad verifiering och dess begränsning

AI-loggen uppger att svaret jämfördes med `man chmod` och att följande test utfördes:

```bash
touch fil.sh
chmod 640 fil.sh
ls -l fil.sh
chmod u+x fil.sh
ls -l fil.sh
```

Loggen uppger resultatet `-rwxr-----` efter tillagd körbehörighet och att `chmod o-rwx` på en fil med `644` gav `640`. Faktiska terminalbilder eller råutskrifter för dessa tester saknas. Den motsägelsefulla första rättighetssträngen gör att verifieringen behöver upprepas och dokumenteras i stället för att beskrivas som slutligt bekräftad.

**Reflektion:** AI kan hjälpa till att förklara syntax och strukturera dokumentation, men en korrekt klingande förklaring är inte bevis för vad som hände i labbmiljön. Skillnaden mellan att lägga till rättigheter och att sätta exakta rättigheter är central för minsta möjliga behörighet. Jag behöver kunna förklara kommandona och knyta min bedömning till faktisk utskrift.

AI har också använts den 9 oktober 2026 för att sammanställa denna Markdown-fil från befintliga källor och upptäcka motsägelser. Denna sammanställning har inte körts i mina VM och ersätter inte labbverifieringen.

## 7. Slutsats

Underlagen beskriver en labbmiljö i VirtualBox med två system och statiska adresser på ett internet nät. Befintliga bilder styrker Windows-mappen och en ACL-inspektion lyckad ping från Ubuntu till Windows samt två Git-commits. De visar också ett misslyckat pingtest från Windows och en avstängd Windows-brandvägg.
Dokumentationen är nu samlad enligt uppgiftens struktur, med kommandon, resultat och kritisk AI-granskning.
 