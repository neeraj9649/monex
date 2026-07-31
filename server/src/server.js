import bcrypt from 'bcryptjs';
import cors from 'cors';
import crypto from 'node:crypto';
import dotenv from 'dotenv';
import express from 'express';
import helmet from 'helmet';
import nodemailer from 'nodemailer';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { z } from 'zod';

import { requireAuth, signToken } from './auth.js';
import { createPool } from './db.js';
import { registerMasterDataRoutes } from './master-data.js';
import { registerTransactionRoutes } from './transactions.js';

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config();
dotenv.config({ path: path.resolve(__dirname, '../.env') });
const pool = createPool();
const webRoot = path.resolve(__dirname, '../public');

app.disable('x-powered-by');
app.use(helmet({
  contentSecurityPolicy: false
}));
app.use(cors({
  origin: process.env.APP_ORIGIN?.split(',') ?? true,
  credentials: true
}));
app.use(express.json({ limit: '2mb' }));

app.get('/api/health', async (req, res, next) => {
  try {
    await pool.execute('SELECT 1');
    res.json({ ok: true, database: 'connected' });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/login', async (req, res, next) => {
  try {
    const payload = z.object({
      email: z.string().email(),
      password: z.string().min(8)
    }).parse(req.body);

    const [rows] = await pool.execute('SELECT * FROM users WHERE email = ?', [payload.email]);
    const user = rows[0];
    if (!user || !(await bcrypt.compare(payload.password, user.password_hash))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    res.json({
      token: signToken(user),
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        primaryCurrency: user.primary_currency,
        companyName: user.company_name
      }
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/register', async (req, res, next) => {
  try {
    const payload = z.object({
      name: z.string().min(2).max(160),
      email: z.string().email().max(190),
      password: z.string().min(8).max(128),
      companyName: z.string().max(190).optional().default('')
    }).parse(req.body);

    const [existing] = await pool.execute('SELECT id FROM users WHERE email = ?', [payload.email]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Account already exists' });
    }

    const userId = crypto.randomUUID();
    const passwordHash = await bcrypt.hash(payload.password, 12);
    await pool.execute(
      `INSERT INTO users (id, name, email, password_hash, company_name)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, payload.name, payload.email, passwordHash, payload.companyName]
    );

    const user = {
      id: userId,
      name: payload.name,
      email: payload.email,
      primary_currency: 'INR',
      company_name: payload.companyName
    };

    res.status(201).json({
      token: signToken(user),
      user: {
        id: userId,
        name: payload.name,
        email: payload.email,
        phone: '',
        primaryCurrency: 'INR',
        companyName: payload.companyName
      }
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/forgot-password', async (req, res, next) => {
  try {
    const payload = z.object({
      email: z.string().email().max(190)
    }).parse(req.body);

    const [rows] = await pool.execute('SELECT id, name, email FROM users WHERE email = ?', [payload.email]);
    const user = rows[0];
    if (user) {
      const token = crypto.randomBytes(32).toString('hex');
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
      const expiresAt = new Date(Date.now() + 1000 * 60 * 30);
      await pool.execute(
        `INSERT INTO password_reset_tokens (id, user_id, token_hash, expires_at)
         VALUES (?, ?, ?, ?)`,
        [crypto.randomUUID(), user.id, tokenHash, expiresAt.toISOString().slice(0, 19).replace('T', ' ')]
      );
      await sendPasswordResetEmail(user, token);
    }

    res.json({
      ok: true,
      message: 'If an account exists for this email, password reset instructions have been sent.'
    });
  } catch (error) {
    next(error);
  }
});

app.post('/api/auth/reset-password', async (req, res, next) => {
  try {
    const payload = z.object({
      token: z.string().min(32),
      password: z.string().min(8).max(128)
    }).parse(req.body);
    const tokenHash = crypto.createHash('sha256').update(payload.token).digest('hex');
    const [rows] = await pool.execute(
      `SELECT prt.id, prt.user_id
       FROM password_reset_tokens prt
       WHERE prt.token_hash = ?
         AND prt.used_at IS NULL
         AND prt.expires_at > NOW()
       LIMIT 1`,
      [tokenHash]
    );
    const reset = rows[0];
    if (!reset) {
      return res.status(400).json({ error: 'Invalid or expired reset token' });
    }

    const passwordHash = await bcrypt.hash(payload.password, 12);
    await pool.execute('UPDATE users SET password_hash = ? WHERE id = ?', [passwordHash, reset.user_id]);
    await pool.execute('UPDATE password_reset_tokens SET used_at = NOW() WHERE id = ?', [reset.id]);
    res.json({ ok: true });
  } catch (error) {
    next(error);
  }
});

async function sendPasswordResetEmail(user, token) {
  if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASSWORD) {
    console.log(`Password reset token for ${user.email}: ${token}`);
    return;
  }

  const resetUrl = `${process.env.APP_ORIGIN || ''}/reset-password?token=${token}`;
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASSWORD
    }
  });

  await transporter.sendMail({
    from: process.env.SMTP_FROM || process.env.SMTP_USER,
    to: user.email,
    subject: 'Reset your MONEX password',
    text: `Use this link to reset your password: ${resetUrl}`,
    html: `<p>Use this link to reset your password:</p><p><a href="${resetUrl}">${resetUrl}</a></p><p>This link expires in 30 minutes.</p>`
  });
}

app.use('/api', requireAuth);
registerMasterDataRoutes(app, pool);
registerTransactionRoutes(app, pool);

app.use(express.static(webRoot, {
  etag: true,
  maxAge: '1y',
  setHeaders(res, filePath) {
    if (filePath.endsWith('index.html')) {
      res.setHeader('Cache-Control', 'no-cache');
    }
  }
}));

app.get('*', (req, res) => {
  res.sendFile(path.join(webRoot, 'index.html'));
});

app.use((error, req, res, next) => {
  if (error instanceof z.ZodError) {
    return res.status(400).json({ error: 'Validation failed', details: error.flatten() });
  }
  console.error(error);
  return res.status(500).json({ error: 'Server error' });
});

const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
  console.log(`MONEX server listening on ${port}`);
});
