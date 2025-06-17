#!/system/bin/sh

# === 1. Wait for System Boot ===
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 10
done

# Ensure stability after boot
sleep 10

# === 2. BusyBox Detection ===
busybox_path=""

if [ -f "/data/adb/magisk/busybox" ]; then
    busybox_path="/data/adb/magisk/busybox"
elif [ -f "/data/adb/ksu/bin/busybox" ]; then
    busybox_path="/data/adb/ksu/bin/busybox"
elif [ -f "/data/adb/ap/bin/busybox" ]; then
    busybox_path="/data/adb/ap/bin/busybox"
else
    echo "BusyBox not found, exiting." >> /data/adb/malwack.log
    exit 1
fi

# Ensure BusyBox is executable
if [ ! -x "$busybox_path" ]; then
    chmod +x "$busybox_path"
fi

# === 3. Copy Update Script to Writable Location ===
cp /data/adb/modules/Malwack/system/bin/au /data/local/tmp/au.sh
chmod +x /data/local/tmp/au.sh

# === 4. Setup Cron Directory and Permissions ===
mkdir -p /data/cron
chmod 700 /data/cron

# === 5. Read Update Interval from Configuration ===
minutes=1440  # Default to 1440 minutes (24 hours)

if [ -f "/data/adb/modules/Malwack/minutes.txt" ]; then
    read_minutes=$(cat /data/adb/modules/Malwack/minutes.txt)
    
    # Validate that the value is a positive integer
    if echo "$read_minutes" | grep -qE '^[0-9]+$'; then
        if [ "$read_minutes" -gt 1440 ]; then
            minutes=1440
            echo "Minutes value exceeds 24 hours. Set to 1440 minutes." >> /data/adb/malwack.log
        elif [ "$read_minutes" -lt 1 ]; then
            minutes=1
            echo "Minutes value is below 1. Set to 1 minute." >> /data/adb/malwack.log
        else
            minutes=$read_minutes
        fi
    else
        echo "Invalid value in minutes.txt. Defaulting to 1440 minutes." >> /data/adb/malwack.log
    fi
else
    echo "minutes.txt not found. Defaulting to 1440 minutes." >> /data/adb/malwack.log
fi

# === 6. Set Up Cron Job ===
echo "*/$minutes * * * * /data/local/tmp/au.sh" > /data/cron/root
chmod 600 /data/cron/root

# === 7. Initialize Logging ===
echo "Phone started at $(date)" > /data/adb/malwack.log
echo "Cron interval set to every $minutes minutes." >> /data/adb/malwack.log
echo "" >> /data/adb/malwack.log

# === 8. Run Update Script Immediately ===
/system/bin/sh /data/local/tmp/au.sh >> /data/adb/malwack.log 2>&1

# === 9. Start Cron Daemon ===
"$busybox_path" crond -c /data/cron -L /data/adb/malwack.log

# Verify Cron Daemon Start
if [ $? -eq 0 ]; then
    echo "Cron daemon started successfully." >> /data/adb/malwack.log
else
    echo "Failed to start cron daemon." >> /data/adb/malwack.log
    exit 1
fi
