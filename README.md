# MONEX

A responsive Flutter finance-management app for founders who need one place for personal finances, company finances, income, loans, EMIs, payables, receivables, accounts, budgets, reports, reminders, documents, and exports.

## What Is Implemented

- Cross-platform Flutter scaffold for Android, iOS, web, macOS, Windows, and Linux.
- Riverpod state management with API-first production data access.
- GoRouter navigation with browser-friendly URLs and working detail routes.
- Email/password registration, login, forgot-password, and reset-password API wiring.
- Responsive Material 3 UI with mobile bottom navigation and desktop navigation rail.
- Dashboard KPIs, reminders, recent ledger activity, and `fl_chart` charts.
- Functional transaction-entry form for expense, income, transfer, EMI payment, money borrowed, money lent, repayment, and receivable collection.
- Typed paise-based money handling for financial safety, Indian rupee formatting, DD/MM/YYYY dates, UPI, GST, and Indian financial-year assumptions.
- Loan and EMI calculations with generated schedules and tests.
- Data-backed modules for personal expenses, company expenses, income, accounts, loans, EMI calendar, people ledgers, payables, receivables, reports, budgets, recurring transactions, reminders, documents, search, settings, profile, and backup/export.
- Light and dark theme definitions, validation, status badges, empty/error surfaces, and clean production startup with no sample records.

## Architecture

The project follows a feature-first clean architecture shape:

- `lib/core`: calculations, responsive breakpoints, API/local storage boundaries, formatting, and errors.
- `lib/config`: reserved for environment and product constants.
- `lib/routing`: GoRouter routes and navigation metadata.
- `lib/theme`: centralized Material 3 theme and semantic finance colors.
- `lib/shared`: domain models, Riverpod providers, and reusable widgets.
- `lib/features`: feature presentation screens split by finance area.

The app starts with an empty workspace. Production authentication, profile, accounts, categories, loans, and transactions use the Node/MySQL backend. Local data mode is disabled by default and is only available for development builds that explicitly pass `--dart-define=ALLOW_LOCAL_DATA=true`.

## Database Schema

The domain schema is represented by typed Dart models:

- `UserProfile`: founder profile, contact, currency, company.
- `Business`: company, GSTIN, financial-year start.
- `Account`: bank, cash, credit card, UPI, wallet, company bank, investment, balances, limits.
- `FinanceTransaction`: type, scope, amount in paise, account links, category, payment method, date, due date, status, GST, vendor, invoice, person, recurrence, audit metadata.
- `TransactionCategory`: personal/company categories and subcategories.
- `Person`, `Vendor`: ledger and supplier identities.
- `Loan`: lender, principal, interest, tenure, EMI, paid count, progress.
- `Payment`, `Payable`, `Receivable`: partial repayment and collection history.
- `Budget`: category/project/account budget amounts, usage, forecast fields.
- `RecurringTransaction`, `Reminder`, `Attachment`, `Tag`: scheduling, notifications, documents, and metadata.

## Packages Used

- `flutter_riverpod`: state management and dependency injection.
- `go_router`: deep links, browser refresh, back/forward navigation.
- `intl`: Indian currency and date formatting.
- `fl_chart`: dashboard and report charts.
- `uuid`: UUID identifiers for new records.
- `shared_preferences`: development-only local persistence boundary.
- `dio`: production API client.
- `flutter_secure_storage`: secure session token storage.

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://m.versai.in
```

For web:

```bash
flutter run -d chrome
```

## Test And Analyze

```bash
dart format lib test
flutter analyze
flutter test
```

## Build

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://m.versai.in
flutter build ios --release
flutter build web --release
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## Web Deployment

For Hostinger Node + MySQL deployment, use [HOSTINGER_DEPLOY.md](HOSTINGER_DEPLOY.md).

Firebase Hosting:

```bash
flutter build web --release
firebase deploy
```

Netlify:

```bash
flutter build web --release
netlify deploy --prod --dir build/web
```

Vercel:

```bash
flutter build web --release
vercel --prod
```

Nginx:

```bash
flutter build web --release
cp -R build/web/* /usr/share/nginx/html/
```

Apache:

```bash
flutter build web --release
cp -R build/web/* /var/www/html/
cp web/.htaccess /var/www/html/.htaccess
```

## Feature Checklist

- Splash, login, onboarding, dashboard: implemented.
- Transactions, add transaction, detail, edit route: implemented.
- Personal expenses, company expenses, income: implemented.
- Accounts and account detail: implemented.
- Loans, loan detail, EMI schedule, EMI calendar: implemented.
- Money I owe, money owed to me, person ledger: implemented.
- Reports, budgets, recurring transactions, reminders: implemented.
- Receipt manager, search, settings, profile, backup/export: implemented.
- Unit tests for financial calculations and widget smoke test: implemented.

## Production Notes

Before a full commercial launch, create the Android release keystore, configure Hostinger MySQL environment variables, and add real attachment upload/storage, push notifications, and export file generation for PDF/CSV/XLSX behind the existing screens.
