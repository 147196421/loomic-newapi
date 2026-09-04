#!/bin/sh
set -eu

: "${NEXT_PUBLIC_SERVER_BASE_URL:?NEXT_PUBLIC_SERVER_BASE_URL is required}"
: "${NEXT_PUBLIC_SUPABASE_URL:?NEXT_PUBLIC_SUPABASE_URL is required}"
: "${NEXT_PUBLIC_SUPABASE_ANON_KEY:?NEXT_PUBLIC_SUPABASE_ANON_KEY is required}"

replace_in_static_files() {
  token="$1"
  value="$2"
  escaped_value="$(printf '%s' "$value" | sed 's/[&|]/\\&/g')"

  find /usr/share/nginx/html -type f \( -name '*.html' -o -name '*.js' -o -name '*.json' \) | while IFS= read -r file; do
    sed -i "s|$token|$escaped_value|g" "$file"
  done
}

replace_in_static_files "https://runtime-api.invalid" "$NEXT_PUBLIC_SERVER_BASE_URL"
replace_in_static_files "https://runtime-supabase.invalid" "$NEXT_PUBLIC_SUPABASE_URL"
replace_in_static_files "runtime-supabase-anon-key" "$NEXT_PUBLIC_SUPABASE_ANON_KEY"
