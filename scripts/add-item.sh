#!/usr/bin/env bash
# Legt einen neuen Bucket-List-Eintrag per Firestore REST API an.
# Wird von Claude Code genutzt, um Telegram-Nachrichten direkt als
# Eintrag in der "items"-Collection zu speichern (siehe CLAUDE.md).
#
# Braucht nur curl + Bash (kein jq).
#
# Nutzung: scripts/add-item.sh <category> "<text>"
set -euo pipefail

VALID_CATEGORIES=(ausflug essen kultur aktiv zuhause reise urlaub)

category="${1:?Kategorie fehlt (ausflug|essen|kultur|aktiv|zuhause|reise|urlaub)}"
text="${2:?Text fehlt}"

valid=false
for c in "${VALID_CATEGORIES[@]}"; do
  [[ "$category" == "$c" ]] && valid=true && break
done
if [[ "$valid" != true ]]; then
  echo "Ungültige Kategorie: $category (erlaubt: ${VALID_CATEGORIES[*]})" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$script_dir/../firebase-config.js"

project_id=$(sed -n 's/.*projectId: *"\([^"]*\)".*/\1/p' "$config_file" | head -n1)
api_key=$(sed -n 's/.*apiKey: *"\([^"]*\)".*/\1/p' "$config_file" | head -n1)

if [[ -z "$project_id" || -z "$api_key" ]]; then
  echo "Konnte projectId/apiKey nicht aus $config_file lesen." >&2
  exit 1
fi

created_at=$(date +%s%3N)

# JSON-Escaping ohne jq: Backslash, Anführungszeichen und Zeilenumbrüche behandeln.
json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\t'/\\t}
  s=${s//$'\r'/}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

text_escaped="$(json_escape "$text")"
category_escaped="$(json_escape "$category")"

body='{"fields":{"text":{"stringValue":"'"$text_escaped"'"},"category":{"stringValue":"'"$category_escaped"'"},"status":{"stringValue":"offen"},"liked":{"booleanValue":false},"createdAt":{"integerValue":"'"$created_at"'"}}}'

response=$(curl -sS -X POST \
  "https://firestore.googleapis.com/v1/projects/${project_id}/databases/(default)/documents/items?key=${api_key}" \
  -H "Content-Type: application/json" \
  -d "$body")

if echo "$response" | grep -q '"error"'; then
  echo "Fehler beim Anlegen des Eintrags:" >&2
  echo "$response" >&2
  exit 1
else
  echo "OK: Eintrag angelegt ($category): $text"
fi
