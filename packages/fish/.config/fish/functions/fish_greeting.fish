# ~/.config/fish/functions/fish_greeting.fish
# A cached macOS/Linux overview with graceful fallbacks on other systems.

# --- Helper: parse numeric values from vm_stat ---
function __dotfiles_greeting_macos_vm_pages
    vm_stat 2>/dev/null | awk -v pat="$argv[1]" '$0 ~ pat {sub(/\./,"",$NF); print $NF}'
end

# --- Helper: memory info (accurate physical total) ---
function __dotfiles_greeting_macos_memory
    set -l total_bytes (sysctl -n hw.memsize 2>/dev/null)
    set -l page_size (vm_stat 2>/dev/null | awk '/page size of/ {print $8}' | tr -d ')')
    test -z "$page_size"; and set page_size 4096

    set -l free_pages (__dotfiles_greeting_macos_vm_pages "Pages free")
    set -l speculative_pages (__dotfiles_greeting_macos_vm_pages "Pages speculative")
    set -l fileback_pages (__dotfiles_greeting_macos_vm_pages "File-backed pages")
    test -z "$fileback_pages"; and set fileback_pages 0

    if not string match -qr '^[0-9]+$' -- "$total_bytes"; or test "$total_bytes" -le 0; or test -z "$free_pages"; or test -z "$speculative_pages"
        echo "(unavailable)"
        return
    end

    set -l avail_pages (math "$free_pages + $speculative_pages + $fileback_pages")
    set -l avail_bytes (math "$avail_pages * $page_size")
    test $avail_bytes -gt $total_bytes; and set avail_bytes $total_bytes
    set -l used_bytes (math "$total_bytes - $avail_bytes")

    set -l used_gb  (math -s2 "$used_bytes  / 1024 / 1024 / 1024")
    set -l total_gb (math -s2 "$total_bytes / 1024 / 1024 / 1024")
    set -l pct (math -s0 "100 * $used_bytes / $total_bytes")

    printf "%6.2f / %-5.2f GB (%s%%)" $used_gb $total_gb $pct
end

# --- Helper: disk info (accurate APFS container) ---
function __dotfiles_greeting_macos_disk
    set -l container (diskutil info -plist / 2>/dev/null | plutil -extract APFSContainerReference raw -o - - 2>/dev/null)
    if test -z "$container"
        printf "(unavailable)"
        return
    end

    set -l total_bytes (diskutil apfs list -plist $container 2>/dev/null | plutil -extract Containers.0.CapacityCeiling raw -o - - 2>/dev/null)
    set -l free_bytes  (diskutil apfs list -plist $container 2>/dev/null | plutil -extract Containers.0.CapacityFree    raw -o - - 2>/dev/null)

    if test -z "$total_bytes"; or test -z "$free_bytes"
        printf "(unavailable)"
        return
    end

    set -l used_bytes (math "$total_bytes - $free_bytes")
    set -l used_gb  (math -s1 "$used_bytes  / 1024 / 1024 / 1024")
    set -l total_gb (math -s1 "$total_bytes / 1024 / 1024 / 1024")
    set -l used_pct (math -s0 "100 * $used_bytes / $total_bytes")

    printf "%6.1f / %-5.1f GB (%s%%)" $used_gb $total_gb $used_pct
end

# --- Helper: battery percentage (portable Macs only) ---
function __dotfiles_greeting_macos_battery
    set -l batt (pmset -g batt 2>/dev/null | grep -Eo "[0-9]+%" | head -n1)
    test -n "$batt"; and printf "%s" $batt; or printf "(n/a)"
end

# --- Helper: CPU model ---
function __dotfiles_greeting_macos_cpu
    set -l cpu (sysctl -n machdep.cpu.brand_string 2>/dev/null)
    test -n "$cpu"; and echo $cpu; or echo "(unknown CPU)"
end

# --- Helper: network info (interface, SSID, IP) ---
function __dotfiles_greeting_macos_network
    # find default interface without DNS reverse lookup (-n)
    set -l primary (route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')
    if test -z "$primary"
        printf "(offline)"
        return
    end

    # get local IP
    set -l ip (ipconfig getifaddr $primary 2>/dev/null)
    test -z "$ip"; and set ip "(no IP)"

    # query interface summary (filter out macOS privacy placeholder '<redacted>')
    set -l summary (ipconfig getsummary $primary 2>/dev/null)
    set -l iftype (printf "%s\n" $summary | awk -F ' : ' '/^  InterfaceType :/{print $2; exit}')
    set -l ssid (printf "%s\n" $summary | awk -F ' : ' '/^  SSID :/{print $2; exit}')

    if test -n "$ssid" -a "$ssid" != "<redacted>"
        printf "%s — %s (%s)" $primary $ssid $ip
    else if test "$iftype" = "WiFi"
        printf "%s — Wi-Fi (%s)" $primary $ip
    else
        printf "%s (%s)" $primary $ip
    end
end


# Accept an optional file so the /proc parser can be checked offline.
function __dotfiles_greeting_linux_memory
    set -l meminfo /proc/meminfo
    if set -q argv[1]
        set meminfo "$argv[1]"
    end
    if not test -r "$meminfo"
        printf '(unavailable)'
        return
    end
    command awk '
        $1 == "MemTotal:" { total = $2 }
        $1 == "MemAvailable:" { available = $2; has_available = 1 }
        $1 == "MemFree:" { free = $2 }
        $1 == "Buffers:" { buffers = $2 }
        $1 == "Cached:" { cached = $2 }
        END {
            if (total <= 0) { printf "(unavailable)"; exit }
            if (!has_available) available = free + buffers + cached
            if (available < 0) available = 0
            if (available > total) available = total
            used = total - available
            printf "%6.2f / %-5.2f GB (%.0f%%)", used / 1048576, total / 1048576, 100 * used / total
        }
    ' "$meminfo"
end

function __dotfiles_greeting_linux_disk
    command df -Pk / 2>/dev/null | command awk '
        NR == 2 && $2 > 0 {
            printf "%6.1f / %-5.1f GB (%.0f%%)", $3 / 1048576, $2 / 1048576, 100 * $3 / $2
            found = 1
        }
        END { if (!found) printf "(unavailable)" }
    '
end

function __dotfiles_greeting_linux_battery
    set -l supply_root /sys/class/power_supply
    if set -q argv[1]
        set supply_root "$argv[1]"
    end
    for capacity in "$supply_root"/*/capacity
        if test -r "$capacity"
            set -l percent (string trim <"$capacity")
            if string match -qr '^[0-9]+$' -- "$percent"; and test "$percent" -le 100
                printf '%s%%' "$percent"
                return
            end
        end
    end
    printf '(n/a)'
end

function __dotfiles_greeting_linux_network
    if not command -q ip
        printf '(unavailable)'
        return
    end
    set -l primary (command ip -o -4 route show default 2>/dev/null | command awk '{ for (i=1; i<NF; i++) if ($i == "dev") { print $(i+1); exit } }')
    if test -z "$primary"
        printf '(offline)'
        return
    end
    set -l address (command ip -o -4 addr show dev "$primary" scope global 2>/dev/null | command awk '{ split($4, address, "/"); print address[1]; exit }')
    if test -z "$address"
        set address '(no IP)'
    end
    printf '%s (%s)' "$primary" "$address"
end

function __dotfiles_greeting_uptime
    if test "$argv[1]" = Linux
        set -l friendly (command uptime -p 2>/dev/null | string replace -r '^up ' '')
        if test -n "$friendly"
            printf '%s' "$friendly"
            return
        end
    end
    command uptime 2>/dev/null | command sed -E 's/.* up (.*), [0-9]+ users?.*/\1/'
end

function __dotfiles_greeting_row
    printf ' %-*s: \e[0;32m%s\e[0m\n' "$argv[1]" "$argv[2]" (string join ' ' -- $argv[3..-1])
end

function __dotfiles_greeting_render
    set -l system "$argv[1]"
    set -l memory '(unavailable)'
    set -l disk '(unavailable)'
    set -l network '(unavailable)'
    set -l battery '(n/a)'
    switch "$system"
        case Darwin
            set memory (__dotfiles_greeting_macos_memory)
            set disk (__dotfiles_greeting_macos_disk)
            set network (__dotfiles_greeting_macos_network)
            set battery (__dotfiles_greeting_macos_battery)
        case Linux
            set memory (__dotfiles_greeting_linux_memory)
            set disk (__dotfiles_greeting_linux_disk)
            set network (__dotfiles_greeting_linux_network)
            set battery (__dotfiles_greeting_linux_battery)
    end

    echo
    set_color --bold
    echo ' System Overview'
    set_color normal
    echo '───────────────────────────────────────────'
    __dotfiles_greeting_row 8 OS (uname -sr)
    __dotfiles_greeting_row 8 Hostname (hostname)
    __dotfiles_greeting_row 8 Uptime (__dotfiles_greeting_uptime "$system")
    __dotfiles_greeting_row 8 Memory "$memory"
    __dotfiles_greeting_row 8 Disk "$disk"
    __dotfiles_greeting_row 8 Network "$network"
    __dotfiles_greeting_row 8 Battery "$battery"
    echo
end

function fish_greeting
    set -l system (uname -s)
    set -l cache_root "$HOME/.cache"
    if set -q XDG_CACHE_HOME; and test -n "$XDG_CACHE_HOME"
        set cache_root "$XDG_CACHE_HOME"
    end
    set -l cache_dir "$cache_root/fish"
    set -l cache "$cache_dir/dotfiles-greeting-$system"

    if test -r "$cache"
        set -l modified
        switch "$system"
            case Darwin
                set modified (command stat -f %m "$cache" 2>/dev/null)
            case Linux
                set modified (command stat -c %Y "$cache" 2>/dev/null)
        end
        if string match -qr '^[0-9]+$' -- "$modified"
            set -l age (math (date +%s) - "$modified")
            if test "$age" -ge 0; and test "$age" -lt 10
                command cat "$cache"
                return
            end
        end
    end

    # Cache atomically in a private per-user directory. A read-only home is OK.
    if command mkdir -p -m 700 "$cache_dir" 2>/dev/null
        set -l temporary (command mktemp "$cache_dir/.greeting.XXXXXX" 2>/dev/null)
        if test -n "$temporary"
            __dotfiles_greeting_render "$system" | command tee "$temporary"
            command mv -f "$temporary" "$cache"
            return
        end
    end
    __dotfiles_greeting_render "$system"
end
