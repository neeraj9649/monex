/// Standalone purge runner for a Hostinger cron job.
///
/// Usage (hPanel -> Advanced -> Cron Jobs, once daily):
///   cd ~/domains/m.versai.in/public_html && node server/src/purge-accounts.js
///
/// Reads the same environment as the server, so it works whether the
/// credentials come from panel variables or server/.env.

import dotenv from 'dotenv';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { purgeExpiredAccounts } from './account-deletion.js';
import { createPool } from './db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config();
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const pool = createPool();

purgeExpiredAccounts(pool)
  .then(async (count) => {
    console.log(`MONEX purge complete: ${count} account(s) removed`);
    await pool.end();
  })
  .catch(async (error) => {
    console.error('MONEX purge failed:', error);
    await pool.end();
    process.exit(1);
  });
