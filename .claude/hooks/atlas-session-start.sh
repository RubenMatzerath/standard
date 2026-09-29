#!/bin/bash
# SessionStart-Hook: verbindet jede Claude-Code-Sitzung mit Atlas.
# Holt GET /api/me/bootstrap und gibt ihn aus - die Ausgabe landet im Kontext der Sitzung.
# Der API-Schlüssel kommt aus der Umgebung (Cloud-Umgebung -> Umgebungsvariable ATLAS_API_KEY)
# und wird nie ausgegeben oder in Dateien geschrieben.
set -uo pipefail

ATLAS_BASE_URL="${ATLAS_BASE_URL:-https://sharify-media-fzco-atlas.s2.sac.run/api}"
MAX_CHARS=9000

# Schlüssel finden: bevorzugt ATLAS_API_KEY, sonst gängige Namen, sonst jede Variable mit atl_-Wert.
key_var=""
for v in ATLAS_API_KEY ATLAS_KEY ATLAS_TOKEN ATLAS_API_TOKEN; do
  if [ -n "${!v:-}" ]; then key_var="$v"; break; fi
done
if [ -z "$key_var" ]; then
  key_var="$(env | sed -n 's/^\([A-Za-z_][A-Za-z0-9_]*\)=atl_.*/\1/p' | head -n 1)"
fi

if [ -z "$key_var" ]; then
  echo "Atlas: kein API-Schlüssel gefunden (erwartet Umgebungsvariable ATLAS_API_KEY). Diese Sitzung ist NICHT mit Atlas verbunden."
  exit 0
fi

# Für Bash-Aufrufe in der Sitzung einheitlich ATLAS_BASE_URL und ATLAS_API_KEY bereitstellen.
# Es wird nur auf die vorhandene Variable verwiesen, der Wert selbst landet nicht in der Datei.
if [ -n "${CLAUDE_ENV_FILE:-}" ] && ! grep -q 'ATLAS_BASE_URL' "$CLAUDE_ENV_FILE" 2>/dev/null; then
  {
    echo "export ATLAS_BASE_URL='$ATLAS_BASE_URL'"
    if [ "$key_var" != "ATLAS_API_KEY" ]; then
      echo "export ATLAS_API_KEY=\"\$$key_var\""
    fi
  } >> "$CLAUDE_ENV_FILE"
fi

# Startart aus dem Hook-Input übernehmen (startup|resume|compact; clear zählt als startup).
input=""
if [ ! -t 0 ]; then input="$(cat)"; fi
source_kind="$(printf '%s' "$input" | grep -o '"source"[[:space:]]*:[[:space:]]*"[a-z]*"' | sed 's/.*"\([a-z]*\)"$/\1/')"
case "$source_kind" in
  startup|resume|compact) ;;
  *) source_kind="startup" ;;
esac

# Header über stdin übergeben, damit der Schlüssel nicht in der Prozessliste steht.
response="$(printf 'Authorization: Bearer %s' "${!key_var}" \
  | curl -sS --max-time 20 --retry 2 -H @- \
      -w '\n%{http_code}' \
      "$ATLAS_BASE_URL/me/bootstrap?source=$source_kind" 2>&1)"
status="${response##*$'\n'}"
body="${response%$'\n'*}"

if [ "$status" != "200" ]; then
  echo "Atlas: Bootstrap fehlgeschlagen (HTTP $status). Diese Sitzung ist NICHT mit Atlas verbunden."
  printf '%s\n' "$body" | head -c 500
  echo
  exit 0
fi

# Bei zu langer Ausgabe die Playbook-Beschreibungen kürzen (Namen und Pfade bleiben vollständig).
if [ "${#body}" -gt "$MAX_CHARS" ] && command -v python3 >/dev/null 2>&1; then
  body="$(printf '%s' "$body" | python3 -c '
import sys
out, in_playbooks = [], False
for line in sys.stdin.read().split("\n"):
    if line.startswith("## "):
        in_playbooks = line.startswith("## Playbooks")
    if in_playbooks and line.startswith("- ") and len(line) > 220:
        line = line[:220].rstrip() + " …"
    out.append(line)
sys.stdout.write("\n".join(out))
')"
  body="$body"$'\n'"(Playbook-Beschreibungen gekürzt; vollständig in playbooks/README.md.)"
fi

cat <<EOF
# Atlas verbunden (source=$source_kind)
Diese Sitzung ist mit Atlas verbunden. REST-API unter \$ATLAS_BASE_URL, Schlüssel in \$ATLAS_API_KEY.
Aufruf: curl -sS -H "Authorization: Bearer \$ATLAS_API_KEY" "\$ATLAS_BASE_URL/<pfad>" - den Schlüssel nie ausgeben.
Regeln für die API stehen in CLAUDE.md. Es folgt GET /api/me/bootstrap:

$body
EOF
