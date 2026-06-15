# iOS via GitHub Actions — Windows-only Setup

After this is done, every iOS release is:

```bash
git tag v1.0.3 && git push origin v1.0.3
```

→ ~7 minutes later, a new build appears in TestFlight. No Mac needed.

---

## ⚠️ Prerequisites

- **Apple Developer Program** membership (active, $99/yr) — if not enrolled
  yet, do that at https://developer.apple.com/programs/ before continuing.
  Enrolment can take 1-2 days.
- Bundle ID `studio.strawhat.smashbreaker` registered in
  Certificates → Identifiers → App IDs (already done if you've reached the
  App Store Connect "New App" step).
- An app shell created in App Store Connect (also done).

Apple Team ID: **`3HXZ723KGD`** (already baked into the export preset).

---

## Step 1 — Create a second private GitHub repo for certificates

Name it something like **`SmashBreaker-Certs`**. Leave it empty. This is
where fastlane `match` will store your distribution certificate and
provisioning profile, encrypted at rest.

## Step 2 — Generate an App Store Connect API key

This is the credential GitHub Actions uses to upload to TestFlight.

1. https://appstoreconnect.apple.com → **Users and Access** →
   **Integrations** tab → **App Store Connect API**
2. Click **Generate API Key**
3. Name: `CI Upload`, Access: **App Manager**
4. Download the `.p8` file — **only downloadable once**, save it
   somewhere safe (filename is `AuthKey_XXXXXXXXXX.p8`)
5. From the same page, note:
   - **Issuer ID** (UUID at the top of the page)
   - **Key ID** (the 10-character ID for this key)

## Step 3 — Create a GitHub personal access token

For fastlane match to read/write the certificates repo.

1. https://github.com/settings/tokens → **Generate new token (classic)**
2. Name: `fastlane-match-smashbreaker`, Expiration: **1 year**
3. Scope: just **`repo`**
4. Generate. **Copy the token now** — it's only shown once.

Then compute the Basic auth string in PowerShell:

```powershell
[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("altafhssn:ghp_yourtoken_here"))
```

That long base64 string becomes the `MATCH_GIT_BASIC_AUTHORIZATION` secret.

## Step 4 — Add secrets to the ballbreaker3D repo

GitHub → ballbreaker3D → **Settings** → **Secrets and variables** →
**Actions** → **New repository secret**. Add each of these:

| Secret name | Value |
|---|---|
| `APPLE_TEAM_ID` | `3HXZ723KGD` |
| `ASC_ISSUER_ID` | The issuer UUID from step 2 |
| `ASC_KEY_ID` | The 10-character key ID from step 2 |
| `ASC_KEY_BASE64` | The `.p8` file contents, base64-encoded (see below) |
| `MATCH_GIT_URL` | `https://github.com/altafhssn/SmashBreaker-Certs.git` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | The base64 string from step 3 |
| `MATCH_PASSWORD` | A strong passphrase you invent — encrypts the certs in the match repo. Save it: if lost, regenerate the cert. |

To base64-encode the `.p8` file in PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\AuthKey_XXXXXXXXXX.p8"))
```

Paste the (multi-line) output as `ASC_KEY_BASE64`.

## Step 5 — Trigger the first build

Easiest way to see the log live: GitHub → ballbreaker3D → **Actions** tab
→ **iOS Release** workflow (left sidebar) → **Run workflow** button.

What this first run does:

1. Downloads Godot 4.6.2 and the iOS export template (~3 min)
2. Exports the Xcode project from the Godot project
3. fastlane `match` sees an empty certificates repo, **automatically
   generates the distribution cert + provisioning profile**, commits them
   to the certs repo encrypted with your `MATCH_PASSWORD`
4. `xcodebuild` archives and signs the `.ipa`
5. `altool` uploads to TestFlight via the API key

Expected total: **~10 minutes first run**, **~6-7 minutes** thereafter.

## Step 6 — Confirm in App Store Connect

Within ~10-30 minutes of the workflow finishing, the build will appear at:

**appstoreconnect.apple.com → My Apps → Smash Breaker → TestFlight**

First with status "Processing", then "Ready to Submit". Install it on your
phone via the TestFlight app to sanity-check before promoting to production.

---

## Per-release flow from here on

```bash
cd "C:\Users\altaf\OneDrive\Documents\Ball Breaker 3D"
git commit -am "v1.0.3: changes"
git tag v1.0.3
git push origin v1.0.3
```

The tag push triggers the workflow. fastlane auto-bumps the build number
based on the latest TestFlight build, so the "build number already used"
error can't happen.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `match: error authenticating with git` | Re-derive `MATCH_GIT_BASIC_AUTHORIZATION`. Format is `username:token` base64'd, NO newline. The token needs `repo` scope. |
| `No code signing identity` | API key probably has wrong access level. Recreate with **App Manager**. |
| `Invalid Provisioning Profile` | Bundle ID mismatch. Confirm `BUNDLE_ID` in the workflow matches the App ID in Apple Developer + the app in App Store Connect. |
| `Could not find module ...` during Godot export | Re-run the workflow — the iOS template cache may have been corrupted between runs. |
| `match Password: ` prompt in logs | `MATCH_PASSWORD` secret isn't set. Set it. |
| Workflow runs but `.p8` missing | `ASC_KEY_BASE64` is missing or wrong. The base64 must decode to the literal `.p8` file (with the `-----BEGIN PRIVATE KEY-----` header). |

---

## What CI does **not** do

- Screenshots, app description, keywords → manual in App Store Connect web UI
- Production submission (Submit for Review) → manual; the CI only sends
  builds to TestFlight, you promote one to production when ready
