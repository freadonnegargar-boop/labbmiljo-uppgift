# Individuell inlämning – Labbmiljö, Git, CLI och AI

**Namn** Freadon Negargar  
**Labbdatum enligt ursprungsrapport** 27 september 2026  
**Dokumentation sammanställd** 18 oktober 2026  
**Kurs** Introduktion till yrkesrollen och grunderna i IT infrastruktur secure cloud

## 1. Introduktion

Syftet är att dokumentera en virtuell labbmiljö med Windows och Ubuntu nätverkskonfiguration och felsökning, kommandoradsarbete, versionshantering samt kritisk granskning av AI stöd. Miljön beskrivs i mina tidigare labbunderlag som två virtuella maskiner i Oracle VirtualBox på ett gemensamt internt nätverk.

Denna sammanställning följer den individuella uppgiftens fyra delar. Mina tidigare uppladdade PDF rapporter och skärmdumpar används som underlag för genomförande och resultat. Övningsinstruktioner räknas inte som bevis för att jag har utfört ett moment.

## 2. Labbmiljö och nätverk

Miljön består av två virtuella maskiner i VirtualBox: Ubuntu och WindowsLab. Båda är anslutna till det interna nätverket `intnet` med statiska IP adresser i subnätet `192.168.1.0/24`. Inställningarna verifierades den 17 oktober 2026.

| VM | Hostname | Operativsystem | Intern IP-adress | Subnätmask | Konfigurerad gateway på internt nätverkskort |
| --- | --- | --- | --- | --- | --- |
| Ubuntu | fraidon-VirtualBox | Ubuntu 26.04.1 LTS | 192.168.1.1 | 255.255.255.0 | Ingen |
| WindowsLab | Windowslab | Windows 11 | 192.168.1.50 | 255.255.255.0 | 192.168.1.1 |

Ubuntus interna nätverkskort heter `enp0s8` Ubuntu har även ett aktivt bryggat nätverkskort `enp0s3` med standard gateway `192.168.0.1`. Hela Ubuntu-maskinen är därför inte isolerad från det externa nätverket.

Windows har Ubuntu-adressen som gateway men vidarebefordran av trafik genom Ubuntu har inte verifierats. Kommunikation mellan maskinerna inom samma subnät kräver ingen gateway.

Ping lyckades i båda riktningarna. Efter felsökning av Windows brandvägg lyckades även ping från Ubuntu till Windows med brandväggen aktiverad.

Ubuntu har ett grafiskt skrivbord. Operativsystemets version är verifierad men installation som serverutgåva är ännu inte bekräftad.

### 2.1 Bilder på nätverksinställningarna

Ubuntus statiska IP adress på det interna nätverket:

![Ubuntu statisk IP adress](<Bilder/Ubuntu statisk IP jpg.jpg>)

Windows nätverksinställningar:

![Windows ipconfig](<Bilder/Windows ip config.jpg>)

### 2.2 Verifiering av operativsystem och hostname

Jag kontrollerade Ubuntus hostname med `hostname` och operativsystemets version med `cat /etc/os-release`. Resultatet visas i bilden nedan.

![Ubuntus operativsystem och hostname](<Bilder/operativsystemets version.jpg>)

#### 2.2.1 Verifiering av nätverksadresser

Den 11 oktober 2026 kontrollerade jag nätverkskonfigurationen i Ubuntu med kommandot `ip -br addr`.

Resultatet visade att nätverkskortet `enp0s3` hade IPv4-adresserna `192.168.50.10/24` och `192.168.0.69/24`, medan `enp0s8` hade adressen `192.168.1.1/24`. Båda nätverkskorten hade status UP.

Den tidigare dokumenterade IP adressen `192.168.1.51/24` kunde inte bekräftas vid denna kontroll. Resultatet visar därför att den aktuella konfigurationen skiljer sig från den tidigare dokumentationen.

Den 11 oktober 2026 kontrollerade jag min virtuella Ubuntu-maskin i Oracle VirtualBox med kommandona `hostname` och `cat /etc/os-release`.

Resultatet visade att datorns hostname är `fraidon-VirtualBox` och att operativsystemet är Ubuntu 26.04.1 LTS (Resolute Raccoon). Ubuntu körs med ett grafiskt skrivbord. Denna kontroll bekräftar systemets namn och version men inte att Ubuntu Server utgåvan är installerad.

Windows har statisk IP-adress 192.168.1.50. Nätverksinställningarna visas i ipconfig /all-utskriften i avsnitt 2.1.

### 2.3 Observerade nätverkstester
#### Kompletterande nätverkstest den 17 oktober 2026

Vid de nya testerna lyckades ping i båda riktningarna mellan Ubuntu (192.168.1.1) och Windows (192.168.1.50).

![Ping i båda riktningarna](<Bilder/Ping både riktningar Ubuntu-Windows.jpg>)

När Windows brandvägg aktiverades blockerades ping från Ubuntu. Vid kontroll upptäcktes att brandväggsregeln innehöll den felaktiga källadressen 198.168.1.1. Den korrigerades till 192.168.1.1 med:

    Set-NetFirewallRule -DisplayName "Labb - Ping fran Ubuntu" -RemoteAddress 192.168.1.1

Efter korrigeringen lyckades ping från Ubuntu till Windows med fyra mottagna paket och 0 % paketförlust. Windows brandvägg var aktiverad för Domain, Private och Public.

![Ping efter korrigering och aktiverad brandvägg](<Bilder/Ping brandvagg felsökning.jpg>)

#### Tidigare testresultat

Resultaten nedan visar tidigare tester och beskriver inte nätverkets slutliga tillstånd.
Följande är avskrivna utdrag ur de befintliga skärmdumparna, inte nya terminalkörningar.

**Windows till Ubunt misslyckat test** (`felsöka nätverket labbmiljö..pdf`)

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

Mellanliggande rader har utelämnats i utdraget. Bilden visar lyckade svar från Windows adressen. Den visar inte Ubuntus egen IP konfiguration.

**Windows till egen dokumenterad adress**

```powershell
ping 192.168.1.50
```

Ping till Windows egen adress testar bara den egna maskinen. Kommunikation från Windows till Ubuntu på 192.168.1.1 verifierades separat vid kompletteringen.

### 2.4 Felsökning och bedömning

Nätverksrapporten beskriver kontroll av nätverksläge, IP-adresser och nätmask samt en tillfällig avstängning av Windows brandväggen. Skärmdumpen visar faktiskt:

```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

Windows brandvägg stängdes tillfälligt av under den tidigare felsökningen. Vid kompletteringen verifierades att samtliga brandväggsprofiler var aktiverade. Efter korrigering av brandväggsregelns källadress lyckades ping från Ubuntu till Windows, se avsnitt 2.3.

Rapportens uppgift att borttagning av gateway gjorde nätverket identifierat saknar resultatbild. Att ett isolerat nät saknar gateway innebär inte i sig att Windows måste ändra etiketten `Unidentified Network`.

## 3. Kommandoradsgenomförande

### 3.1 Linux Bash

Följande kommandon dokumenterar genomförandet. Gruppägarskap och behörigheter verifierades den 17 oktober 2026 och visas under steg 4.

**Steg 1 skapa mapp och fil**

```bash
sudo mkdir -p /var/systementor/konsultdata
sudo touch /var/systementor/konsultdata/anteckningar.txt
```

**Steg 2 skapa gruppen**

```bash
sudo groupadd konsulter
```

**Steg 3 tilldela grupp och begränsa rättigheter**

```bash
sudo chown :konsulter /var/systementor/konsultdata
sudo chown :konsulter /var/systementor/konsultdata/anteckningar.txt
sudo chmod 750 /var/systementor/konsultdata
sudo chmod 640 /var/systementor/konsultdata/anteckningar.txt
```

`chown :konsulter` ändrar gruppen utan att uttryckligen ändra ägaren. Den faktiska ägaren behöver därför visas i resultatet.

| Objekt | Avsedd rättighet | Ägare | Gruppen konsulter | Övriga |
| --- | --- | --- | --- | --- |
| Mapp | 750 (`rwxr-x---`) | Läsa skriva och traversera | Läsa och traversera | Ingen åtkomst |
| Textfil | 640 (`rw-r-----`) | Läsa och skriva | Läsa | Ingen åtkomst |

Detta följer principen om minsta möjliga behörighet: gruppen får endast de rättigheter som behövs och övriga får ingen åtkomst. Gruppmedlemmar får inte skriva i filen med dessa rättigheter. Mappens `x` betyder rätt att traversera katalogen textfilen behöver ingen körbehörighet.

**Steg 4 inspektera**

```bash
ls -la /var/systementor/konsultdata
```

**Verifierat resultat den 17 oktober 2026**

Gruppen `konsulter` finns. Mappen och filen ägs av `root` och tillhör gruppen `konsulter`.

- Mappen har behörigheten `drwxr-x---` (750).
- Filen `anteckningar.txt` har behörigheten `-rw-r-----` (640).
- Övriga användare saknar åtkomst enligt dessa behörigheter.

Kontrollen gjordes med följande kommandon:

    getent group konsulter
    ls -ld /var/systementor/konsultdata
    sudo ls -la /var/systementor/konsultdata

![Verifiering av Linux-behörigheter](<Bilder/Felsökning .jpg>)

**Steg 5 nätverkskontroll**

```bash
ping 192.168.1.50
ip addr show
```
Pingresultat finns i avsnitt 2.3. Jag verifierade nätverkskortens adresser och status med `ip addr show` den 18 oktober 2026. Det interna nätverkskortet enp0s8 hade adressen 192.168.1.1/24 och status UP.

![Ubuntu – nätverkskort och IP-adresser](<Bilder/Ubuntu IP Addr.jpg>)

### 3.2 Windows PowerShell

**Steg 1 skapa mapp** dokumenterat i ursprungsrapporten:

```powershell
New-Item -ItemType Directory -Path "C:\Systementor\KonsultData"
```

**Steg 2 inspektera ACL**

```powershell
Get-Acl "C:\Systementor\KonsultData"
```

**Verifierat resultat den 17 oktober 2026**

Jag inspekterade mappens ägare och åtkomstlista med:

    Get-Acl "C:\Systementor\KonsultData" | Format-List Path,Owner,AccessToString

Ägaren är `BUILTIN\Administrators`. Åtkomstlistan visar bland annat:

| Grupp | Tillåten behörighet |
| --- | --- |
| BUILTIN\Administrators | FullControl |
| NT AUTHORITY\SYSTEM | FullControl |
| BUILTIN\Users | ReadAndExecute, Synchronize |
| NT AUTHORITY\Authenticated Users | Modify, Synchronize |

Authenticated Users har även en post som visas numeriskt som `-536805376`. Den behöver tolkas separat och återges därför inte som en namngiven behörighet här.

![Windows mappens ägare och behörigheter](<Bilder/Windows behörigheterna.jpg>)

**Steg 3 nätverkskontroll** dokumenterat i rapporten:

```powershell
ping 192.168.1.1
ipconfig /all
```

Vid det kompletterande testet lyckades ping från Windows till Ubuntu på 192.168.1.1 se avsnitt 2.3. Utskriften från `ipconfig /all` visas i avsnitt 2.1.

## 4. Git och versionshantering

### 4.1 Projekt och arbetsprocess

Jag kontrollerade min Git historik med kommandona `git status` och `git log --oneline` i VS Code. Först upptäckte jag att mappen Downloads inte var ett Git repository. Därefter hittade jag mitt tidigare projekt `labbmiljo-uppgift` på skrivbordet. Jag öppnade projektet i VS Code kontrollerade mina tidigare commits och lade till min kompletterade labbdokumentation. Sedan skapade jag en ny commit för att dokumentera ändringarna.

Den tidigare Git-historiken dokumenteras i `Git-Repo Historisk.pdf`. Skärmdumpen visar projektets ursprungliga commits och används som underlag för jämförelse med den aktuella Git historiken.

Dokumenterade grundkommandon:

```bash
git init
git add .
git commit -m "<meddelande>"
git log --oneline
```

`meddelande` är en platshållare från underlaget. Den är inte ett faktiskt commit meddelande.
### 4.2 Faktisk synlig commit-historik

```text
0a058fc Kompletterar nätverkstester och behörigheter med bildbevis
0facbb9 Kompletterar dokumentation av Git-historik
e692d96 Sammanställer labbdokumentation för labbmiljö Git CLI och AI
6f89b32 Lägger till innehåll i Del 1 om Git-repå
3d749c6 Initierar repo och skapar dokumentationsfil
```

Historiken visar fem separata commits som dokumenterar projektets utveckling. Utdraget kontrollerades med `git log --oneline` efter commit 0a058fc.

GitHub-repository: https://github.com/freadonnegargar-boop/labbmiljo-uppgift

### 4.3 Kontroll av repository och historik

Jag kontrollerade projektet med `git remote -v` `git status` och `git log --oneline`.

Remote `origin` pekar på:
https://github.com/freadonnegargar-boop/labbmiljo-uppgift.git

Efter commit `0a058fc` innehåller historiken fem commits. Denna commit sparade den kompletterade dokumentationen och åtta bildfiler.

## 5. AI logg och Utvärdering 

**AI verktyg** ChatGPT.
**Datum för AI interaktionen** 18 oktober 2026.
**Syfte** Förstå Linux behörigheterna 750 och 640 samt hur behörigheter och gruppägare kan kontrolleras utan ändringar.

### 5.1 Exakt prompt

Förklara vad chmod 750 på mappen /var/systementor/konsultdata och chmod 640 på filen anteckningar.txt innebär. Vad får ägaren, gruppen och övriga göra? Ge kommandon för att kontrollera behörigheter och gruppägare utan att ändra något.

### 5.2 Fullständigt AI svar

`chmod` ändrar behörigheter. De tre siffrorna gäller i ordningen **ägare, grupp och övriga**. Värdena är läsa = 4, skriva = 2 och köra/traversera = 1.

| Objekt | Ägare | Grupp | Övriga |
| --- | --- | --- | --- |
| Mapp: `750` (`rwxr-x---`) | Lista innehåll, skapa/ta bort namn och gå in i mappen | Lista innehåll och gå in i mappen | Ingen åtkomst |
| Fil: `640` (`rw-r-----`) | Läsa och ändra innehållet | Läsa innehållet | Ingen åtkomst |

För en mapp betyder `x` att kunna gå in i och passera genom mappen. Ingen får körbehörighet på filen med `640`. Gruppmedlemmarna kan läsa filen men inte ändra den med dessa behörigheter.

Kontrollera utan att ändra något:

```bash
# Visa själva mappens behörigheter, ägare och grupp
ls -ld /var/systementor/konsultdata

# Visa innehållets behörigheter ägare och grupp
sudo ls -la /var/systementor/konsultdata

# Kontrollera att gruppen finns
getent group konsulter
```

I `ls`utskriften kommer ägarens namn före gruppnamnet exempelvis `root konsulter` **chmod ändrar inte ägare eller grupp**

Förklaringen gäller vanliga Linux behörigheter. Åtkomst kräver även rättigheter till överordnade mappar ACL regler och administratörsrättigheter kan påverka den faktiska åtkomsten.

### 5.3 Kritisk granskning

Förklaringen av 750 och 640 stämmer med de behörigheter som visas i min tidigare terminalkontroll mappen har `drwxr-x---` och filen har `-rw-r-----` Båda ägs av `root` och tillhör gruppen `konsulter`.

Svaret skiljer korrekt mellan filers och mappars `x` behörighet och förklarar att chmod inte ändrar ägare eller grupp. Kontrollkommandona visar information utan att ändra behörigheterna.

Jag identifierade inga påhittade eller föråldrade kommandon i detta svar. En begränsning är att ls visar behörigheter men inte ensamt bevisar en viss användares faktiska åtkomst. Gruppmedlemskap, överordnade mappar och eventuella ACL regler behöver också beaktas.

Svaret föreslår inga bredare behörigheter eller rekursiva ändringar. sudo används endast för att läsa katalogens innehåll med administratörsrättigheter.

AI hjälpte till med förklaringen men jag behövde jämföra den med resultatet från min egen labbmiljö.

### 5.4 Dokumenterad verifiering och dess begränsning

Jag jämförde AI svaret från den 18 oktober 2026 med min dokumenterade terminalkontroll från den 17 oktober 2026 se bilden i Linux avsnittet.

Kontrollen visade:

- Gruppen `konsulter` finns.
- Mappen ägs av `root` tillhör `konsulter` och har behörigheten `drwxr-x---` (750).
- Filen `anteckningar.txt` ägs av `root` tillhör `konsulter` och har behörigheten `-rw-r-----` (640).

Resultatet stämmer med AI svarets förklaring av de vanliga behörigheterna. Kontrollen visar däremot inte ett praktiskt åtkomsttest med en användare i gruppen eller någon separat granskning av ACL regler.

**Reflektion** 
AI hjälper mig att förstå kommandon och strukturera dokumentationen. Jag behöver ändå förstå svaret och jämföra det med verkliga resultat. Ett trovärdigt formulerat svar är inte i sig ett bevis.

Jag har även använt ChatGPT för hjälp med felsökning och förslag till text i denna dokumentation. Terminalresultaten och skärmbilderna kommer från min egen labbmiljö.

## 6. Slutsats

Jag har dokumenterat en labbmiljö i VirtualBox med Ubuntu och Windows på det gemensamma interna nätverket intnet. Maskinerna har statiska IP-adresser i samma subnät och ping har lyckats i båda riktningarna.

I Linux verifierades gruppen konsulter och behörigheterna 750 för mappen samt 640 för filen. I Windows inspekterades mappens ägare och ACL med PowerShell.
Vid felsökningen upptäcktes en felaktig källadress i Windows brandväggsregel. Efter korrigeringen lyckades ping från Ubuntu till Windows med brandväggen aktiverad för samtliga profiler.

Arbetet har spårats med fem commits fram till det dokumenterade historikutdraget. AI loggen innehåller en exakt prompt ett fullständigt svar och en kritisk granskning kopplad till labbens resultat.
 