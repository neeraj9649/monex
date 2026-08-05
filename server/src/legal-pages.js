/// Publicly reachable policy pages.
///
/// Google Play requires a privacy policy URL and a data deletion URL that both
/// work without installing the app or signing in. These must be registered
/// before the single page app catch-all, otherwise Express would answer them
/// with index.html.

const CONTACT_EMAIL = process.env.SUPPORT_EMAIL || 'nv8667172@gmail.com';
const APP_NAME = 'MONEX';
const PUBLISHER = 'Versai Tech Solutions';
const LAST_UPDATED = '2 August 2026';

export function registerLegalRoutes(app) {
  app.get('/privacy-policy', (req, res) => send(res, privacyPolicy()));
  app.get('/terms', (req, res) => send(res, terms()));
  app.get('/delete-account', (req, res) => send(res, deleteAccount()));
}

function send(res, html) {
  res.set('Content-Type', 'text/html; charset=utf-8');
  res.set('Cache-Control', 'public, max-age=3600');
  res.send(html);
}

function page(title, body) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title} · ${APP_NAME}</title>
<style>
  :root { color-scheme: light dark; }
  body {
    margin: 0 auto; padding: 32px 20px 80px; max-width: 760px;
    font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: #14161a; background: #fff;
  }
  @media (prefers-color-scheme: dark) {
    body { color: #e8eaed; background: #14161a; }
    a { color: #8ab4f8; }
    code { background: #23262b; }
  }
  h1 { font-size: 30px; margin: 0 0 6px; }
  h2 { font-size: 20px; margin: 34px 0 10px; }
  .meta { color: #6b7280; font-size: 14px; margin-bottom: 28px; }
  ul { padding-left: 22px; }
  li { margin: 6px 0; }
  code { background: #f1f3f5; padding: 2px 6px; border-radius: 4px; font-size: 14px; }
  .box {
    border: 1px solid #d6dae0; border-radius: 10px;
    padding: 16px 18px; margin: 22px 0;
  }
  @media (prefers-color-scheme: dark) { .box { border-color: #343941; } }
  footer { margin-top: 48px; font-size: 14px; color: #6b7280; }
</style>
</head>
<body>
${body}
<footer>${APP_NAME} is operated by ${PUBLISHER}. Contact:
<a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a></footer>
</body>
</html>`;
}

function privacyPolicy() {
  return page(
    'Privacy Policy',
    `<h1>Privacy Policy</h1>
<p class="meta">Last updated ${LAST_UPDATED}</p>

<p>${APP_NAME} is a personal and business finance manager operated by
${PUBLISHER}. This policy explains what we collect, why, and how you can
remove it.</p>

<h2>Information we collect</h2>
<ul>
  <li><strong>Account information</strong> — your name, email address, optional
      phone number and company name, supplied when you register.</li>
  <li><strong>Financial information you enter</strong> — accounts, balances,
      account number fragments, categories, loans, EMI schedules and
      transactions.</li>
  <li><strong>Bank SMS content (Android only, optional)</strong> — if you
      switch on automatic bank SMS import and grant SMS permission, the app
      reads bank transaction messages already on your device in order to
      detect the amount, direction, bank, account number fragment, closing
      balance, counterparty and reference of a transaction.</li>
</ul>

<h2>How bank SMS is handled</h2>
<div class="box">
  <p><strong>SMS import is off by default and requires your explicit
  permission.</strong> You can turn it off at any time in Settings, or revoke
  SMS permission in Android settings.</p>
  <ul>
    <li>Messages are read and parsed <strong>on your device only</strong>.</li>
    <li>Raw SMS text is <strong>never uploaded</strong> to our servers and is
        never shared with any third party.</li>
    <li>Only a transaction you explicitly approve is saved, and only the
        resulting financial fields (amount, date, category, account,
        description) are stored.</li>
    <li>Messages that are not bank transactions — including one time
        passwords, personal messages and promotions — are discarded and never
        leave the device.</li>
    <li>We do not read, store or transmit SMS for advertising, profiling,
        credit scoring or any purpose other than creating the transaction you
        approve.</li>
  </ul>
</div>

<h2>How we use your information</h2>
<ul>
  <li>To provide the service: storing and displaying your finances.</li>
  <li>To authenticate you and keep your session secure.</li>
  <li>To send password reset emails when you request one.</li>
</ul>
<p>We do not sell your data. We do not use it for advertising. We do not share
it with third parties except the hosting provider that runs our servers.</p>

<h2>Storage and security</h2>
<p>Your data is stored in a private MySQL database on our hosting provider in
India. Passwords are hashed with bcrypt and are never stored in readable form.
Traffic is encrypted with HTTPS. Your session token is held in the device
secure store. The app can be locked with your fingerprint or device screen
lock.</p>

<h2>Data retention and deletion</h2>
<p>We keep your data until you delete your account. You can delete it from
inside the app under <strong>Profile &rarr; Delete account</strong>, or by
following the instructions at
<a href="/delete-account">${'https://m.versai.in/delete-account'}</a>.</p>
<p>Deletion is scheduled with a ${'30'} day grace period so an accidental
request can be undone by signing in and cancelling. After that period your
user record and all associated accounts, categories, loans, transactions and
reset tokens are permanently erased.</p>

<h2>Children</h2>
<p>${APP_NAME} is not directed at children under 13 and we do not knowingly
collect their data.</p>

<h2>Your rights</h2>
<p>You may request a copy of your data, correct it, or have it erased by
writing to <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>. We respond
within 30 days.</p>

<h2>Changes</h2>
<p>If this policy changes materially we will update this page and the date
above, and notify you in the app.</p>`
  );
}

function terms() {
  return page(
    'Terms of Service',
    `<h1>Terms of Service</h1>
<p class="meta">Last updated ${LAST_UPDATED}</p>

<h2>Using ${APP_NAME}</h2>
<p>${APP_NAME} is a personal and business finance record keeping tool provided
by ${PUBLISHER}. You need an account to use it, and you are responsible for
keeping your credentials secure and for the accuracy of what you record.</p>

<h2>Not financial advice</h2>
<p>${APP_NAME} records and summarises figures that you enter or approve. It
does not provide financial, tax, accounting or legal advice. Automatically
detected bank transactions are suggestions that require your approval and may
be incomplete or incorrect. Always check against your bank statement before
relying on any figure.</p>

<h2>Acceptable use</h2>
<ul>
  <li>Do not use ${APP_NAME} for unlawful purposes.</li>
  <li>Do not attempt to access another user's data.</li>
  <li>Do not disrupt or overload the service.</li>
</ul>

<h2>Availability</h2>
<p>We aim to keep the service running but do not guarantee uninterrupted
availability. We may change or discontinue features. Keep your own records of
anything you cannot afford to lose.</p>

<h2>Liability</h2>
<p>To the extent permitted by law, ${PUBLISHER} is not liable for indirect or
consequential loss, or for any financial decision made on the basis of data
shown in ${APP_NAME}.</p>

<h2>Termination</h2>
<p>You may delete your account at any time. We may suspend accounts that
breach these terms.</p>

<h2>Contact</h2>
<p>Questions: <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a></p>`
  );
}

function deleteAccount() {
  return page(
    'Delete your account',
    `<h1>Delete your ${APP_NAME} account</h1>
<p class="meta">Last updated ${LAST_UPDATED}</p>

<p>You can permanently delete your ${APP_NAME} account and all of the data in
it. There are two ways to do this.</p>

<h2>Option 1 — from inside the app</h2>
<ol>
  <li>Open ${APP_NAME} and sign in.</li>
  <li>Go to <strong>Profile</strong>.</li>
  <li>Tap <strong>Delete account</strong>.</li>
  <li>Confirm by typing <code>DELETE</code>.</li>
</ol>

<h2>Option 2 — by email</h2>
<p>If you cannot sign in or have already uninstalled the app, email
<a href="mailto:${CONTACT_EMAIL}?subject=MONEX%20account%20deletion%20request">
${CONTACT_EMAIL}</a> from the address registered on the account, with the
subject <strong>MONEX account deletion request</strong>. We verify ownership
and action the request within 30 days.</p>

<h2>What gets deleted</h2>
<div class="box">
  <p><strong>Permanently erased:</strong></p>
  <ul>
    <li>Your user record: name, email, phone, company name and password hash</li>
    <li>All accounts and payment methods, including stored account number
        fragments</li>
    <li>All categories, loans and EMI schedules</li>
    <li>All transactions and their descriptions, amounts and dates</li>
    <li>All password reset tokens</li>
  </ul>
  <p><strong>Not retained:</strong> we do not keep a backup copy of your
  financial records after deletion, and no bank SMS content is ever stored on
  our servers in the first place.</p>
</div>

<h2>When it happens</h2>
<p>Deletion is scheduled <strong>30 days</strong> after you request it. During
those 30 days you can undo the request by signing in and choosing
<strong>Cancel deletion</strong>. After 30 days the data is erased permanently
and cannot be recovered.</p>

<p>If you want your data removed immediately rather than after 30 days, say so
in your email and we will action it.</p>`
  );
}
