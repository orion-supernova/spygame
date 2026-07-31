# Load a dotenv file into the environment without running values through bash
# command interpretation. `source .env.local` chokes on values containing
# unquoted '|', '&', ';', '$()' etc. — common in keys/secrets. This loader:
#   - skips blanks and # comments
#   - strips matched surrounding "..." or '...'
#   - expands $VAR / ${VAR} / ${VAR:-default} (so $HOME paths still work)
#   - neutralizes command substitution and backticks
#
# Shared by deploy.sh, build_ios.sh and scripts/upload_appstore.sh.
load_env_file() {
    local file="$1"
    [ -f "$file" ] || return 1
    local line key value stripped first last safe
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        stripped="${line#"${line%%[![:space:]]*}"}"
        [ -z "$stripped" ] && continue
        [ "${stripped:0:1}" = "#" ] && continue
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        key="${key//[[:space:]]/}"
        key="${key#export}"
        [ -z "$key" ] && continue
        if [ ${#value} -ge 2 ]; then
            first="${value:0:1}"
            last="${value: -1}"
            if { [ "$first" = '"' ] && [ "$last" = '"' ]; } || \
               { [ "$first" = "'" ] && [ "$last" = "'" ]; }; then
                value="${value:1:${#value}-2}"
            fi
        fi
        safe="${value//\\/\\\\}"
        safe="${safe//\"/\\\"}"
        safe="${safe//\`/\\\`}"
        safe="${safe//\$(/\\\$(}"
        eval "value=\"$safe\""
        export "$key=$value"
    done < "$file"
}

# Resolve the App Store Connect .p8 path from the key id + optional dir
# override. Sets P8_FILE_PATH. Returns non-zero (without exiting) when the
# key can't be resolved, so callers decide whether that's fatal.
resolve_asc_key() {
    local key_dir="${APP_STORE_CONNECT_KEY_DIR:-$HOME/.appstoreconnect/private_keys}"
    [ -n "${APP_STORE_CONNECT_KEY_ID:-}" ] || return 1
    P8_FILE_PATH="$key_dir/AuthKey_$APP_STORE_CONNECT_KEY_ID.p8"
    [ -f "$P8_FILE_PATH" ]
}
