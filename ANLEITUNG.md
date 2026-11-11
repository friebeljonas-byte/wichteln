# Wichtel-Losung: Online-Version mit Supabase

Ein Link für die ganze Signal-Gruppe. Jede/r tippt auf den eigenen Namen, legt eine PIN fest,
sieht den eigenen Wichtel und trägt einen Wunsch ein.

## Einrichtung (einmalig, ca. 10 Minuten)

### 1. Supabase-Projekt anlegen
1. Auf https://supabase.com kostenlos registrieren und **New project** anlegen
   (Region z. B. *Central EU (Frankfurt)*).
2. Links **SQL Editor** öffnen, den kompletten Inhalt von `supabase.sql` einfügen und **Run** klicken.
   Erwartet: „Success. No rows returned“.
3. **Project Settings → API Keys** (bzw. **Data API**) öffnen und notieren:
   - die **Project URL**, z. B. `https://abcdefgh.supabase.co`
   - den **publishable key** (`sb_publishable_…`) oder den älteren **anon key** (`eyJ…`).
   Den **secret/service_role key nicht** verwenden.

### 2. Zugangsdaten eintragen
(Für dieses Repo schon erledigt.) In `index.html` oben im Skript die zwei Zeilen anpassen:

```js
const SUPABASE_URL = "https://abcdefgh.supabase.co";
const SUPABASE_KEY = "sb_publishable_…";
```

Der publishable/anon key ist öffentlich und darf in der Seite stehen. Die Datenbank ist trotzdem geschützt:
Die Tabellen sind für Browser gesperrt, und es gehen nur die Funktionen aus `supabase.sql`.

### 3. Seite veröffentlichen (eine Variante wählen)
- **Netlify Drop (am einfachsten):** https://app.netlify.com/drop öffnen und den Ordner mit `index.html`
  ins Fenster ziehen. Du bekommst sofort eine Adresse wie `https://xyz.netlify.app`.
  Mit einem kostenlosen Konto bleibt sie dauerhaft.
- **GitHub Pages:** im Repository unter *Settings → Pages* bei „Source“ **Deploy from a branch** wählen,
  den Branch mit `index.html` und den Ordner `/ (root)` auswählen und speichern. Nach ein bis zwei Minuten
  ist die App unter `https://<github-name>.github.io/wichteln/` erreichbar.

## Benutzung
1. Seite öffnen, Runde ausfüllen (Namen, Budget, Datum, Regeln) und **Auslosen** tippen.
2. Du landest auf deiner **Verwaltungsseite**. **Diesen Link speichern** (Lesezeichen, oder in Signal
   „Notiz an mich“ schicken), aber nicht teilen.
3. Die **Nachricht für die Signal-Gruppe** kopieren und in die Gruppe posten.
4. Alle tippen auf ihren Namen, legen eine PIN fest und sehen ihren Wichtel und dessen Wunschzettel.
5. Auf der Verwaltungsseite siehst du, wer schon angemeldet ist und wer einen Wunsch hat. Wer wen
   beschenkt, siehst du dort nicht. Nach der Bescherung kannst du die Runde löschen.

## Sicherheit
| Wer | Sieht was? |
|---|---|
| Supabase / jemand mit Datenbankzugriff | Nur verschlüsselte Daten. Der Schlüssel steht im Link hinter `#` und wird nie an den Server geschickt. |
| Andere aus der Gruppe | Ohne deine PIN nichts von dir. Nach 10 falschen PINs ist der Platz gesperrt. |
| Organisation (Verwaltungsseite) | Nur, wer angemeldet ist und einen Wunsch hat. Keine Zuordnungen, keine Wunschtexte. |
| Dein Wichtel | Deinen Wunsch (mit einem eigenen Schlüssel verschlüsselt). |

Grenzen:
- **Name „wegschnappen“:** Wer den Gruppenlink hat, könnte sich als jemand anderes anmelden, *bevor*
  die Person selbst es tut. Das fällt sofort auf: Die echte Person sieht „schon angemeldet“ und kommt nicht
  rein. Die Organisation gibt den Platz dann frei. Der Eindringling kennt dann aber die Zuordnung dieser Person.
  Im Zweifel neu auslosen.
- **Wer den Gruppenlink kennt** (z. B. weil er weitergeleitet wurde), kann sich dort anmelden. Also nur in
  der Signal-Gruppe teilen.
- **Wer die Seite hostet** (Netlify/GitHub), könnte die Seite theoretisch verändern. Dem Hoster vertraust du
  also. Nimm eine Adresse, die nur du kontrollierst.
- Die PIN wird auf dem Gerät gespeichert, damit man angemeldet bleibt. Auf fremden Geräten **Abmelden** tippen.

## Kosten
Der kostenlose Supabase-Tarif reicht locker. Achtung: Kostenlose Projekte werden nach etwa einer Woche
ohne Nutzung pausiert. Im Dashboard kann man sie mit einem Klick wieder aufwecken.
