# Release secrets & build defines

Release CI **must not** rely on a committed `.env`. Config is injected with
`--dart-define` from GitHub Secrets / Variables.

## Required repository secrets

| Secret | Used by | Purpose |
|--------|---------|---------|
| `API_BASE_URL` | Android + iOS release | Backend base URL including `/api/v1` |
| `SUPABASE_URL` | Android + iOS release | Supabase project URL |
| `SUPABASE_PUBLISHABLE_KEY` | Android + iOS release | Supabase anon/publishable key |
| `GOOGLE_WEB_CLIENT_ID` | Android + iOS release | Google Sign-In web client (optional empty) |
| `GOOGLE_IOS_CLIENT_ID` | Android + iOS release | Google Sign-In iOS client (optional empty) |
| `ANDROID_KEYSTORE_BASE64` | Android release | Base64-encoded upload keystore |
| `ANDROID_STORE_PASSWORD` | Android release | Keystore password |
| `ANDROID_KEY_PASSWORD` | Android release | Key password |
| `ANDROID_KEY_ALIAS` | Android release | Key alias |
| `PLAY_STORE_SERVICE_ACCOUNT_JSON` | Android release | Play Console service account |
| `IOS_DIST_CERTIFICATE_BASE64` | iOS release | Distribution cert (p12) |
| `IOS_CERTIFICATE_PASSWORD` | iOS release | p12 password |
| `IOS_PROVISIONING_PROFILE_BASE64` | iOS release | App Store profile |
| `IOS_KEYCHAIN_PASSWORD` | iOS release | Temporary CI keychain |
| `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_CONTENT` | iOS deliver | App Store Connect API key |

## Variables

| Variable | Purpose |
|----------|---------|
| `APP_STORE_ID` | Numeric App Store ID for force-update deep links |

## Local release dry-run

```bash
flutter build appbundle --release \
  --obfuscate --split-debug-info=build/symbols \
  --dart-define=APP_ENV=prod \
  --dart-define=API_BASE_URL=https://api.example.com/api/v1 \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=... \
  --dart-define=ENABLE_DEBUG_LOGS=false
```

## Play track

Android CI publishes to the **internal** track. Promote to production from
Play Console after QA.
