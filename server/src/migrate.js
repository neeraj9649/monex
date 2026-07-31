import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createPool } from './db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config();
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const ddl = [
  `CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(160) NOT NULL,
    email VARCHAR(190) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(40),
    primary_currency VARCHAR(8) NOT NULL DEFAULT 'INR',
    company_name VARCHAR(190),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  )`,
  `CREATE TABLE IF NOT EXISTS accounts (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    name VARCHAR(190) NOT NULL,
    type VARCHAR(40) NOT NULL,
    scope VARCHAR(40) NOT NULL,
    balance_paise BIGINT NOT NULL DEFAULT 0,
    available_balance_paise BIGINT,
    credit_limit_paise BIGINT,
    outstanding_paise BIGINT NOT NULL DEFAULT 0,
    institution VARCHAR(190),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`,
  `CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    name VARCHAR(160) NOT NULL,
    scope VARCHAR(40) NOT NULL,
    type VARCHAR(60) NOT NULL,
    subcategories JSON,
    icon VARCHAR(80) NOT NULL DEFAULT 'category',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_categories_user_scope_type (user_id, scope, type),
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`,
  `CREATE TABLE IF NOT EXISTS loans (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    name VARCHAR(190) NOT NULL,
    type VARCHAR(60) NOT NULL,
    lender_name VARCHAR(190) NOT NULL,
    principal_paise BIGINT NOT NULL,
    interest_rate DECIMAL(8, 4) NOT NULL DEFAULT 0,
    start_date DATETIME NOT NULL,
    tenure_months INT NOT NULL,
    emi_paise BIGINT NOT NULL,
    emi_due_day INT NOT NULL,
    paid_emi_count INT NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_loans_user (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`,
  `CREATE TABLE IF NOT EXISTS transactions (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    type VARCHAR(60) NOT NULL,
    scope VARCHAR(40) NOT NULL,
    amount_paise BIGINT NOT NULL,
    category VARCHAR(160) NOT NULL,
    subcategory VARCHAR(160),
    payment_method VARCHAR(60) NOT NULL,
    account_id VARCHAR(64) NOT NULL,
    to_account_id VARCHAR(64),
    transaction_date DATETIME NOT NULL,
    description TEXT NOT NULL,
    tags JSON,
    location VARCHAR(255),
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(40) NOT NULL,
    business_name VARCHAR(190),
    vendor_name VARCHAR(190),
    invoice_number VARCHAR(120),
    gst_paise BIGINT,
    is_reimbursable BOOLEAN NOT NULL DEFAULT FALSE,
    paid_personally BOOLEAN NOT NULL DEFAULT FALSE,
    due_date DATETIME,
    project_or_department VARCHAR(160),
    person_id VARCHAR(64),
    created_by VARCHAR(64) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_transactions_user_date (user_id, transaction_date),
    INDEX idx_transactions_search (user_id, category, status),
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`,
  `CREATE TABLE IF NOT EXISTS password_reset_tokens (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL,
    token_hash VARCHAR(128) NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_password_reset_token_hash (token_hash),
    INDEX idx_password_reset_user (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id)
  )`
];

export async function runMigrations(pool) {
  for (const sql of ddl) {
    await pool.execute(sql);
  }

  const email = process.env.ADMIN_EMAIL;
  const password = process.env.ADMIN_PASSWORD;
  if (email && password) {
    const [existing] = await pool.execute('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length === 0) {
      const passwordHash = await bcrypt.hash(password, 12);
      await pool.execute(
        `INSERT INTO users (id, name, email, password_hash, phone, company_name)
         VALUES (?, ?, ?, ?, ?, ?)`,
        ['user-founder', 'MONEX Admin', email, passwordHash, '', 'MONEX Workspace']
      );
    }
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === __filename) {
  const pool = createPool();
  runMigrations(pool)
    .then(async () => {
      console.log('Database migration complete');
      await pool.end();
    })
    .catch(async (error) => {
      console.error(error);
      await pool.end();
      process.exit(1);
    });
}
