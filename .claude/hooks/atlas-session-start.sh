#!/bin/bash
# SessionStart-Hook: erinnert jede Claude-Code-Sitzung daran, Atlas über den SAC-Connector zu laden.
# Der Hook selbst ruft Atlas nicht auf: Der Connector steht nur Claude als MCP-Server zur Verfügung,
# nicht der Shell. Es werden keine Schlüssel gelesen oder ausgegeben.
set -uo pipefail

# Startart aus dem Hook-Input übernehmen (startup|resume|compact; clear zählt als startup).
input=""
if [ ! -t 0 ]; then input="$(cat)"; fi
source_kind="$(printf '%s' "$input" | grep -o '"source"[[:space:]]*:[[:space:]]*"[a-z]*"' | sed 's/.*"\([a-z]*\)"$/\1/')"
case "$source_kind" in
  startup|resume|compact) ;;
  *) source_kind="startup" ;;
esac

cat <<OUT
# Atlas über den Connector (source=$source_kind)
Bevor du etwas anderes tust: Rufe über den MCP-Server Connector den Bootstrap ab:
  call  integration="atlas"  method="GET"  path="/api/me/bootstrap?source=$source_kind"
Der Bootstrap nennt Identität, Chef, Conventions, Pflicht-Dateien, Memories und Playbooks. Folge ihm.
Keine eigenen Zugangsdaten mitschicken. list_integrations darf leer sein, call mit "atlas" funktioniert trotzdem.
Klappt der Aufruf nicht, sag dem Nutzer, dass diese Sitzung nicht mit Atlas verbunden ist, und nenne den Fehler samt Quelle (Connector oder Atlas).
Regeln für die API stehen in CLAUDE.md.
OUT
