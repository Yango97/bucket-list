# Bucket-List – Hinweise für Claude Code

Statische Webseite (`index.html`) + Firestore als Backend (Config in
`firebase-config.js`). Kein Server, kein Build-Schritt.

## Telegram → Firestore Automatik

Dieses Repo ist an den Telegram-Bot `@YannikBucketListBot` gepairt. Nachrichten,
die über Telegram hereinkommen, sind **standardmäßig Ideen für die Bucket-List**,
kein Coding-Auftrag. Für so eine Nachricht:

1. **Kategorie bestimmen** anhand des Texts, eine von:
   - `ausflug` – Tagesausflüge, Orte in der Nähe besuchen
   - `essen` – Restaurants, Rezepte, Kochen/Backen, Getränke
   - `kultur` – Museum, Konzert, Theater, Kino, Ausstellung, Buch
   - `aktiv` – Sport, Wandern, Fitness, körperliche Aktivität
   - `zuhause` – Projekte/Aktivitäten für zu Hause
   - `reise` – Reisen/Trips (mehrtägig, ohne klassischen Urlaubscharakter)
   - `urlaub` – Urlaub im klassischen Sinn (Strand, Auszeit, Pauschalreise o. Ä.)

   Ist die Kategorie nicht eindeutig, die nächstliegende wählen (Kategorie lässt
   sich später in der App per Klick ändern) — nicht extra nachfragen, außer der
   Text ist wirklich unverständlich.

2. **Eintrag anlegen** mit:
   ```
   scripts/add-item.sh <category> "<text>"
   ```
   Das Skript liest `projectId`/`apiKey` aus `firebase-config.js` und legt per
   Firestore-REST-API (`POST .../documents/items`) ein Dokument an mit:
   `text` (Originaltext der Nachricht, ggf. leicht bereinigt/gekürzt),
   `category`, `status: "offen"`, `liked: false`, `createdAt` (Unix-ms).

3. **Kurz bestätigen**, z. B.: `✅ "<text>" unter <Kategorie> hinzugefügt.`
   Keine weiteren Rückfragen oder Erklärungen, wenn nicht nötig.

Mehrere Ideen in einer Nachricht (z. B. durch Zeilenumbruch/Aufzählung
getrennt) → für jede einzeln `add-item.sh` aufrufen.

Nur wenn eine Telegram-Nachricht eindeutig ein Coding-/Repo-Auftrag ist
(z. B. "ändere Feld X in index.html"), stattdessen normal als Entwicklungsaufgabe
behandeln statt als Bucket-List-Eintrag.

## Firestore-Zugriff allgemein

Die Firestore-Regeln erlauben offenen Lese-/Schreibzugriff (siehe README.md),
daher genügt ein einfacher REST-Aufruf ohne Auth-Token — Endpoint:
`https://firestore.googleapis.com/v1/projects/<projectId>/databases/(default)/documents/items?key=<apiKey>`.
`apiKey`/`projectId` niemals hart in Skripte eintragen, sondern aus
`firebase-config.js` lesen (dort können sie sich ändern).
