#!/usr/bin/env bash
# Legt einen neuen Bucket-List-Eintrag per Firestore REST API an.
# Wird von Claude Code genutzt, um Telegram-Nachrichten direkt als
# Eintrag in der "items"-Collection zu speichern (siehe CLAUDE.md).
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

project_id=$(grep -oP '(?<=projectId:\s")[^"]+' "$config_file")
api_key=$(grep -oP '(?<=apiKey:\s")[^"]+' "$config_file")

if [[ -z "$project_id" || -z "$api_key" ]]; then
  echo "Konnte projectId/apiKey nicht aus $config_file lesen." >&2
  exit 1
fi

created_at=$(date +%s%3N)

body=$(jq -n \
  --arg text "$text" \
  --arg category "$category" \
  --arg createdAt "$created_at" \
  '{fields: {text: {stringValue: $text}, category: {stringValue: $category}, status: {stringValue: "offen"}, liked: {booleanValue: false}, createdAt: {integerValue: $createdAt}}}')

response=$(curl -sS -X POST \
  "https://firestore.googleapis.com/v1/projects/${project_id}/databases/(default)/documents/items?key=${api_key}" \
  -H "Content-Type: application/json" \
  -d "$body")

doc_name=$(echo "$response" | jq -r '.name // empty')

if [[ -n "$doc_name" ]]; then
  echo "OK: Eintrag angelegt ($category): $text"
  echo "$doc_name"
else
  echo "Fehler beim Anlegen des Eintrags:" >&2
  echo "$response" >&2
  exit 1
fi
