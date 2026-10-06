# Debugging Notes: Fish Shell Network Hang & SSID Redaction

## 1. Problem Statement
When opening a new `tmux` window on **macOS 27.0 ("Golden Gate", Darwin 27.0.0, Build 26A428)**, the shell startup sequence was freezing for over 30 seconds on the **Network** row of the system overview greeting (`fish_greeting`).

After resolving the delay, the network line displayed:
```text
Network:  en0 — <redacted> (192.168.31.27)
```
with an unexpected `<redacted>` placeholder instead of the Wi-Fi network name or interface label.

---

## 2. Root Cause Analysis

### A. The 30-Second Network Hang
- **Culprit Command**: In `_net_info` (`shell/shell-fish/.config/fish/functions/fish_greeting.fish`), the script queried the default routing interface using:
  ```fish
  set primary (route get default 2>/dev/null | awk '/interface:/{print $2}')
  ```
- **Reverse DNS Lookup**: Without the `-n` flag, macOS `route` attempts to resolve every IP address in the route entry (destination, gateway, interface) into a hostname via DNS reverse lookup (PTR query).
- **Tailscale MagicDNS Interaction**:
  - `scutil --dns` revealed that **Tailscale** was configured as the primary system resolver:
    ```text
    resolver #1
      search domain[0] : tail8aa8f3.ts.net
      nameserver[0] : 100.100.100.100
      order    : 100600
    ```
  - When `route` issued a reverse PTR lookup for the local router gateway `192.168.31.1` (`1.31.168.192.in-addr.arpa`), the query was directed to `100.100.100.100`.
  - Testing `dig @100.100.100.100 -x 192.168.31.1` verified that Tailscale's DNS dropped/timed out on this local private PTR request, blocking execution for **exactly 30 seconds**.
  - In contrast, standard public DNS (`114.114.114.114`) immediately returned `NXDOMAIN` in 79ms.
- **Why it worked previously on Tahoe (macOS 26)**:
  - Tailscale / MagicDNS was not active or was configured differently.
  - On networks where the router or DNS responder returns immediate `NXDOMAIN` or resolves the PTR locally, the reverse lookup completes in milliseconds without a timeout.

---

### B. The `<redacted>` Wi-Fi SSID
- **Privacy Protections**: Apple classifies Wi-Fi SSID and BSSID information as location-sensitive privacy data.
- **macOS 27 ("Golden Gate") Enforcement**:
  - Unprivileged processes and CLI tools without explicit **Location Services** permissions receive the literal string `"<redacted>"` for SSID fields from system services (including `ipconfig getsummary` and `system_profiler SPAirPortDataType`).
  - Previously, `networksetup -getairportnetwork` failed with `You are not associated with an AirPort network.` and fell back to `(no SSID)`.
  - Switching to `ipconfig getsummary` returned the literal `SSID : <redacted>`, which was printed directly as `en0 — <redacted> (192.168.31.27)`.

---

## 3. Implemented Fixes

File updated: `shell/shell-fish/.config/fish/functions/fish_greeting.fish`

1. **Bypass DNS Resolution**:
   Added `-n` to `route`:
   ```fish
   set primary (route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')
   ```
   This eliminates all DNS/PTR traffic, resolving the default interface in under **2ms** regardless of Tailscale, VPNs, or network connectivity.

2. **Handle Wi-Fi Type & Redacted SSID**:
   Updated `_net_info` to parse interface details and gracefully handle the `<redacted>` token:
   ```fish
   # query interface summary (filter out macOS privacy placeholder '<redacted>')
   set summary (ipconfig getsummary $primary 2>/dev/null)
   set iftype (printf "%s\n" $summary | awk -F ' : ' '/^  InterfaceType :/{print $2; exit}')
   set ssid (printf "%s\n" $summary | awk -F ' : ' '/^  SSID :/{print $2; exit}')

   if test -n "$ssid" -a "$ssid" != "<redacted>"
       printf "%s — %s (%s)" $primary $ssid $ip
   else if test "$iftype" = "WiFi"
       printf "%s — Wi-Fi (%s)" $primary $ip
   else
       printf "%s (%s)" $primary $ip
   end
   ```

---

## 4. Benchmark Comparison

| Metric | Before Fix | After Fix |
| :--- | :--- | :--- |
| **Startup Duration (uncached)** | **30.44 s** | **0.36 s** |
| **Startup Duration (cached)** | 0.02 s | 0.02 s |
| **Interface Resolution** | Hung on PTR lookup | **0.002 s** (`route -n`) |
| **Network Display** | `en0 — (no SSID)` (or `<redacted>`) | `en0 — Wi-Fi (192.168.31.27)` |

---

## 5. Git Diff Reference

```diff
diff --git a/shell/shell-fish/.config/fish/functions/fish_greeting.fish b/shell/shell-fish/.config/fish/functions/fish_greeting.fish
index 00e0724..4c059bc 100644
--- a/shell/shell-fish/.config/fish/functions/fish_greeting.fish
+++ b/shell/shell-fish/.config/fish/functions/fish_greeting.fish
@@ -72,8 +72,8 @@ end
 
 # --- Helper: network info (interface, SSID, IP) ---
 function _net_info
-    # find default interface
-    set primary (route get default 2>/dev/null | awk '/interface:/{print $2}')
+    # find default interface without DNS reverse lookup (-n)
+    set primary (route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')
     if test -z "$primary"
         printf "(offline)"
         return
@@ -83,15 +83,15 @@ function _net_info
     set ip (ipconfig getifaddr $primary 2>/dev/null)
     test -z "$ip"; and set ip "(no IP)"
 
-    # if Wi-Fi, get SSID cleanly
-    if string match -qr '^en[01]$' $primary
-        set rawssid (networksetup -getairportnetwork $primary 2>/dev/null)
-        if string match -qr '^Current Wi-Fi Network:' $rawssid
-            set ssid (string replace -r '^Current Wi-Fi Network: ' '' $rawssid)
-        else
-            set ssid "(no SSID)"
-        end
+    # query interface summary (filter out macOS privacy placeholder '<redacted>')
+    set summary (ipconfig getsummary $primary 2>/dev/null)
+    set iftype (printf "%s\n" $summary | awk -F ' : ' '/^  InterfaceType :/{print $2; exit}')
+    set ssid (printf "%s\n" $summary | awk -F ' : ' '/^  SSID :/{print $2; exit}')
+
+    if test -n "$ssid" -a "$ssid" != "<redacted>"
         printf "%s — %s (%s)" $primary $ssid $ip
+    else if test "$iftype" = "WiFi"
+        printf "%s — Wi-Fi (%s)" $primary $ip
     else
         printf "%s (%s)" $primary $ip
     end
```
