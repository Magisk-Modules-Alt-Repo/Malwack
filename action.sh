#!/system/bin/sh

echo " "
echo " "
echo "                    lll                           kk     "
echo "mm mm mmmm    aa aa lll ww      ww   aa aa   cccc kk  kk "
echo "mmm  mm  mm  aa aaa lll ww      ww  aa aaa cc     kkkkk  "
echo "mmm  mm  mm aa  aaa lll  ww ww ww  aa  aaa cc     kk kk  "
echo "mmm  mm  mm  aaa aa lll   ww  ww    aaa aa  ccccc kk  kk "
echo " "
echo " By Person0z"
echo " "

# === Define Paths ===
MODDIR=${0%/*}
HOSTS_FILE="$MODDIR/system/etc/hosts"
TMP_DIR="/data/local/tmp"
LOG_FILE="/data/adb/malwack.log"
MERGED_HOSTS="/data/local/tmp/hosts"
URLS_FILE="$MODDIR/urls.txt"

# === Logging Function ===
log() {
    echo "[$(date '+%m-%d %H:%M')] $1" | tee -a "$LOG_FILE"
}

# === Abort Function for Errors ===
abort() {
    log "Error: $1"
    exit 1
}

# === Download Hosts Files from `urls.txt` ===
download_hosts() {
    log "Starting hosts download from $URLS_FILE..."
    if [ ! -f "$URLS_FILE" ]; then
        abort "URLs file not found at $URLS_FILE"
    fi
    
    index=1
    while IFS= read -r url || [ -n "$url" ]; do
        # Skip empty lines and comments
        [[ "$url" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$url" ]] && continue
        
        target="$TMP_DIR/hosts$index"
        log "Downloading hosts file from $url..."
        curl -s "$url" -o "$target" || {
            log "Failed to download $url"
            continue
        }
        log "Downloaded hosts$index successfully."
        index=$((index + 1))
    done < "$URLS_FILE"
}

# === Merge Hosts Files ===
merge_hosts() {
    log "Merging downloaded hosts files..."
    cat "$TMP_DIR"/hosts* | grep -vE '^[[:space:]]*#' | grep -vE '^[[:space:]]*$' | sort | uniq > "$MERGED_HOSTS" || {
        log "Failed to merge hosts files"
        exit 1
    }
    log "Hosts files merged successfully."
}

# === Apply Hosts File via Magisk Overlay ===
apply_hosts_magisk() {
    log "Applying merged hosts file via Magisk overlay..."
    mkdir -p "$(dirname "$HOSTS_FILE")"
    cp "$MERGED_HOSTS" "$HOSTS_FILE" || {
        log "Failed to copy merged hosts file to $HOSTS_FILE"
        exit 1
    }
    chmod 644 "$HOSTS_FILE"
    chown root:root "$HOSTS_FILE"
    log "Merged hosts file applied successfully."
}

# === Restart DNS Services ===
restart_dns() {
    log "Restarting DNS services to apply the new hosts file..."
    setprop net.dns1 8.8.8.8
    setprop net.dns2 8.8.4.4
    log "DNS services restarted."
}

# === Cleanup Temporary Files ===
cleanup() {
    log "Cleaning up temporary files..."
    rm -f "$TMP_DIR"/hosts* "$MERGED_HOSTS"
    log "Temporary files cleaned successfully."
}

# === Update Module Description ===
update_module_prop() {
    MODULE_PROP="$MODDIR/module.prop"
    log "Updating module.prop with current date..."
    string="description=(Updated: $(date)) Ever wanted to get rid of those annoying ads that pop every 2 seconds in mobile games you're playing or websites you are visiting? Well, look no further with Malwack, your defense against ads!"
    sed -i "s/^description=.*/$string/g" "$MODULE_PROP"
    log "module.prop updated successfully."
}

# === Main Logic ===
log "Starting dynamic hosts update..."

# Download, Merge, and Apply Hosts
download_hosts
merge_hosts
apply_hosts_magisk
restart_dns
cleanup
update_module_prop

log "Dynamic hosts update completed successfully!"

echo ""
echo "Hosts file updated successfully!"
echo ""
