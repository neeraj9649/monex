# Hostinger Node + MySQL Deployment

This project is structured for Hostinger as one Node app:

- Node/Express serves the Flutter web files from `server/public`.
- Node/Express exposes real API routes under `/api/*`.
- Hostinger MySQL stores real transaction data.
- The Flutter app starts with an empty production workspace. No demo accounts, transactions, loans, categories, reminders, or people are loaded.

## 1. Create MySQL Database In Hostinger

In Hostinger hPanel:

1. Open **Databases**.
2. Create a MySQL database.
3. Create a database user and password.
4. Copy:
   - MySQL host
   - Database name
   - Username
   - Password
   - Port, usually `3306`

## 2. Configure Server Environment

Upload `server/.env.example` as `server/.env` and set:

```bash
NODE_ENV=production
PORT=3000
APP_ORIGIN=https://your-domain.com
DATABASE_URL=mysql://USER:PASSWORD@HOST:3306/DATABASE
JWT_SECRET=use-a-long-random-secret
AUTO_MIGRATE=true
ADMIN_EMAIL=your-login-email@example.com
ADMIN_PASSWORD=your-strong-password
SMTP_HOST=smtp.hostinger.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=no-reply@your-domain.com
SMTP_PASSWORD=your-mailbox-password
SMTP_FROM="MONEX <no-reply@your-domain.com>"
```

Do not commit or expose the real `.env`.

## 3. Build Flutter For Hosted API Mode

From the project root:

```bash
flutter pub get
flutter build web --release \
  --no-tree-shake-icons
```

If your API is hosted on a different subdomain, also pass:

```bash
--dart-define=API_BASE_URL=https://api.your-domain.com
```

Copy the generated Flutter web build into the Node public folder:

```bash
mkdir -p server/public
cp -R build/web/. server/public/
```

## 4. Install Node Dependencies

If you import or upload the full repository, run this from the repository root:

```bash
npm install --omit=dev
```

The root `package.json` starts the backend from `server.js`.

## 5. Run Database Migration

From the repository root:

```bash
npm run db:migrate
```

This creates empty production tables:

- `users`
- `accounts`
- `categories`
- `loans`
- `transactions`
- `password_reset_tokens`

It also creates the first admin user from `ADMIN_EMAIL` and `ADMIN_PASSWORD` when those variables are set. It does not create sample accounts or transactions.

If you already ran an older migration and want to remove placeholder accounts, run this once in phpMyAdmin or the Hostinger MySQL console:

```sql
DELETE FROM transactions
WHERE account_id IN ('acc-main-bank', 'acc-company-bank', 'acc-upi')
   OR to_account_id IN ('acc-main-bank', 'acc-company-bank', 'acc-upi');

DELETE FROM accounts
WHERE id IN ('acc-main-bank', 'acc-company-bank', 'acc-upi');
```

## 6. Configure Hostinger Node App

In Hostinger hPanel:

1. Open **Websites**.
2. Select your domain.
3. Open **Advanced** or **Node.js**.
4. Create/enable a Node.js app.
5. Set application root to the repository root.
6. Set startup file to:

```text
server.js
```

7. Set Node version 18 or newer.
8. Set build command to:

```text
npm run build
```

9. Set start command to:

```text
npm start
```

10. Leave output directory empty. This is a Node app, not static hosting.
11. Add the environment variables from `server/.env`.
12. Start or restart the Node app.

The deployment must use these routes:

```text
Application root: ./
Startup file: server.js
Start command: npm start
Build command: npm run build
Public files served from: server/public
```

## 7. Verify

Open:

```text
https://your-domain.com/api/health
```

Expected result:

```json
{"ok":true,"database":"connected"}
```

If the website shows `503 Service Unavailable`, open Hostinger runtime logs first. The most common causes are:

- Startup file is not `server.js`.
- Required environment variables are missing, especially `DATABASE_URL` and `JWT_SECRET`.
- The Node app was deployed but not started/restarted.
- The domain is connected to static hosting instead of the Node app.

You can also check:

```text
https://your-domain.com/api/runtime
```

Then open:

```text
https://your-domain.com
```

Sign in to MONEX with `ADMIN_EMAIL` and `ADMIN_PASSWORD`.

Auth endpoints available after deployment:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`

Production data endpoints available after deployment:

- `GET /api/accounts`
- `POST /api/accounts`
- `GET /api/categories`
- `POST /api/categories`
- `GET /api/loans`
- `POST /api/loans`
- `GET /api/transactions`
- `POST /api/transactions`

## Important

The app uses the production backend by default. For same-domain Hostinger hosting, this is enough:

```bash
flutter build web --release --no-tree-shake-icons
```

For Android and iOS builds, pass the hosted API origin:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://m.versai.in
```

Local data mode is disabled by default. Only development builds can enable it with:

```bash
--dart-define=ALLOW_LOCAL_DATA=true
```
