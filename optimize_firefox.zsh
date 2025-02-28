#!/usr/bin/env zsh

# Locate Firefox profile directory
FF_PROFILE=$(find "$HOME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" | head -n 1)
FF_PREFS="$FF_PROFILE/prefs.js"

# Firefox Optimization - Reducing Disk Writes & RAM Usage
echo "Optimizing Firefox settings..."

if [[ -f $FF_PREFS ]]; then
    echo 'user_pref("browser.sessionstore.interval", 300000);' >> $FF_PREFS
    echo 'user_pref("browser.sessionstore.interval.idle", 3600000);' >> $FF_PREFS
    echo 'user_pref("browser.cache.disk.enable", false);' >> $FF_PREFS
    echo 'user_pref("browser.cache.memory.enable", true);' >> $FF_PREFS
    echo 'user_pref("browser.tabs.unloadOnLowMemory", true);' >> $FF_PREFS
    echo 'user_pref("dom.ipc.processCount", 4);' >> $FF_PREFS
    echo "Firefox optimizations applied!"
else
    echo "Firefox preferences file not found in $FF_PROFILE. Skipping..."
fi

# Function to monitor RAM and SSD writes
monitor_system() {
    echo "Monitoring RAM usage and SSD writes... (Press Ctrl+C to stop)"
    while true; do
        echo "----------------------------"
        free -h | awk '/^Mem:/ {print "RAM Used: "$3" / "$2}'
        iostat -xm 1 1 | awk '/sda/ {print "SSD Writes: "$10" MB/s"}'
        sleep 3
    done
}

# Start monitoring
monitor_system
