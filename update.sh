#!/usr/bin/env bash
#
# update.sh
#
# This script:
# 1. Automatically increments version and versionCode in update.json, module.prop, and changelog.md.
# 2. Downloads and merges hosts files into system/etc/hosts.
# 3. Creates install.zip.
# 4. (Optional) Commits and pushes changes to Git.

# --------------------------
# External Hosts URLs
# --------------------------
URL1="https://hosts.ubuntu101.co.za/hosts"
URL2="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
URL3="https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"

# -----------------------------------------------------------------------------
# 1. Retrieve and increment version info from update.json
# -----------------------------------------------------------------------------

# Extract the current version string: e.g., "v4.2.3"
CURRENT_VERSION=$(grep -oE '"version": "v[0-9]+\.[0-9]+\.[0-9]+"' update.json \
  | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')

# Extract the numeric part (e.g., "4.2.3")
NUM_VERSION=${CURRENT_VERSION#v}

# Split into major.minor.patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$NUM_VERSION"

# Increment just the PATCH part by 1
(( PATCH++ ))

# Reconstruct the new version string (e.g., "v4.2.4")
NEW_VERSION="v${MAJOR}.${MINOR}.${PATCH}"

# Extract the current versionCode: e.g., 20
CURRENT_VERSION_CODE=$(grep -oE '"versionCode": [0-9]+' update.json \
  | grep -oE '[0-9]+')

# Increment versionCode by 1
NEW_VERSION_CODE=$((CURRENT_VERSION_CODE + 1))

# -----------------------------------------------------------------------------
# 2. Update the files with the new version
# -----------------------------------------------------------------------------

# Update update.json
# Replace "version": "vX.X.X" with new version
sed -i "s/\"version\": \"$CURRENT_VERSION\"/\"version\": \"${NEW_VERSION}\"/" update.json

# Replace "versionCode": N with new versionCode
sed -i "s/\"versionCode\": $CURRENT_VERSION_CODE/\"versionCode\": $NEW_VERSION_CODE/" update.json

# -----------------------------------------------------------------------------
# 3. Prepend the new version info to changelog.md
# -----------------------------------------------------------------------------
sed -i "1s/^/## ${NEW_VERSION}\n- Updated hosts file\n\n/" changelog.md

# -----------------------------------------------------------------------------
# 4. Update module.prop with NEW_VERSION and NEW_VERSION_CODE
# -----------------------------------------------------------------------------
# Replace the line starting with "version=vX.X.X"
sed -i "s/^version=v[0-9.]\+/version=${NEW_VERSION}/" module.prop

# Replace the line starting with "versionCode=X"
sed -i "s/^versionCode=[0-9]\+/versionCode=${NEW_VERSION_CODE}/" module.prop

# -----------------------------------------------------------------------------
# 5. Download and combine hosts files into system/etc/hosts
# -----------------------------------------------------------------------------
mkdir -p system/etc

echo "Downloading and merging hosts files..."
curl -s "$URL1" > /tmp/hosts1
curl -s "$URL2" > /tmp/hosts2
curl -s "$URL3" > /tmp/hosts3

cat /tmp/hosts1 /tmp/hosts2 /tmp/hosts3 | sort | uniq > system/etc/hosts

# -----------------------------------------------------------------------------
# 6. Package everything into install.zip
# -----------------------------------------------------------------------------
zip -r install.zip system update.json changelog.md module.prop

# -----------------------------------------------------------------------------
# 7. (Optional) Commit and push to Git
# -----------------------------------------------------------------------------
# Uncomment the following lines if you want to auto-commit and push changes.
git add .
git commit -m "Update to ${NEW_VERSION} (versionCode: ${NEW_VERSION_CODE})"
git push origin main

echo "Creating GitHub Release for ${NEW_VERSION}..."

gh release create "${NEW_VERSION}" \
  --repo Magisk-Modules-Alt-Repo/Malwack \
  --title "Malwack ${NEW_VERSION}" \
  --notes "Release notes for ${NEW_VERSION}\n- Updated hosts file, etc." \
  install.zip

echo "GitHub Release created for ${NEW_VERSION}."

echo "Done!"
echo "Version updated from ${CURRENT_VERSION} to ${NEW_VERSION}"
echo "VersionCode updated from ${CURRENT_VERSION_CODE} to ${NEW_VERSION_CODE}"
echo "install.zip has been created."
