#!/usr/bin/env bash
# Smash Breaker — release pipeline (Mac side, runs via Hermes).
#
# Pulls latest, re-exports the Xcode project via headless Godot, archives
# with xcodebuild (automatic signing, Apple handles certs/profiles),
# exports a signed .ipa, uploads to TestFlight via altool.
#
# Env vars required (set in ~/.zshrc after bootstrap):
#   ASC_KEY_ID        — App Store Connect API key ID
#   ASC_ISSUER_ID     — App Store Connect issuer UUID
# Env vars with sane defaults:
#   APPLE_TEAM_ID     — Apple Developer Team ID (default: 3HXZ723KGD)
#   BUNDLE_ID         — Bundle identifier (default: studio.strawhat.smashbreaker)
#   WORK_DIR          — repo root (default: $HOME/work/SmashBreaker)

set -euo pipefail

APPLE_TEAM_ID="${APPLE_TEAM_ID:-3HXZ723KGD}"
BUNDLE_ID="${BUNDLE_ID:-studio.strawhat.smashbreaker}"
WORK_DIR="${WORK_DIR:-$HOME/work/SmashBreaker}"
GODOT_BIN="${GODOT_BIN:-$HOME/Applications/Godot.app/Contents/MacOS/Godot}"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID:-MISSING}.p8"

# Sanity checks.
for var in ASC_KEY_ID ASC_ISSUER_ID; do
  if [ -z "${!var:-}" ]; then
    echo "✗ \$${var} is not set. Run the env-var lines from bootstrap output."; exit 1
  fi
done
[ -x "$GODOT_BIN" ] || { echo "✗ Godot not at $GODOT_BIN — rerun bootstrap.sh"; exit 1; }
[ -f "$KEY_PATH" ]  || { echo "✗ ASC key not at $KEY_PATH"; exit 1; }
[ -d "$WORK_DIR" ]  || { echo "✗ Project missing at $WORK_DIR"; exit 1; }

cd "$WORK_DIR"

echo "═══ Pulling latest ═══"
git pull --rebase

echo "═══ Headless import + export Xcode project ═══"
"$GODOT_BIN" --headless --path SmashBreaker --import || true
mkdir -p builds/ios
"$GODOT_BIN" --headless --path SmashBreaker --export-release "iOS" \
  "../builds/ios/SmashBreaker.ipa" || true

XCPROJ="builds/ios/SmashBreaker.xcodeproj"
[ -d "$XCPROJ" ] || { echo "✗ Xcode project not produced. Check Godot iOS preset."; exit 1; }

ARCHIVE="builds/ios/SmashBreaker.xcarchive"
IPA_OUT="builds/ios/ipa"
rm -rf "$ARCHIVE" "$IPA_OUT"
mkdir -p "$IPA_OUT"

echo "═══ Archiving (xcodebuild auto-signing) ═══"
xcodebuild \
  -project "$XCPROJ" \
  -scheme SmashBreaker \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  archive

echo "═══ Exporting signed .ipa ═══"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist mac/export_options.plist \
  -exportPath "$IPA_OUT" \
  -allowProvisioningUpdates

IPA="$IPA_OUT/SmashBreaker.ipa"
[ -f "$IPA" ] || { echo "✗ Export did not produce $IPA"; exit 1; }
echo "✓ Signed .ipa: $IPA ($(du -h "$IPA" | cut -f1))"

echo "═══ Uploading to TestFlight ═══"
xcrun altool --upload-app \
  --type ios \
  --file "$IPA" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"

cat <<EOF

══════════════════════════════════════════
✓ Build uploaded to App Store Connect.
  • Processing usually completes in ~5-30 minutes.
  • Check: https://appstoreconnect.apple.com → My Apps → Smash Breaker → TestFlight
  • Once "Ready to Test", install via the TestFlight app on your phone.

To release as an App Store version, go to the version's "Prepare for
Submission" page, attach this build, fill in screenshots + listing,
and Submit for Review.
══════════════════════════════════════════
EOF
