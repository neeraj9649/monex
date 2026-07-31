import { z } from 'zod';

const accountSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1).max(190),
  type: z.string().min(1).max(40),
  scope: z.string().min(1).max(40),
  balancePaise: z.number().int(),
  availableBalancePaise: z.number().int().nullable().optional(),
  creditLimitPaise: z.number().int().nullable().optional(),
  outstandingPaise: z.number().int().optional().default(0),
  institution: z.string().max(190).nullable().optional()
});

const categorySchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1).max(160),
  scope: z.string().min(1).max(40),
  type: z.string().min(1).max(60),
  subcategories: z.array(z.string()).optional().default([]),
  icon: z.string().max(80).optional().default('category')
});

const loanSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1).max(190),
  type: z.string().min(1).max(60),
  lenderName: z.string().min(1).max(190),
  principalPaise: z.number().int().positive(),
  interestRate: z.number().min(0),
  startDate: z.string().datetime(),
  tenureMonths: z.number().int().positive(),
  emiPaise: z.number().int().positive(),
  emiDueDay: z.number().int().min(1).max(31),
  paidEmiCount: z.number().int().min(0).optional().default(0),
  notes: z.string().optional().default('')
});

function parseJsonList(value) {
  if (typeof value === 'string') return JSON.parse(value);
  return Array.isArray(value) ? value : [];
}

function mapAccount(row) {
  return {
    id: row.id,
    name: row.name,
    type: row.type,
    scope: row.scope,
    balancePaise: Number(row.balance_paise),
    availableBalancePaise: row.available_balance_paise == null
      ? null
      : Number(row.available_balance_paise),
    creditLimitPaise: row.credit_limit_paise == null
      ? null
      : Number(row.credit_limit_paise),
    outstandingPaise: Number(row.outstanding_paise ?? 0),
    institution: row.institution
  };
}

function mapCategory(row) {
  return {
    id: row.id,
    name: row.name,
    scope: row.scope,
    type: row.type,
    subcategories: parseJsonList(row.subcategories),
    icon: row.icon || 'category'
  };
}

function mapLoan(row) {
  return {
    id: row.id,
    name: row.name,
    type: row.type,
    lenderName: row.lender_name,
    principalPaise: Number(row.principal_paise),
    interestRate: Number(row.interest_rate),
    startDate: new Date(row.start_date).toISOString(),
    tenureMonths: Number(row.tenure_months),
    emiPaise: Number(row.emi_paise),
    emiDueDay: Number(row.emi_due_day),
    paidEmiCount: Number(row.paid_emi_count ?? 0),
    notes: row.notes || ''
  };
}

export function registerMasterDataRoutes(app, pool) {
  app.get('/api/accounts', async (req, res, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT * FROM accounts WHERE user_id = ? ORDER BY created_at DESC',
        [req.user.id]
      );
      res.json({ data: rows.map(mapAccount) });
    } catch (error) {
      next(error);
    }
  });

  app.post('/api/accounts', async (req, res, next) => {
    try {
      const account = accountSchema.parse(req.body);
      await pool.execute(
        `INSERT INTO accounts
          (id, user_id, name, type, scope, balance_paise, available_balance_paise,
           credit_limit_paise, outstanding_paise, institution)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          account.id,
          req.user.id,
          account.name,
          account.type,
          account.scope,
          account.balancePaise,
          account.availableBalancePaise ?? account.balancePaise,
          account.creditLimitPaise ?? null,
          account.outstandingPaise ?? 0,
          account.institution ?? null
        ]
      );
      const [rows] = await pool.execute(
        'SELECT * FROM accounts WHERE id = ? AND user_id = ?',
        [account.id, req.user.id]
      );
      res.status(201).json({ data: mapAccount(rows[0]) });
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/categories', async (req, res, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT * FROM categories WHERE user_id = ? ORDER BY created_at DESC',
        [req.user.id]
      );
      res.json({ data: rows.map(mapCategory) });
    } catch (error) {
      next(error);
    }
  });

  app.post('/api/categories', async (req, res, next) => {
    try {
      const category = categorySchema.parse(req.body);
      await pool.execute(
        `INSERT INTO categories
          (id, user_id, name, scope, type, subcategories, icon)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          category.id,
          req.user.id,
          category.name,
          category.scope,
          category.type,
          JSON.stringify(category.subcategories ?? []),
          category.icon
        ]
      );
      const [rows] = await pool.execute(
        'SELECT * FROM categories WHERE id = ? AND user_id = ?',
        [category.id, req.user.id]
      );
      res.status(201).json({ data: mapCategory(rows[0]) });
    } catch (error) {
      next(error);
    }
  });

  app.get('/api/loans', async (req, res, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT * FROM loans WHERE user_id = ? ORDER BY created_at DESC',
        [req.user.id]
      );
      res.json({ data: rows.map(mapLoan) });
    } catch (error) {
      next(error);
    }
  });

  app.post('/api/loans', async (req, res, next) => {
    try {
      const loan = loanSchema.parse(req.body);
      await pool.execute(
        `INSERT INTO loans
          (id, user_id, name, type, lender_name, principal_paise, interest_rate,
           start_date, tenure_months, emi_paise, emi_due_day, paid_emi_count, notes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          loan.id,
          req.user.id,
          loan.name,
          loan.type,
          loan.lenderName,
          loan.principalPaise,
          loan.interestRate,
          loan.startDate.slice(0, 19).replace('T', ' '),
          loan.tenureMonths,
          loan.emiPaise,
          loan.emiDueDay,
          loan.paidEmiCount ?? 0,
          loan.notes ?? ''
        ]
      );
      const [rows] = await pool.execute(
        'SELECT * FROM loans WHERE id = ? AND user_id = ?',
        [loan.id, req.user.id]
      );
      res.status(201).json({ data: mapLoan(rows[0]) });
    } catch (error) {
      next(error);
    }
  });
}
