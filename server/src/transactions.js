import { z } from 'zod';

const transactionSchema = z.object({
  id: z.string().min(1),
  type: z.string().min(1),
  scope: z.string().min(1),
  amountPaise: z.number().int().positive(),
  category: z.string().min(1),
  subcategory: z.string().nullable().optional(),
  paymentMethod: z.string().min(1),
  accountId: z.string().min(1),
  toAccountId: z.string().nullable().optional(),
  date: z.string().datetime(),
  description: z.string().min(2),
  tags: z.array(z.string()).optional(),
  location: z.string().nullable().optional(),
  isRecurring: z.boolean().optional(),
  status: z.string().min(1),
  businessName: z.string().nullable().optional(),
  vendorName: z.string().nullable().optional(),
  invoiceNumber: z.string().nullable().optional(),
  gstPaise: z.number().int().nullable().optional(),
  isReimbursable: z.boolean().optional(),
  paidPersonally: z.boolean().optional(),
  dueDate: z.string().datetime().nullable().optional(),
  projectOrDepartment: z.string().nullable().optional(),
  personId: z.string().nullable().optional()
});

export function mapTransaction(row) {
  const tags = typeof row.tags === 'string'
    ? JSON.parse(row.tags)
    : Array.isArray(row.tags)
      ? row.tags
      : [];

  return {
    id: row.id,
    type: row.type,
    scope: row.scope,
    amountPaise: Number(row.amount_paise),
    category: row.category,
    subcategory: row.subcategory,
    paymentMethod: row.payment_method,
    accountId: row.account_id,
    toAccountId: row.to_account_id,
    date: new Date(row.transaction_date).toISOString(),
    description: row.description,
    tags,
    location: row.location,
    isRecurring: Boolean(row.is_recurring),
    status: row.status,
    businessName: row.business_name,
    vendorName: row.vendor_name,
    invoiceNumber: row.invoice_number,
    gstPaise: row.gst_paise == null ? null : Number(row.gst_paise),
    isReimbursable: Boolean(row.is_reimbursable),
    paidPersonally: Boolean(row.paid_personally),
    dueDate: row.due_date ? new Date(row.due_date).toISOString() : null,
    projectOrDepartment: row.project_or_department,
    personId: row.person_id,
    audit: {
      createdAt: row.created_at ? new Date(row.created_at).toISOString() : new Date().toISOString(),
      updatedAt: row.updated_at ? new Date(row.updated_at).toISOString() : new Date().toISOString(),
      deletedAt: row.deleted_at ? new Date(row.deleted_at).toISOString() : null,
      createdBy: row.created_by,
      status: row.deleted_at ? 'deleted' : 'active'
    }
  };
}

export function registerTransactionRoutes(app, pool) {
  app.get('/api/transactions', async (req, res, next) => {
    try {
      const [rows] = await pool.execute(
        `SELECT * FROM transactions
         WHERE user_id = ? AND deleted_at IS NULL
         ORDER BY transaction_date DESC, created_at DESC
         LIMIT 500`,
        [req.user.id]
      );
      res.json({ data: rows.map(mapTransaction) });
    } catch (error) {
      next(error);
    }
  });

  app.post('/api/transactions', async (req, res, next) => {
    try {
      const transaction = transactionSchema.parse(req.body);
      await pool.execute(
        `INSERT INTO transactions
          (id, user_id, type, scope, amount_paise, category, subcategory,
           payment_method, account_id, to_account_id, transaction_date,
           description, tags, location, is_recurring, status, business_name,
           vendor_name, invoice_number, gst_paise, is_reimbursable,
           paid_personally, due_date, project_or_department, person_id, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          transaction.id,
          req.user.id,
          transaction.type,
          transaction.scope,
          transaction.amountPaise,
          transaction.category,
          transaction.subcategory ?? null,
          transaction.paymentMethod,
          transaction.accountId,
          transaction.toAccountId ?? null,
          transaction.date.slice(0, 19).replace('T', ' '),
          transaction.description,
          JSON.stringify(transaction.tags ?? []),
          transaction.location ?? null,
          transaction.isRecurring ?? false,
          transaction.status,
          transaction.businessName ?? null,
          transaction.vendorName ?? null,
          transaction.invoiceNumber ?? null,
          transaction.gstPaise ?? null,
          transaction.isReimbursable ?? false,
          transaction.paidPersonally ?? false,
          transaction.dueDate ? transaction.dueDate.slice(0, 19).replace('T', ' ') : null,
          transaction.projectOrDepartment ?? null,
          transaction.personId ?? null,
          req.user.id
        ]
      );

      await applyAccountMovement(pool, req.user.id, transaction);

      const [rows] = await pool.execute('SELECT * FROM transactions WHERE id = ? AND user_id = ?', [
        transaction.id,
        req.user.id
      ]);
      res.status(201).json({ data: mapTransaction(rows[0]) });
    } catch (error) {
      next(error);
    }
  });
}

async function applyAccountMovement(pool, userId, transaction) {
  const sourceDelta = accountDelta(transaction.type, true, transaction.amountPaise);
  const targetDelta = accountDelta(transaction.type, false, transaction.amountPaise);

  if (sourceDelta !== 0) {
    await pool.execute(
      `UPDATE accounts
       SET balance_paise = balance_paise + ?,
           available_balance_paise = COALESCE(available_balance_paise, balance_paise) + ?
       WHERE id = ? AND user_id = ?`,
      [sourceDelta, sourceDelta, transaction.accountId, userId]
    );
  }

  if (transaction.type === 'expense') {
    await pool.execute(
      `UPDATE accounts
       SET outstanding_paise = outstanding_paise + ?
       WHERE id = ? AND user_id = ? AND type = 'creditCard'`,
      [transaction.amountPaise, transaction.accountId, userId]
    );
  }

  if (transaction.toAccountId && targetDelta !== 0) {
    await pool.execute(
      `UPDATE accounts
       SET balance_paise = balance_paise + ?,
           available_balance_paise = COALESCE(available_balance_paise, balance_paise) + ?
       WHERE id = ? AND user_id = ?`,
      [targetDelta, targetDelta, transaction.toAccountId, userId]
    );
  }
}

function accountDelta(type, source, amountPaise) {
  switch (type) {
    case 'income':
    case 'moneyBorrowed':
    case 'receivableCollection':
      return source ? amountPaise : 0;
    case 'expense':
    case 'emiPayment':
    case 'moneyLent':
    case 'repayment':
    case 'loan':
      return source ? -amountPaise : 0;
    case 'transfer':
      return source ? -amountPaise : amountPaise;
    default:
      return 0;
  }
}
