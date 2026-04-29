# Plan: Add Android (Google Play) deploy to codemagic.yaml

## Context

`codemagic.yaml` currently only has an iOS workflow that ships to TestFlight. We want to add a parallel Android workflow that ships to Google Play. Today the Android side is **not deploy-ready**:

- `android/app/build.gradle.kts:37` still signs release with the **debug** keystore ("Signing with the debug keys for now")
- No `android/key.properties`, no `.jks` keystore in the repo
- No fastlane, no GitHub Actions, no Android logic in `deploy.sh`

So this plan has two halves: **(A) what you need to gather/create** outside the codebase, and **(B) what changes go into `codemagic.yaml` and `android/app/build.gradle.kts`** once you have them.

---

## A. What you need (and where to get it)

Your current state: Play Console developer account already, app **not yet created** in Play Console, keystore not yet generated, target track is **beta (open testing)**.

So the order of operations is:

1. Generate keystore locally (A1)
2. Build a signed `.aab` locally to sanity-check the keystore (B1 + `flutter build appbundle --release`)
3. Create the app in Play Console + upload that first `.aab` manually (A3) — Google Play requires this; the API refuses the very first upload
4. Create the service account JSON (A2)
5. Upload keystore + JSON to Codemagic (last bullets of A1 and A2)
6. Add the `android-release` workflow to `codemagic.yaml` (B2)
7. Push to `main`; Codemagic ships every subsequent build to the **beta** track

Android deployment needs **two credentials** — analogous to iOS's signing cert + App Store Connect API key:

### A1. Upload keystore (`.jks`) — the Android equivalent of an iOS distribution certificate

This is a file **you create yourself, once**, and then guard forever. Google Play uses it to verify that uploaded builds are really from you.

**How to create it** (run locally on your Mac, one time):
```bash
keytool -genkey -v -keystore ~/spygame-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
It will ask for a keystore password, a key password (use the same to keep things simple), and your name/org. Keep the `.jks` file and both passwords in your password manager — **if you lose them you cannot publish updates** (you'd have to use Play's key reset flow, which is slow).

**How to give it to Codemagic:**
- Codemagic UI → your app → **Code signing identities** → **Android keystores** → Upload `.jks`
- Set: **Reference name** (e.g. `spygame_upload`), **Keystore password**, **Key alias** (`upload`), **Key password`
- This reference name is what we'll plug into `codemagic.yaml` under `android_signing:`

### A2. Google Play service account JSON — the Android equivalent of your App Store Connect API key

This lets Codemagic upload builds to the Play Console on your behalf.

**Prerequisite:** Same Google Play Console developer account, **and the app must already exist there with at least one build manually uploaded.** Google Play API will not accept the very first upload — see A3 below for that one-time step.

**How to create the JSON:**
1. **Google Cloud Console** → create or pick a project → **IAM & Admin** → **Service Accounts** → **Create service account** (any name, e.g. `codemagic-publisher`)
2. On that service account → **Keys** → **Add key** → **Create new key** → **JSON** → download it. Treat this file like a password.
3. **Google Play Console** → **Users and permissions** → **Invite new user** → paste the service account's email (looks like `codemagic-publisher@your-project.iam.gserviceaccount.com`) → grant app permissions: **Release to production / testing tracks** + **View app information**.
4. Wait ~5 minutes for Play to propagate access.

**How to give it to Codemagic:**
- Codemagic UI → top-right avatar → **Teams** → (your team) → **Integrations** → **Google Play** → paste the JSON
- Give the integration a name (e.g. `GooglePlayPublisher`) — same idea as `XcodeAdminAPIKeyTeamMCK` for iOS

### A3. One-time manual first upload to Play Console

Google Play's API refuses the very first build for a brand-new app. So:

1. **Play Console** → **Create app** — package name **must** be `com.walhallaa.spygame.v02202404` (matches `android/app/build.gradle.kts:9,24`). Fill in the basic store listing (title, short/full description, category, content rating, privacy policy URL, target audience, data safety form). Play won't let you publish without these; they're tedious but one-time.
2. Build a signed `.aab` locally once after you've done step B1 below:
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`
3. **Play Console** → your app → **Testing** → **Open testing** → **Create new release** → drop the `.aab` → roll it out.
4. After this, the Play API will accept further uploads — Codemagic takes over from the next push to `main`.

### A4. (Implicit) Bundle / package name
Already set: `com.walhallaa.spygame.v02202404` (`android/app/build.gradle.kts:9,24`). This must match the package you registered in Play Console step above.

---

## B. Code changes (after you have the items above)

### B1. `android/app/build.gradle.kts` — wire up real release signing

Replace the debug-signing placeholder at line 37. Standard pattern: read `key.properties` if present, otherwise fall back to debug (so local `flutter run` still works without the keystore):

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = if (keystoreProperties.isNotEmpty())
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}
```

`android/key.properties` and `*.jks` must be in `.gitignore` (Codemagic writes them at build time from the keystore reference).

### B2. `codemagic.yaml` — add `android-release` workflow

Mirrors the iOS workflow's structure (Rust → pub get → codegen → build → publish). Note: **Rust install is still needed on Android** because `convex_flutter` uses cargokit on both platforms; the target triples differ (`aarch64-linux-android`, `armv7-linux-androideabi`, `x86_64-linux-android` instead of `aarch64-apple-ios`).

```yaml
  android-release:
    name: Android Release (Google Play)
    instance_type: mac_mini_m2   # or linux_x2 — cheaper, fine for Android
    max_build_duration: 60

    integrations:
      google_play: GooglePlayPublisher   # <-- name from step A2

    environment:
      android_signing:
        - spygame_upload                 # <-- reference name from step A1
      flutter: stable
      java: 17

    triggering:
      events: [push]
      branch_patterns:
        - pattern: main
          include: true
          source: true

    scripts:
      - name: Install Rust toolchain (cargokit)
        script: |
          curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal
          source "$HOME/.cargo/env"
          rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
          echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$CM_ENV"

      - name: Flutter pub get
        script: flutter pub get

      - name: Codegen
        script: dart run build_runner build --delete-conflicting-outputs

      - name: Flutter build appbundle
        script: flutter build appbundle --release

    artifacts:
      - build/app/outputs/bundle/release/*.aab
      - build/app/outputs/mapping/release/mapping.txt

    publishing:
      google_play:
        credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS  # auto-injected by integration
        track: beta         # open testing — anyone with the opt-in link can install
```

`track: beta` matches what you asked for. Anyone with the opt-in link from Play Console can install. To promote a beta build to production, do it manually in Play Console → Production → Promote release.

---

## Verification

1. Local `flutter run` still works after the build.gradle.kts change (debug fallback path).
2. `flutter build appbundle --release` locally with a real `key.properties` produces a signed `.aab`.
3. First Codemagic Android run on `main` (after the manual A3 upload) produces an artifact and uploads to Play **open testing (beta)** track.
4. Build appears in Play Console → Testing → Open testing within ~5–10 minutes.

## Critical files

- `codemagic.yaml` — add `android-release` workflow
- `android/app/build.gradle.kts` — replace debug signing with real release config
- `.gitignore` — confirm `android/key.properties` and `*.jks` are excluded
