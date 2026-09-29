# Atlas

Jede Sitzung in diesem Repo ist mit Atlas verbunden: Der SessionStart-Hook
`.claude/hooks/atlas-session-start.sh` lädt `GET /api/me/bootstrap` in den Kontext.
Fehlt der Bootstrap im Kontext, ist Atlas nicht verbunden. Dann steht im Kontext der Grund.

## Zugang

- Base URL: `$ATLAS_BASE_URL` (https://sharify-media-fzco-atlas.s2.sac.run/api)
- Schlüssel: `$ATLAS_API_KEY`, hinterlegt in der Cloud-Umgebung
- Aufruf: `curl -sS -H "Authorization: Bearer $ATLAS_API_KEY" "$ATLAS_BASE_URL/<pfad>"`
- Den Schlüssel nie ausgeben, nie in Dateien schreiben, nie committen.

## Orientierung

- `GET /api/onboarding`: Orientierung, Konventionen, erste Schritte
- `GET /api/info`: alle Bereiche, Mitglieder-System, Endpunkte
- `GET /api/<bereich>/info`: ein einzelner Bereich (Felder, Fallstricke, `conventionsDoc`)
- Unbekannte Pfade nicht raten, sondern im jeweiligen `/info` nachsehen.
- Wiki lesen: `GET /api/wikis/secondbrain/docs/<pfad>`

## Regeln

- Antwort-Envelope ist immer `{ data, meta?, error? }`. Listen paginieren per `cursor` + `limit`.
- Es gibt keinen Hard-Delete. Archiviert wird über `archivedAt` bzw. die `/archive`-Endpunkte.
  Achtung: `DELETE /api/companies/:id` löscht hart. Nie benutzen, stattdessen `POST /api/companies/:id/archive`.
  Kein `?hard=true` bei Kontakten oder Wiki-Dokumenten.
- Kontakt-Endpunkte liegen unter `/api/companies/contacts`. Einen Bereich `/api/contacts` gibt es nicht
  (Ausnahme: `GET /api/contacts/:id` für einen einzelnen Kontakt).
- Beim Anlegen von Aufgaben `assigneeIds` explizit setzen.
- Aufgaben und Projekte brauchen beim Anlegen `definitionOfDone`. Aufgaben brauchen `projectId` oder `dealId`.
  Bei Projektaufgaben kein `description` mitschicken, der Inhalt gehört in die Wiki-Notiz (`wikiDocPath`).
- Aufgaben filtern über `POST /api/tasks/search`.
- Geld als Integer-Cent (`*Cents`), Dauer in Minuten (`durationMin`), Datum als ISO-8601 mit Offset.
- Deutsche Texte mit echten Umlauten, Enums exakt wie dokumentiert.
