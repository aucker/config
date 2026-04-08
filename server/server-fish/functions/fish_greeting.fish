# ~/.config/fish/functions/fish_greeting.fish
function _vm_pages
    vm_stat | awk -v pat="$argv[1]" '$0 ~ pat {sub(/\./,"",$NF); print $NF}'
end

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
    printf "%s/%s GB (%s%%)" $used_gb $total_gb $pct
end

function _disk_info
    set total (diskutil info / | awk '/Container Total Space:/ {print $(NF-1),$NF}')
    set free  (diskutil info / | awk '/Container Free Space:/  {print $(NF-1),$NF}')
    if test -z "$total"; or test -z "$free"
        echo "(unavailable)"
        return
    end

    set total_val (echo $total | awk '{print $1}')
    set total_unit (echo $total | awk '{print $2}')
    set free_val (echo $free | awk '{print $1}')
    set free_unit (echo $free | awk '{print $2}')

    # normalize to GB
    switch $total_unit
        case "TB"
            set total_gb (math "$total_val * 1024")
        case "GB"
            set total_gb $total_val
        case '*'
            set total_gb (math "$total_val / 1024")
    end
    switch $free_unit
        case "TB"
            set free_gb (math "$free_val * 1024")
        case "GB"
            set free_gb $free_val
        case '*'
            set free_gb (math "$free_val / 1024")
    end

    set used_gb (math -s2 "$total_gb - $free_gb")
    set used_pct (math -s0 "100 * $used_gb / $total_gb")
    printf "%s/%s GB (%s%% used)" $used_gb $total_gb $used_pct
end

function fish_greeting
    echo
    printf " \e[1mOS:\e[0;32m %s\e[0m\n" (uname -sr)
    printf " \e[1mHostname:\e[0;32m %s\e[0m\n" (hostname)
    printf " \e[1mUptime:\e[0;32m %s\e[0m\n" (uptime | sed -E 's/.* up (.*), [0-9]+ users?.*/\1/')
    printf " \e[1mMemory:\e[0;32m %s\e[0m\n" (_mem_info)
    printf " \e[1mDisk:\e[0;32m %s\e[0m\n" (_disk_info)
    echo
end

