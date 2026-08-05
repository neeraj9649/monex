/// Account deletion with a 30-day grace period.
///
/// Google Play requires both an in-app deletion path and a publicly reachable
/// web page. This module provides the API behind both, plus the purge that
/// actually removes the data.

export const GRACE_PERIOD_DAYS = 30;

/// Child tables are cleared before `users` because each one has a foreign key
/// pointing at it. Order matters.
const childTables = [
  'transactions',
  'password_reset_tokens',
  'loans',
  'categories',
  'accounts'
];

export function registerAccountDeletionRoutes(app, pool) {
  // Current deletion state, so the app can show a "pending deletion" banner.
  app.get('/api/account/deletion', async (req, res, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT deletion_requested_at FROM users WHERE id = ?',
        [req.user.id]
      );
      if (rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.json({ data: deletionStatus(rows[0].deletion_requested_at) });
    } catch (error) {
      next(error);
    }
  });

  // Schedules deletion. Idempotent: asking twice does not extend the window.
  app.post('/api/account/deletion', async (req, res, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT deletion_requested_at FROM users WHERE id = ?',
        [req.user.id]
      );
      if (rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      if (!rows[0].deletion_requested_at) {
        await pool.execute(
          'UPDATE users SET deletion_requested_at = NOW() WHERE id = ?',
          [req.user.id]
        );
      }

      const [updated] = await pool.execute(
        'SELECT deletion_requested_at FROM users WHERE id = ?',
        [req.user.id]
      );
      res.json({ data: deletionStatus(updated[0].deletion_requested_at) });
    } catch (error) {
      next(error);
    }
  });

  // Cancels a pending deletion.
  app.delete('/api/account/deletion', async (req, res, next) => {
    try {
      await pool.execute(
        'UPDATE users SET deletion_requested_at = NULL WHERE id = ?',
        [req.user.id]
      );
      res.json({ data: deletionStatus(null) });
    } catch (error) {
      next(error);
    }
  });
}

function deletionStatus(requestedAt) {
  if (!requestedAt) {
    return { pending: false, requestedAt: null, scheduledPurgeAt: null };
  }
  const requested = new Date(requestedAt);
  const purgeAt = new Date(requested);
  purgeAt.setDate(purgeAt.getDate() + GRACE_PERIOD_DAYS);
  return {
    pending: true,
    requestedAt: requested.toISOString(),
    scheduledPurgeAt: purgeAt.toISOString()
  };
}

/// Permanently removes every user whose grace period has elapsed.
///
/// Returns the number of accounts purged. Safe to call repeatedly and
/// concurrently: it selects first, then deletes by explicit id.
export async function purgeExpiredAccounts(pool) {
  const [due] = await pool.execute(
    `SELECT id FROM users
     WHERE deletion_requested_at IS NOT NULL
       AND deletion_requested_at < (NOW() - INTERVAL ? DAY)`,
    [GRACE_PERIOD_DAYS]
  );
  if (due.length === 0) return 0;

  for (const user of due) {
    for (const table of childTables) {
      await pool.execute(`DELETE FROM \`${table}\` WHERE user_id = ?`, [
        user.id
      ]);
    }
    await pool.execute('DELETE FROM users WHERE id = ?', [user.id]);
  }

  return due.length;
}
