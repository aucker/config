# ~/.config/fish/functions/fish_greeting.fish
# A fast, accurate macOS system overview shown on Fish shell startup.

# --- Helper: parse numeric values from vm_stat ---
function _vm_pages
    vm_stat | awk -v pat="$argv[1]" '$0 ~ pat {sub(/\./,"",$NF); print $NF}'
end

# --- Helper: memory info (accurate physical total) ---
function _mem_info
    set total_bytes (sysctl -n hw.memsize)
    set page_size (vm_stat | awk '/page size of/ {print $8}' | tr -d ')')
    test -z "$page_size"; and set page_size 4096

    set free_pages (_vm_pages "Pages free")
    set speculative_pages (_vm_pages "Pages speculative")
    set fileback_pages (_vm_pages "File-backed pages")
    test -z "$fileback_pages"; and set fileback_pages 0

    if test -z "$free_pages"; or test -z "$speculative_pages"
        echo "(unavailable)"
        return
    end

    set avail_pages (math "$free_pages + $speculative_pages + $fileback_pages")
    set avail_bytes (math "$avail_pages * $page_size")
    test $avail_bytes -gt $total_bytes; and set avail_bytes $total_bytes
    set used_bytes (math "$total_bytes - $avail_bytes")

    set used_gb  (math -s2 "$used_bytes  / 1024 / 1024 / 1024")
    set total_gb (math -s2 "$total_bytes / 1024 / 1024 / 1024")
    set pct (math -s0 "100 * $used_bytes / $total_bytes")

    printf "%6.2f / %-5.2f GB (%s%%)" $used_gb $total_gb $pct
end

# --- Helper: disk info (accurate APFS container) ---
function _disk_info
    set container (diskutil info -plist / | plutil -extract APFSContainerReference raw -o - - 2>/dev/null)
    if test -z "$container"
        printf "(unavailable)"
        return
    end

    set total_bytes (diskutil apfs list -plist $container | plutil -extract Containers.0.CapacityCeiling raw -o - - 2>/dev/null)
    set free_bytes  (diskutil apfs list -plist $container | plutil -extract Containers.0.CapacityFree    raw -o - - 2>/dev/null)

    if test -z "$total_bytes"; or test -z "$free_bytes"
        printf "(unavailable)"
        return
    end

    set used_bytes (math "$total_bytes - $free_bytes")
    set used_gb  (math -s1 "$used_bytes  / 1024 / 1024 / 1024")
    set total_gb (math -s1 "$total_bytes / 1024 / 1024 / 1024")
    set used_pct (math -s0 "100 * $used_bytes / $total_bytes")

    printf "%6.1f / %-5.1f GB (%s%%)" $used_gb $total_gb $used_pct
end

# --- Helper: battery percentage (portable Macs only) ---
function _battery_info
    set batt (pmset -g batt | grep -Eo "[0-9]+%" | head -n1)
    test -n "$batt"; and printf "%s" $batt; or printf "(n/a)"
end

# --- Helper: CPU model ---
function _cpu_info
    set cpu (sysctl -n machdep.cpu.brand_string 2>/dev/null)
    test -n "$cpu"; and echo $cpu; or echo "(unknown CPU)"
end

# --- Helper: network info (interface, SSID, IP) ---
function _net_info
    # find default interface
    set primary (route get default 2>/dev/null | awk '/interface:/{print $2}')
    if test -z "$primary"
        printf "(offline)"
        return
    end

    # get local IP
    set ip (ipconfig getifaddr $primary 2>/dev/null)
    test -z "$ip"; and set ip "(no IP)"

    # if Wi-Fi, get SSID cleanly
    if string match -qr '^en[01]$' $primary
        set rawssid (networksetup -getairportnetwork $primary 2>/dev/null)
        if string match -qr '^Current Wi-Fi Network:' $rawssid
            set ssid (string replace -r '^Current Wi-Fi Network: ' '' $rawssid)
        else
            set ssid "(no SSID)"
        end
        printf "%s — %s (%s)" $primary $ssid $ip
    else
        printf "%s (%s)" $primary $ip
    end
end

# --- aligned row printer (defined once globally) ---
#function _row -a max label
#    set value $argv[3..-1]
#    printf " %-*s: \e[0;32m%s\e[0m\n" $max $label $value
#end

function _row -a max label
    set value $argv[3..-1]

    # Compute label length separately
    set label_len (string length -- $label)
    set pad (math "$max - $label_len")
    set spaces (string repeat -n (math "$pad + 1") " ")

    printf " %s:%s\e[0;32m%s\e[0m\n" $label $spaces $value
end



function fish_greeting
    set cache /tmp/fish_greeting_cache

    # cache: reuse if less than 10s
    if test -f $cache; and test (math (date +%s) - (stat -f %m $cache)) -lt 10
        cat $cache
        return
    end

    # compute label width
    set labels OS Hostname Uptime Memory Disk Network Battery
    # CPU
    set max 0
    for L in $labels
        set len (string length -- $L)
        if test $len -gt $max
            set max $len
        end
    end

    begin
        echo
        set_color --bold; echo " System Overview"; set_color normal
        echo "───────────────────────────────────────────"

        _row $max OS        (uname -sr)
        _row $max Hostname  (hostname)
        _row $max Uptime    (uptime | sed -E 's/.* up (.*), [0-9]+ users?.*/\1/')
        _row $max Memory    (string trim (_mem_info))
        _row $max Disk      (string trim (_disk_info))
        _row $max Network   (_net_info)
        _row $max Battery   (_battery_info)
        #_row $max CPU       (_cpu_info)

        echo
    end | tee $cache
end

