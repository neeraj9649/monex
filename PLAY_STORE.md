# MONEX — Google Play submission pack

Everything needed to fill in the Play Console. Copy the text blocks verbatim.

---

## 1. App identity

| Field | Value |
|---|---|
| **Package name (applicationId)** | `com.versai.founderfinance` |
| App name (max 30 chars) | `MONEX – Finance Manager` |
| Default language | English (India) — `en-IN` |
| App or game | App |
| Free or paid | Free |
| Category | Finance |
| Contact email | `nv8667172@gmail.com` |
| Website | `https://m.versai.in` |
| Version name / code | `1.0.0` / `1` (from `pubspec.yaml` `version: 1.0.0+1`) |

> The package name is **permanent**. Once `com.versai.founderfinance` is
> uploaded it can never be changed or reused, even if you delete the app.

**Signing key:** `android/app/upload-keystore.jks`, alias `MONEX_UP`, referenced
by `android/key.properties`.

> Back this keystore up somewhere you will still have in five years. If you
> lose it you cannot ship an update to this listing, ever. It is gitignored, so
> it is **not** in your public GitHub repo — do not "fix" that.

---

## 2. Required URLs

All three are live on your server and reachable without signing in.

| Play Console field | URL |
|---|---|
| Privacy policy | `https://m.versai.in/privacy-policy` |
| Account deletion | `https://m.versai.in/delete-account` |
| Terms (optional, use in listing) | `https://m.versai.in/terms` |

Verify each returns real HTML after you deploy:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://m.versai.in/privacy-policy
curl -s -o /dev/null -w "%{http_code}\n" https://m.versai.in/delete-account
curl -s -o /dev/null -w "%{http_code}\n" https://m.versai.in/terms
```

Each must return `200`. If you get the Flutter app instead of the policy text,
the routes were registered after the SPA catch-all.

---

## 3. Store listing text

### Short description (max 80 characters — this is 69)

```
Track business and personal money, loans, EMIs and bank transactions.
```

### Full description (max 4000 characters)

```
MONEX is a finance manager built for founders and small business owners who
have to keep personal and company money straight.

RECORD EVERY RUPEE
Log income, expenses and transfers in seconds. Split every entry between your
personal and company books, so you always know which side of the business a
cost belongs to.

ACCOUNTS AND PAYMENT METHODS
Track bank accounts, credit cards, UPI, wallets and cash side by side. See
balances, credit limits and outstanding amounts in one place.

LOANS AND EMIs
Record loans with principal, interest rate, tenure and EMI. MONEX builds the
amortisation schedule for you and tracks how many instalments are left.

BANK MESSAGE IMPORT (optional, Android)
Turn on bank SMS import and MONEX detects the amount, direction, bank, account
number and counterparty from bank transaction messages already on your phone.
Every detected transaction is queued for your approval — nothing is written to
your books until you confirm it. Messages are read and processed entirely on
your device and are never uploaded anywhere.

PEOPLE, PAYABLES AND RECEIVABLES
Keep a ledger per person. Know exactly who owes you and who you owe, without
scrolling through chat history.

REPORTS THAT MAKE SENSE
Category breakdowns, monthly trends and personal versus company splits, in
Indian number format.

BUILT FOR PRIVACY
- Lock the app with your fingerprint or device screen lock
- Passwords stored only as bcrypt hashes, never in readable form
- No ads, no trackers, no selling your data
- Delete your account and all data from inside the app at any time

MONEX records the figures you enter or approve. It is a bookkeeping tool, not
financial, tax or legal advice, and detected transactions should always be
checked against your bank statement.

Questions or help: nv8667172@gmail.com
```

### Graphics you must supply (I cannot generate images)

| Asset | Size | Notes |
|---|---|---|
| App icon | 512 × 512 PNG, 32-bit | No transparency, no rounded corners |
| Feature graphic | 1024 × 500 PNG/JPG | Shown at top of listing, required |
| Phone screenshots | min 2, max 8 | 16:9 or 9:16, min 320px, max 3840px |
| 7-inch tablet | optional | Only if you declare tablet support |

Good screenshot set: Dashboard, Transactions list, Add transaction, Loans/EMI,
Bank imports review queue, Settings showing the fingerprint lock.

---

## 4. Data safety form

Play Console → App content → Data safety.

**Does your app collect or share any of the required user data types?** → Yes

**Is all of the user data collected by your app encrypted in transit?** → Yes
(HTTPS)

**Do you provide a way for users to request that their data is deleted?** → Yes
→ URL `https://m.versai.in/delete-account`

### Data types to declare

| Data type | Collected | Shared | Purpose | Optional? |
|---|---|---|---|---|
| Name | Yes | No | App functionality, Account management | Required |
| Email address | Yes | No | App functionality, Account management | Required |
| Phone number | Yes | No | App functionality | Optional |
| **User payment info** | No | No | — | — |
| **Purchase history** | No | No | — | — |
| **Other financial info** | Yes | No | App functionality | Required |
| App interactions | No | No | — | — |
| Location | No | No | — | — |
| **SMS or MMS** | **No** | No | — | — |

### Why SMS is declared "not collected"

Play defines *collected* as transferred off the device. MONEX parses bank SMS
**on the device** and never transmits message content to any server. Only the
resulting transaction fields that you explicitly approve are saved.

Say exactly this if asked:

```
MONEX reads bank transaction SMS locally on the device to detect transaction
amount, type, bank and account. Message content is never transmitted off the
device, never stored on our servers, and never shared with third parties. Only
the financial fields of transactions the user explicitly approves are saved to
their account.
```

"Other financial info" covers the balances, loans and transactions users enter.

---

## 5. SMS Permissions Declaration — the risky part

**Read this before you submit.** `READ_SMS` and `RECEIVE_SMS` are restricted
permissions. Play grants them mainly to apps that are the device's **default
SMS handler**. MONEX is not, so you are relying on an exception that is
frequently refused for finance apps. Expect rejection to be the likely outcome,
and note that repeated policy rejections can put the developer account at risk.

If it is refused, the app still works: the paste-and-parse flow on the Bank
Imports screen uses the same parser and needs no permission. Removing the two
`uses-permission` lines from `android/app/src/main/AndroidManifest.xml` and
rebuilding produces a compliant build.

### Declaration form answers

**Which core feature requires this permission?**

```
Automatic bank transaction import.
```

**Describe the core functionality:**

```
MONEX is a personal and business finance manager. Its core feature is
maintaining an accurate ledger of the user's bank transactions.

With the user's explicit opt-in, MONEX reads bank transaction SMS already on
the device to extract the transaction amount, debit or credit direction, bank
name, masked account number, closing balance and counterparty. Each detected
transaction is presented in a review queue and is only added to the user's
ledger after the user approves it.

Without SMS access the user must retype every bank transaction by hand, which
is the primary problem the app exists to solve for users in India, where bank
transaction alerts are delivered by SMS rather than by a standard API.

All parsing happens on device. Message content is never uploaded to our
servers, never stored remotely, and never shared with any third party. Messages
that are not bank transaction alerts, including one time passwords and personal
messages, are discarded immediately and never leave the device.

The feature is off by default, is enabled by an explicit toggle in Settings,
and can be revoked at any time from Android settings without affecting the rest
of the app.
```

**Is there a less sensitive alternative?**

```
We ship a manual alternative: users can paste bank message text into the app
and it is parsed by the same engine. This is retained as a fallback. It is not
sufficient as the only option because it requires the user to open their SMS
app, copy each message and paste it individually, which defeats the purpose of
automatic bookkeeping.
```

You must also supply a **demo video** (unlisted YouTube link) showing:
1. Settings → toggling "Automatic bank SMS import" on and the permission prompt
2. A bank SMS arriving
3. It appearing in the Bank Imports review queue
4. Approving it and the transaction appearing in the ledger

---

## 6. Other Play Console sections

### App access
The whole app is behind a login, so reviewers need credentials. Provide:

```
Username: <a real account you create for review>
Password: <that account's password>
Notes: Sign in with the credentials above. Bank SMS import is under
Settings > Automatic bank SMS import. A test bank SMS can be pasted on the
Bank Imports screen to see the detection and approval flow.
```

> Create a **separate throwaway account** for this. Do not give reviewers your
> real admin login.

### Financial features declaration
Finance-category apps must complete this. MONEX is a bookkeeping tool, not a
lender or payment processor, so select:

- Personal loans → **No**
- Lending / credit → **No**
- Payments / money transfer → **No**
- Cryptocurrency → **No**
- Only "personal finance management / budgeting" applies

### Content rating (IARC questionnaire)
Category: Utility / Productivity. Answer **No** to every question about
violence, sexuality, language, controlled substances, gambling and user
interaction. Expected outcome: **Everyone / 3+**.

### Target audience
Age groups: **18 and over**. Not designed for children — this keeps you out of
the Families policy programme, which matters for a finance app.

### Ads
Contains ads: **No**.

---

## 7. Build and upload

```bash
# 1. Rebuild the Flutter web assets the server hosts
flutter build web --release --no-tree-shake-icons
cp -R build/web/. server/public/

# 2. Build the signed bundle Play requires
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab`.

Confirm before uploading that the declared permissions are exactly these:

```bash
flutter build apk --release
~/Library/Android/sdk/build-tools/36.1.0/aapt2 dump permissions \
  build/app/outputs/flutter-apk/app-release.apk
```

Expected: `INTERNET`, `RECEIVE_SMS`, `READ_SMS`, `USE_BIOMETRIC`,
`USE_FINGERPRINT`, and the auto-generated
`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. Anything else — especially
`ACCESS_COARSE_LOCATION` — means a plugin re-introduced a permission and you
will be asked to justify it.

For every later release, bump `version:` in `pubspec.yaml` (for example
`1.0.1+2`). Play rejects a bundle whose versionCode already exists.

---

## 8. Server deployment for this release

The deletion API, purge job and policy pages are new server code.

1. Push and redeploy on Hostinger.
2. The `users.deletion_requested_at` column is added automatically by the
   startup migration.
3. Add a daily cron job in hPanel → Advanced → **Cron Jobs** so the 30-day
   purge runs even if the Node process restarts:

```bash
cd ~/domains/m.versai.in/public_html && node server/src/purge-accounts.js
```

Schedule: once daily. The server also runs the purge at boot and every 24h,
but shared hosting can idle the process, so the cron job is the dependable one.

---

## 9. Pre-submission checklist

- [ ] Keystore backed up outside this machine
- [ ] `/privacy-policy`, `/delete-account`, `/terms` all return 200
- [ ] Reviewer test account created and working
- [ ] Deletion tested end to end: request → pending banner → cancel
- [ ] Cron job added for `purge:accounts`
- [ ] Screenshots and feature graphic prepared
- [ ] Demo video recorded for the SMS declaration
- [ ] `flutter analyze` clean and `flutter test` passing
- [ ] Accepted the risk that the SMS declaration may be refused
