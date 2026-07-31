# Terminal spinner helpers, shared by deploy.sh and build_ios.sh so a step
# looks the same whether you ran the full ship or just the build.
function finish { tput cnorm 2>/dev/null || true; }
trap finish EXIT

spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local spinstr='|/-\'
    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 $((${#spinstr} - 1))); do
            tput sc 2>/dev/null
            tput cup $(($(tput lines) - 1)) 0 2>/dev/null
            printf "%s %s" "${spinstr:$i:1}" "$message"
            tput rc 2>/dev/null
            sleep "$delay"
        done
    done
    tput sc 2>/dev/null
    tput cup $(($(tput lines) - 1)) 0 2>/dev/null
    printf "   %s\n" "$message"
    tput rc 2>/dev/null
    tput cnorm 2>/dev/null || true
}

run_with_spinner() {
    local description="$1"
    shift
    echo "$description..."
    "$@" &
    local pid=$!
    spinner "$pid" "$description"
    wait "$pid"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "  ✅ $description"
    else
        echo "  ❌ $description failed (exit $exit_code)"
        exit $exit_code
    fi
}
