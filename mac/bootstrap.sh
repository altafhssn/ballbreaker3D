#!/usr/bin/env bash
# Smash Breaker — one-time Mac bootstrap (run on the Mac via Hermes).
# Idempotent: rerunning skips anything that's already installed.
#
# After this finishes, the Mac is ready for release_ios.sh to do its job
# without any human in the loop.

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/CHANGE-ME/SmashBreaker.git}"
WORK_DIR="${WORK_DIR:-$HOME/work/SmashBreaker}"
GODOT_VERSION="${GODOT_VERSION:-4.6.2-stable}"

echo "═══ Smash Breaker Mac bootstrap ═══"

# 1. Apple developer command-line tools (clang, git, etc).
if ! xcode-select -p &>/dev/null; then
  echo "→ Installing Xcode Command Line Tools (GUI prompt — accept it)"
  xcode-select --install
  echo "Wait for installation to finish, then rerun this script."
  exit 0
else
  echo "✓ Command Line Tools present"
fi

# 2. Full Xcode app.
if ! [ -d "/Applications/Xcode.app" ]; then
  cat <<'EOF'
✗ Xcode.app not installed.

Install it from the App Store (~10 GB download, free).
Search "Xcode", install, then:
  sudo xcodebuild -license accept
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

Then rerun this script.
EOF
  exit 1
else
  echo "✓ Xcode.app present"
fi

# 3. Homebrew (used to pull a few small CLI tools).
if ! command -v brew &>/dev/null; then
  echo "→ Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for this shell.
  if [ -d /opt/homebrew/bin ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  echo "✓ Homebrew present"
fi

# 4. Godot (universal binary).
GODOT_APP="$HOME/Applications/Godot.app"
GODOT_BIN="$GODOT_APP/Contents/MacOS/Godot"
if [ ! -x "$GODOT_BIN" ]; then
  echo "→ Installing Godot $GODOT_VERSION"
  mkdir -p "$HOME/Applications"
  cd /tmp
  curl -fsSL -o godot.zip \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_macos.universal.zip"
  unzip -oq godot.zip
  rm -rf "$GODOT_APP"
  mv Godot.app "$GODOT_APP"
  rm godot.zip
else
  echo "✓ Godot present at $GODOT_BIN"
fi

# 5. Export templates.
TEMPLATES_DIR="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}"
if [ ! -f "$TEMPLATES_DIR/ios.zip" ]; then
  echo "→ Installing Godot iOS export template"
  mkdir -p "$TEMPLATES_DIR"
  cd /tmp
  curl -fsSL -o templates.tpz \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz"
  python3 - <<PY
import zipfile, os, shutil
src = "/tmp/templates.tpz"
dest = os.path.expanduser("$TEMPLATES_DIR")
with zipfile.ZipFile(src) as z:
    for n in z.namelist():
        if "ios" in n.lower() or n.endswith("version.txt"):
            with z.open(n) as srcf, open(os.path.join(dest, os.path.basename(n)), "wb") as dst:
                shutil.copyfileobj(srcf, dst)
                print("extracted", os.path.basename(n))
PY
  rm templates.tpz
else
  echo "✓ iOS export template present"
fi

# 6. App Store Connect private key directory (you'll drop the .p8 here).
mkdir -p "$HOME/.appstoreconnect/private_keys"
echo "✓ ASC private-keys directory ready"

# 7. Repo checkout.
mkdir -p "$(dirname "$WORK_DIR")"
if [ ! -d "$WORK_DIR/.git" ]; then
  echo "→ Cloning project to $WORK_DIR"
  git clone "$REPO_URL" "$WORK_DIR"
else
  echo "→ Updating $WORK_DIR"
  git -C "$WORK_DIR" pull --rebase
fi

cat <<EOF

══════════════════════════════════════════
✓ Bootstrap complete.

Two remaining manual steps (browser only):

1. Sign Xcode into your Apple Developer account:
     open -a Xcode
     # Xcode → Settings → Accounts → "+" → Apple ID
     # Confirm team "Straw Hat Studio" (3HXZ723KGD) appears.

2. Generate an App Store Connect API key:
     https://appstoreconnect.apple.com → Users and Access →
     Integrations → App Store Connect API → Generate API Key
     Name: "Hermes Upload", Access: "App Manager"
     Download the .p8 once — save it to:
       ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8
     And note the Key ID and Issuer ID.

Then export these env vars (or put them in ~/.zshrc):
     export ASC_KEY_ID=<your-key-id>
     export ASC_ISSUER_ID=<your-issuer-uuid>

After that, run a release with:
     cd "$WORK_DIR"
     ./mac/release_ios.sh
══════════════════════════════════════════
EOF
