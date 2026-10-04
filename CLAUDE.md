# Atlas

Atlas läuft ausschließlich über den SAC-Connector (MCP-Server `Connector`).
Zu Beginn jeder Sitzung als Erstes den Bootstrap abrufen:
`call` mit `integration: "atlas"`, `method: "GET"`, `path: "/api/me/bootstrap?source=startup"`.
Der SessionStart-Hook `.claude/hooks/atlas-session-start.sh` erinnert daran, ruft Atlas aber selbst nicht auf.

## Zugang

- Kürzel der Integration: `atlas`. Pfade wie in der Atlas-Doku, mit `/api/...`.
- Zugangsdaten setzt der Connector serverseitig ein. Nie eigene mitschicken, keinen `ATLAS_API_KEY` verwenden.
- `list_integrations` und `my_access` zeigen leere Listen, obwohl `call` mit `atlas` funktioniert.
  Das Kürzel liefert `find_endpoints`. Bei 403 zuerst `my_access` aufrufen.
- Große Antworten und PDFs mit `binary: true` holen, PDFs mit `?format=base64`.

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
