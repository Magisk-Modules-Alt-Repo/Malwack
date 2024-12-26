# Perms
set_permissions() {
  set_perm $MODPATH/system/etc/hosts root root 0777  # -rwxrwxrwx
  set_perm $MODPATH/system/bin/malwack root root 0777  # -rwxrwxrwx
  set_perm $MODPATH/system/bin/au root root 0777  # -rwxrwxrwx
  set_perm $MODPATH/action.sh root root 0777  # -rwxrwxrwx
}

# Allow all the scripts to be executable
chmod +x $MODPATH/*.sh

# Do not modify
SKIPUNZIP=1
unzip -qjo "$ZIPFILE" 'common/functions.sh' -d $TMPDIR >&2
. $TMPDIR/functions.sh