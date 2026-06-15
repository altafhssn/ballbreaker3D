# Briefing for the Hermes agent on the Mac

Paste this whole file (or its substance) into the Hermes session. It tells
Hermes what to do, what's expected, and what to ask the user for.

---

## Context

You are running on a brand-new Mac. The user is on a Windows PC and is
coordinating with you remotely. They have just pushed a Godot 4.6.2 game
called **Smash Breaker** to a private GitHub repo. Your job is to take that
project and ship an iOS build to TestFlight (App Store Connect).

**Apple Team ID:** `3HXZ723KGD`
**Bundle ID:** `studio.strawhat.smashbreaker`
**Project repo path on Mac (target):** `~/work/SmashBreaker`

Two helper scripts live in the repo at `mac/`:
- `mac/bootstrap.sh` — one-time Mac setup (Xcode/Homebrew/Godot/templates)
- `mac/release_ios.sh` — per-release build + sign + TestFlight upload

## Your task in 5 steps

### 1. Confirm prerequisites with the user
Ask them for the **GitHub repo URL** (HTTPS clone URL, e.g.
`https://github.com/<their-user>/SmashBreaker.git`) and a **personal access
token** if the repo is private. Set the env vars accordingly:

```bash
export REPO_URL="<the URL>"
# For private repos, embed the token:
# REPO_URL="https://<user>:<token>@github.com/<user>/SmashBreaker.git"
```

### 2. Run bootstrap
```bash
bash <(curl -fsSL "$REPO_URL/raw/main/mac/bootstrap.sh") || true
# If curl fails (private repo / token in URL), clone first then run:
git clone "$REPO_URL" ~/work/SmashBreaker
cd ~/work/SmashBreaker
bash mac/bootstrap.sh
```

The script handles: Xcode Command Line Tools, Homebrew, Godot binary, Godot
iOS export template, App Store Connect private keys directory, repo clone.
It **will pause and tell you what to do** if Xcode.app itself is missing
(must be installed from the Mac App Store — large download, you cannot do
that headlessly).

### 3. Walk the user through the two manual web-UI steps
After bootstrap completes, two things require their browser:

**a) Apple Developer Program**
The Mac/Hermes can do nothing if there is no active Apple Developer
membership ($99/yr). Confirm with the user that they have one. If not, point
them to https://developer.apple.com/programs/ — enrolment takes 1-2 days.

**b) App Store Connect API key**
This is the credential that lets you upload to TestFlight from the command
line. Direct the user to:
- https://appstoreconnect.apple.com → Users and Access → Integrations →
  App Store Connect API → **Generate API Key**
- Name: "Hermes Upload", Access: **App Manager**
- Download the `.p8` file (only downloadable ONCE) and note the **Key ID**
  and **Issuer ID** from the page.

Ask the user to send you (Hermes):
- The `.p8` file content (paste the text, or base64'd)
- The Key ID (10-char)
- The Issuer ID (UUID)

Save the .p8 to:
```
~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8
```
And export the IDs:
```bash
export ASC_KEY_ID="<10-char key id>"
export ASC_ISSUER_ID="<issuer uuid>"
# Persist them:
echo "export ASC_KEY_ID=\"$ASC_KEY_ID\"" >> ~/.zshrc
echo "export ASC_ISSUER_ID=\"$ASC_ISSUER_ID\"" >> ~/.zshrc
```

Also, before the first archive, you must sign Xcode into the Apple
Developer account once. Run:
```bash
open -a Xcode
```
Xcode → Settings → Accounts → "+" → Apple ID. The user provides credentials.

### 4. Run the release script
```bash
cd ~/work/SmashBreaker
./mac/release_ios.sh
```

This will:
1. `git pull` the latest
2. Headless-export the Xcode project via Godot
3. `xcodebuild archive` with automatic signing (Xcode will create the
   distribution cert and provisioning profile on its own using the signed-in
   Apple ID)
4. `xcodebuild -exportArchive` → signed `.ipa`
5. `xcrun altool --upload-app` to TestFlight

Expect ~5-7 minutes. The first run is slowest because Xcode has to generate
the cert.

### 5. Confirm success
The script prints a success block when the upload returns 0. Tell the user
to check **App Store Connect → My Apps → Smash Breaker → TestFlight** in
~10-30 minutes. The build will appear with status "Processing", then
"Ready to Submit".

## Common issues and how to fix them

| Symptom | Fix |
|---|---|
| `xcodebuild: error: code signing is required` | Xcode isn't signed in. Open Xcode, Settings → Accounts → add Apple ID. |
| `No profiles for 'studio.strawhat.smashbreaker' were found` | `-allowProvisioningUpdates` should fix it; if not, in Xcode open the project once and enable "Automatically manage signing". |
| `altool: Asset validation failed: Invalid Provisioning Profile` | Bundle ID mismatch — check `BUNDLE_ID` env var matches the App Store Connect app exactly. |
| `Could not find module ...` during Godot export | Re-run bootstrap — it reinstalls the iOS template idempotently. |
| Hermes-side: any password prompt | Ask the user. Don't attempt to bypass macOS authentication prompts. |

## For subsequent releases

Once the Mac is set up, each new release from the user is just:
```bash
cd ~/work/SmashBreaker
./mac/release_ios.sh
```

`release_ios.sh` pulls latest from git before building, so the user pushes a
commit on Windows and tells you "ship it".

## Don't do these things

- Don't commit `.p8` files, certs, or the keystore to the repo.
- Don't run `sudo` unless an installer specifically asks. macOS gates a lot
  behind GUI auth that you can't supply remotely.
- Don't try to submit-for-review automatically. TestFlight upload is fine;
  Production submission requires screenshots and a "what's new" review and
  the user does that in App Store Connect.

End of briefing.
