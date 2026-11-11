# 🎁 Wichteln

Wichtel-Losung für Messenger-Gruppen (z. B. Signal oder WhatsApp): **ein Link für alle**, jede Person
sieht nur ihren eigenen Wichtel und dessen Wunschzettel. Ohne Konto, ohne E-Mail-Adressen, und
**Ende-zu-Ende-verschlüsselt**: Nicht einmal der Server weiß, wer wen beschenkt.

👉 **App:** https://friebeljonas-byte.github.io/wichteln/

---

## So funktioniert's

### Für die Organisation
1. App öffnen und die Runde ausfüllen:
   - Name der Runde, Budget, Datum der Bescherung, optional ein Hinweis
   - alle Teilnehmenden (mindestens 3)
   - optional Regeln: Paare, die sich nicht ziehen sollen; keine gegenseitigen Ziehungen;
     eine große Kette (A → B → C → … → A)
2. **„Auslosen und Runde anlegen“** tippen.
3. Du landest auf deiner **Verwaltungsseite** (Link mit `#a=…`).
   **Diesen Link sicher aufbewahren** (Lesezeichen oder „Notiz an mich“ im Messenger) und **mit niemandem teilen**.
4. Die fertige **Nachricht für die Gruppe** kopieren und in die Gruppe posten. Sie enthält den
   Gruppenlink (`#g=…`).
5. Auf der Verwaltungsseite siehst du, wer schon angemeldet ist und wer einen Wunsch eingetragen hat,
   aber **nicht, wer wen beschenkt**. Du kannst also selbst ganz normal mitmachen.

### Für alle Teilnehmenden
1. Den **Gruppenlink** aus der Gruppe öffnen.
2. Unter „Wer bist du?“ auf **den eigenen Namen** tippen.
3. Eine **PIN** festlegen (mindestens 4 Zeichen) und gut merken.
4. Jetzt siehst du, **wen du beschenkst**, und den **Wunschzettel** dieser Person.
5. Darunter deinen **eigenen Wunsch** eintragen. Lesen kann ihn nur dein Wichtel, ändern kannst du ihn jederzeit.

Die App läuft in jedem Browser, auf Handy, PC und Tablet. Auf einem anderen Gerät meldest du dich
einfach mit deinem Namen und deiner PIN an. Auf fremden Geräten danach **„Abmelden“** tippen.

---

## Häufige Fragen

**Ich habe meine PIN vergessen bzw. mein Platz ist gesperrt.**
Nach 10 falschen PINs wird ein Platz gesperrt. Die Organisation tippt auf der Verwaltungsseite bei dir auf
**„Freigeben“**. Danach meldest du dich mit einer neuen PIN an. Ein schon eingetragener Wunsch wird dabei
gelöscht.

**Bei meinem Namen steht „schon angemeldet“, aber ich war das nicht.**
Dann hat sich jemand unter deinem Namen angemeldet. Sag der Organisation Bescheid. Am saubersten ist es,
die Runde zu löschen und neu auszulosen, denn die andere Person kennt jetzt deine Zuordnung.

**Die Seite zeigt keine Namen zum Antippen.**
Du bist wahrscheinlich auf der Verwaltungsseite (`#a=…`). Öffne den Gruppenlink (`#g=…`), bei Bedarf in
einem neuen Tab oder nach einem Neuladen der Seite.

**Was passiert nach der Bescherung?**
Die Organisation kann die Runde auf der Verwaltungsseite mit **„Runde löschen“** komplett vom Server entfernen.

---

## Datenschutz und Sicherheit

- **Ende-zu-Ende-verschlüsselt:** Namen, Zuordnungen und Wünsche werden im Browser mit AES-GCM
  verschlüsselt. Der Schlüssel steht nur im Link hinter dem `#`. Dieser Teil wird von Browsern nie an
  einen Server geschickt. In der Datenbank liegen nur unlesbare Daten.
- **PIN-Schutz:** Die eigene Zuordnung bekommt nur, wer die PIN des Platzes kennt. Die PIN wird auf dem
  Server nur als Hash gespeichert (bcrypt).
- **Wunschzettel:** Jeder Wunsch hat einen eigenen Schlüssel. Lesen können ihn nur die Person selbst und
  ihr Wichtel.
- **Organisation:** Sie sieht nur, wer angemeldet ist und ob ein Wunsch vorhanden ist, keine Zuordnungen
  und keine Wunschtexte.

**Grenzen:**
- Wer den Gruppenlink kennt, kann einen *noch freien* Namen beanspruchen. Teilt den Link daher nur in
  eurer Gruppe.
- Das Gerät merkt sich die Anmeldung. Auf geteilten Geräten bitte abmelden.

---

## Technik

- `index.html`: die komplette App in einer einzigen Datei, ohne Build-Schritt und ohne externe
  Bibliotheken (Web Crypto API)
- `supabase.sql`: Datenbank für [Supabase](https://supabase.com). Tabellen sind gesperrt (Row Level
  Security), Zugriff nur über PIN-geschützte Funktionen
- `ANLEITUNG.md`: Einrichtung einer eigenen Instanz (Supabase-Projekt, Zugangsdaten, Veröffentlichung)
