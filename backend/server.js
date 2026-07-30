// server.js — Express server (PostgreSQL / Neon).
// Auth + user CRUD + profiles/swipes/matches, and serves the frontend.

const path = require('path');
const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const { pool } = require('./db');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

// SHA-256 password hashing (dependency-free; a real app would use bcrypt/argon2).
function hashPassword(pw) {
  return crypto.createHash('sha256').update(String(pw)).digest('hex');
}

// Accurate age from birth_date (whole years).
const AGE_EXPR = 'EXTRACT(YEAR FROM AGE(p.birth_date))::int';
const GENDERS = ['M', 'F', 'O'];

// --- Auth helpers ------------------------------------------------------------
async function getRequester(req) {
  const id = parseInt(req.header('x-user-id'), 10);
  if (!Number.isInteger(id)) return null;
  const { rows } = await pool.query('SELECT user_id, is_admin FROM users WHERE user_id = $1', [id]);
  return rows[0] || null;
}

async function requireAdmin(req, res, next) {
  try {
    const u = await getRequester(req);
    if (!u || !u.is_admin) return res.status(403).json({ error: 'Admin access required.' });
    req.requester = u;
    next();
  } catch (err) {
    return res.status(503).json({ error: 'Authorization check failed.', details: err.message });
  }
}

// The "session" view of a user (safe fields only).
async function loadSessionUser(id) {
  const { rows } = await pool.query(`
    SELECT u.user_id, u.username, u.email, u.is_admin,
           p.first_name, p.last_name, p.gender, p.location_name, p.bio, p.birth_date,
           ${AGE_EXPR} AS age,
           COALESCE(ph.url, p.profile_photo_url) AS photo_url
    FROM users u
    LEFT JOIN profiles p ON p.user_id = u.user_id
    LEFT JOIN photos ph ON ph.user_id = u.user_id AND ph.is_primary = 1
    WHERE u.user_id = $1`, [id]);
  const row = rows[0];
  if (row) row.is_admin = !!row.is_admin;
  return row || null;
}

// ===========================================================================
//  AUTH — register + login (the landing screen)
// ===========================================================================
app.post('/api/auth/register', async (req, res) => {
  const b = req.body || {};
  const required = ['username', 'email', 'password', 'first_name', 'last_name', 'birth_date', 'gender'];
  const missing = required.filter((f) => !b[f] && b[f] !== 0);
  if (missing.length) return res.status(400).json({ error: `Missing required fields: ${missing.join(', ')}.` });
  if (!GENDERS.includes(b.gender)) return res.status(400).json({ error: `gender must be one of: ${GENDERS.join(', ')}.` });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const dup = await client.query('SELECT user_id FROM users WHERE username = $1 OR email = $2', [b.username, b.email]);
    if (dup.rows.length) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'That username or email is already taken.' });
    }
    const ins = await client.query(
      `INSERT INTO users (username, email, password_hash, created_at, is_admin)
       VALUES ($1, $2, $3, NOW(), 0) RETURNING user_id`,
      [b.username, b.email, hashPassword(b.password)]);
    const newId = ins.rows[0].user_id;
    await client.query(
      `INSERT INTO profiles (user_id, first_name, last_name, birth_date, gender, bio, location_name, profile_photo_url, last_modified_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())`,
      [newId, b.first_name, b.last_name, b.birth_date, b.gender, b.bio || null, b.location_name || null, b.profile_photo_url || null]);
    await client.query('COMMIT');
    const user = await loadSessionUser(newId);
    return res.status(201).json({ ok: true, user });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('Error in POST /api/auth/register:', err.message);
    return res.status(503).json({ error: 'Could not register.', details: err.message });
  } finally {
    client.release();
  }
});

app.post('/api/auth/login', async (req, res) => {
  const identifier = req.body?.identifier;
  const password = req.body?.password;
  if (!identifier || !password) return res.status(400).json({ error: 'identifier and password are required.' });
  try {
    const { rows } = await pool.query(
      `SELECT user_id FROM users WHERE (username = $1 OR email = $1) AND password_hash = $2`,
      [identifier, hashPassword(password)]);
    if (!rows.length) return res.status(401).json({ error: 'Invalid username/email or password.' });
    const user = await loadSessionUser(rows[0].user_id);
    return res.status(200).json({ ok: true, user });
  } catch (err) {
    console.error('Error in POST /api/auth/login:', err.message);
    return res.status(503).json({ error: 'Login failed.', details: err.message });
  }
});

app.get('/api/auth/me/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'id must be an integer.' });
  try {
    const user = await loadSessionUser(id);
    if (!user) return res.status(404).json({ error: 'User not found.' });
    return res.status(200).json({ ok: true, user });
  } catch (err) {
    return res.status(503).json({ error: 'Could not load user.', details: err.message });
  }
});

// ===========================================================================
//  USERS CRUD — management routes are admin-only; a user may act on themselves.
// ===========================================================================

// GET /api/users — list with filters (admin only).
app.get('/api/users', requireAdmin, async (req, res) => {
  const { search, gender, minAge, maxAge, city, sort } = req.query;
  const conds = [];
  const params = [];
  try {
    if (search) {
      params.push(`%${search}%`);
      const p = `$${params.length}`;
      conds.push(`(p.first_name ILIKE ${p} OR p.last_name ILIKE ${p} OR u.username ILIKE ${p} OR u.email ILIKE ${p})`);
    }
    if (gender && GENDERS.includes(gender)) { params.push(gender); conds.push(`p.gender = $${params.length}`); }
    if (city) { params.push(`%${city}%`); conds.push(`p.location_name ILIKE $${params.length}`); }
    if (minAge && Number.isInteger(+minAge)) { params.push(+minAge); conds.push(`${AGE_EXPR} >= $${params.length}`); }
    if (maxAge && Number.isInteger(+maxAge)) { params.push(+maxAge); conds.push(`${AGE_EXPR} <= $${params.length}`); }

    const orderBy = {
      name: 'p.first_name ASC', age_asc: 'age ASC', age_desc: 'age DESC',
      city: 'p.location_name ASC', newest: 'u.created_at DESC',
    }[sort] || 'u.user_id ASC';
    const where = conds.length ? 'WHERE ' + conds.join(' AND ') : '';

    const { rows } = await pool.query(`
      SELECT u.user_id, u.username, u.email, u.created_at,
             p.first_name, p.last_name, p.gender, p.bio, p.location_name, p.birth_date,
             ${AGE_EXPR} AS age,
             COALESCE(ph.url, p.profile_photo_url) AS photo_url
      FROM users u
      LEFT JOIN profiles p ON p.user_id = u.user_id
      LEFT JOIN photos ph ON ph.user_id = u.user_id AND ph.is_primary = 1
      ${where}
      ORDER BY ${orderBy}`, params);
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Error in GET /api/users:', err.message);
    return res.status(503).json({ error: 'Could not fetch users.', details: err.message });
  }
});

// GET /api/users/:id — admin or self.
app.get('/api/users/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'id must be an integer.' });
  const requester = await getRequester(req);
  if (!requester || (!requester.is_admin && requester.user_id !== id)) {
    return res.status(403).json({ error: 'You can only view your own account.' });
  }
  try {
    const { rows } = await pool.query(`
      SELECT u.user_id, u.username, u.email, u.created_at,
             p.first_name, p.last_name, p.gender, p.bio, p.location_name, p.birth_date,
             p.profile_photo_url, ${AGE_EXPR} AS age,
             COALESCE(ph.url, p.profile_photo_url) AS photo_url
      FROM users u
      LEFT JOIN profiles p ON p.user_id = u.user_id
      LEFT JOIN photos ph ON ph.user_id = u.user_id AND ph.is_primary = 1
      WHERE u.user_id = $1`, [id]);
    if (!rows.length) return res.status(404).json({ error: 'User not found.' });
    return res.status(200).json(rows[0]);
  } catch (err) {
    console.error('Error in GET /api/users/:id:', err.message);
    return res.status(503).json({ error: 'Could not fetch the user.', details: err.message });
  }
});

// POST /api/users — admin creates a user + profile.
app.post('/api/users', requireAdmin, async (req, res) => {
  const b = req.body || {};
  const required = ['username', 'email', 'password', 'first_name', 'last_name', 'birth_date', 'gender'];
  const missing = required.filter((f) => !b[f] && b[f] !== 0);
  if (missing.length) return res.status(400).json({ error: `Missing required fields: ${missing.join(', ')}.` });
  if (!GENDERS.includes(b.gender)) return res.status(400).json({ error: `gender must be one of: ${GENDERS.join(', ')}.` });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const dup = await client.query('SELECT user_id FROM users WHERE username = $1 OR email = $2', [b.username, b.email]);
    if (dup.rows.length) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'A user with that username or email already exists.' });
    }
    const ins = await client.query(
      `INSERT INTO users (username, email, password_hash, created_at, is_admin)
       VALUES ($1, $2, $3, NOW(), 0) RETURNING user_id`,
      [b.username, b.email, hashPassword(b.password)]);
    const newId = ins.rows[0].user_id;
    await client.query(
      `INSERT INTO profiles (user_id, first_name, last_name, birth_date, gender, bio, location_name, profile_photo_url, last_modified_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())`,
      [newId, b.first_name, b.last_name, b.birth_date, b.gender, b.bio || null, b.location_name || null, b.profile_photo_url || null]);
    await client.query('COMMIT');
    return res.status(201).json({ ok: true, user_id: newId, message: 'User created.' });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('Error in POST /api/users:', err.message);
    return res.status(503).json({ error: 'Could not create the user.', details: err.message });
  } finally {
    client.release();
  }
});

// PUT /api/users/:id — admin or self (partial update).
app.put('/api/users/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'id must be an integer.' });
  const requester = await getRequester(req);
  if (!requester || (!requester.is_admin && requester.user_id !== id)) {
    return res.status(403).json({ error: 'You can only edit your own account.' });
  }
  const b = req.body || {};
  if (b.gender && !GENDERS.includes(b.gender)) {
    return res.status(400).json({ error: `gender must be one of: ${GENDERS.join(', ')}.` });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const exists = await client.query('SELECT user_id FROM users WHERE user_id = $1', [id]);
    if (!exists.rows.length) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'User not found.' });
    }

    // Account fields.
    const uSets = [], uParams = [];
    const addU = (col, val) => { uParams.push(val); uSets.push(`${col} = $${uParams.length}`); };
    if (b.username !== undefined) addU('username', b.username);
    if (b.email !== undefined) addU('email', b.email);
    if (b.password) addU('password_hash', hashPassword(b.password));
    if (uSets.length) {
      uParams.push(id);
      await client.query(`UPDATE users SET ${uSets.join(', ')} WHERE user_id = $${uParams.length}`, uParams);
    }

    // Profile fields.
    const pSets = [], pParams = [];
    const addP = (col, val) => { pParams.push(val); pSets.push(`${col} = $${pParams.length}`); };
    if (b.first_name !== undefined) addP('first_name', b.first_name);
    if (b.last_name !== undefined) addP('last_name', b.last_name);
    if (b.birth_date !== undefined) addP('birth_date', b.birth_date);
    if (b.gender !== undefined) addP('gender', b.gender);
    if (b.bio !== undefined) addP('bio', b.bio);
    if (b.location_name !== undefined) addP('location_name', b.location_name);
    if (b.profile_photo_url !== undefined) addP('profile_photo_url', b.profile_photo_url);
    if (pSets.length) {
      pSets.push('last_modified_at = NOW()');
      pParams.push(id);
      await client.query(`UPDATE profiles SET ${pSets.join(', ')} WHERE user_id = $${pParams.length}`, pParams);
    }

    await client.query('COMMIT');
    return res.status(200).json({ ok: true, message: 'User updated.' });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('Error in PUT /api/users/:id:', err.message);
    if (err.code === '23505') return res.status(409).json({ error: 'That username or email is already taken.' });
    return res.status(503).json({ error: 'Could not update the user.', details: err.message });
  } finally {
    client.release();
  }
});

// DELETE /api/users/:id — admin or self; removes all dependent rows.
app.delete('/api/users/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'id must be an integer.' });
  const requester = await getRequester(req);
  if (!requester || (!requester.is_admin && requester.user_id !== id)) {
    return res.status(403).json({ error: 'You can only delete your own account.' });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const q = (text) => client.query(text, [id]);
    await q(`DELETE FROM messages WHERE sender_id = $1
             OR match_id IN (SELECT match_id FROM matches WHERE user1_id = $1 OR user2_id = $1)`);
    await q('DELETE FROM matches WHERE user1_id = $1 OR user2_id = $1');
    await q('DELETE FROM swipes WHERE swiper_id = $1 OR swiped_id = $1');
    await q('DELETE FROM blocks WHERE blocker_id = $1 OR blocked_user_id = $1');
    await q('DELETE FROM reports WHERE reporter_id = $1 OR reported_user_id = $1');
    await q('DELETE FROM photos WHERE user_id = $1');
    await q('DELETE FROM superlikes_balance WHERE user_id = $1');
    await q('DELETE FROM user_payments WHERE user_id = $1');
    await q('DELETE FROM user_preferences WHERE user_id = $1');
    await q('DELETE FROM profiles WHERE user_id = $1');
    await q('UPDATE users SET referred_by_user_id = NULL WHERE referred_by_user_id = $1');
    const del = await q('DELETE FROM users WHERE user_id = $1');
    if (del.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'User not found.' });
    }
    await client.query('COMMIT');
    return res.status(200).json({ ok: true, message: `User ${id} and all related data deleted.` });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('Error in DELETE /api/users/:id:', err.message);
    return res.status(503).json({ error: 'Could not delete the user.', details: err.message });
  } finally {
    client.release();
  }
});

// ===========================================================================
//  PROFILES / SWIPES / MATCHES / LIKES
// ===========================================================================
app.get('/api/profiles', async (req, res) => {
  // Optional ?viewer=<id>: flag profiles that have *superliked* the viewer,
  // so the UI can surface them (just like the real Tinder blue star).
  const viewer = parseInt(req.query.viewer, 10);
  const hasViewer = Number.isInteger(viewer);
  const superCol = hasViewer
    ? `EXISTS (SELECT 1 FROM swipes s
               WHERE s.swiper_id = p.user_id AND s.swiped_id = $1 AND s.swipetype = 'superlike')`
    : 'false';
  try {
    const { rows } = await pool.query(`
      SELECT p.user_id, p.first_name, p.last_name, p.gender, p.bio, p.location_name, p.birth_date,
             ${AGE_EXPR} AS age,
             COALESCE(ph.url, p.profile_photo_url) AS photo_url,
             ${superCol} AS superliked_you
      FROM profiles p
      LEFT JOIN photos ph ON p.user_id = ph.user_id AND ph.is_primary = 1
      ORDER BY p.user_id`, hasViewer ? [viewer] : []);
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Error in GET /api/profiles:', err.message);
    return res.status(503).json({ error: 'Could not fetch profiles.', details: err.message });
  }
});

const VALID_SWIPES = ['like', 'dislike', 'superlike'];

app.post('/api/swipes', async (req, res) => {
  const swiperId = parseInt(req.body.swiperId, 10);
  const swipedId = parseInt(req.body.swipedId, 10);
  const swipeType = String(req.body.swipeType || '').toLowerCase();
  if (!Number.isInteger(swiperId) || !Number.isInteger(swipedId)) {
    return res.status(400).json({ error: 'swiperId and swipedId must be integers.' });
  }
  if (swiperId === swipedId) return res.status(400).json({ error: 'You cannot swipe on yourself.' });
  if (!VALID_SWIPES.includes(swipeType)) {
    return res.status(400).json({ error: `swipeType must be one of: ${VALID_SWIPES.join(', ')}.` });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM swipes WHERE swiper_id = $1 AND swiped_id = $2', [swiperId, swipedId]);
    await client.query(
      `INSERT INTO swipes (swiper_id, swiped_id, swipetype, created_at) VALUES ($1, $2, $3, NOW())`,
      [swiperId, swipedId, swipeType]);

    let match = false, matchedProfile = null;
    if (swipeType === 'like' || swipeType === 'superlike') {
      const recip = await client.query(
        `SELECT 1 FROM swipes WHERE swiper_id = $1 AND swiped_id = $2 AND swipetype IN ('like','superlike') LIMIT 1`,
        [swipedId, swiperId]);
      if (recip.rows.length) {
        match = true;
        const u1 = Math.min(swiperId, swipedId), u2 = Math.max(swiperId, swipedId);
        await client.query(
          `INSERT INTO matches (user1_id, user2_id, matched_at) VALUES ($1, $2, NOW())
           ON CONFLICT (user1_id, user2_id) DO NOTHING`, [u1, u2]);
        const prof = await client.query(`
          SELECT p.user_id, p.first_name, p.last_name,
                 COALESCE(ph.url, p.profile_photo_url) AS photo_url
          FROM profiles p
          LEFT JOIN photos ph ON p.user_id = ph.user_id AND ph.is_primary = 1
          WHERE p.user_id = $1`, [swipedId]);
        matchedProfile = prof.rows[0] || null;
      }
    }
    await client.query('COMMIT');
    return res.status(201).json({ ok: true, match, matchedProfile });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('Error in POST /api/swipes:', err.message);
    return res.status(503).json({ error: 'Could not save the swipe.', details: err.message });
  } finally {
    client.release();
  }
});

app.get('/api/matches/:userId', async (req, res) => {
  const userId = parseInt(req.params.userId, 10);
  if (!Number.isInteger(userId)) return res.status(400).json({ error: 'userId must be an integer.' });
  try {
    const { rows } = await pool.query(`
      SELECT p.user_id, p.first_name, p.last_name, p.location_name,
             COALESCE(ph.url, p.profile_photo_url) AS photo_url, m.matched_at
      FROM matches m
      JOIN profiles p ON p.user_id = CASE WHEN m.user1_id = $1 THEN m.user2_id ELSE m.user1_id END
      LEFT JOIN photos ph ON p.user_id = ph.user_id AND ph.is_primary = 1
      WHERE m.user1_id = $1 OR m.user2_id = $1
      ORDER BY m.matched_at DESC`, [userId]);
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Error in GET /api/matches:', err.message);
    return res.status(503).json({ error: 'Could not fetch matches.', details: err.message });
  }
});

app.get('/api/likes/:userId', async (req, res) => {
  const userId = parseInt(req.params.userId, 10);
  if (!Number.isInteger(userId)) return res.status(400).json({ error: 'userId must be an integer.' });
  try {
    const { rows } = await pool.query(`
      SELECT p.user_id, p.first_name, p.last_name, p.location_name,
             COALESCE(ph.url, p.profile_photo_url) AS photo_url,
             s.swipetype, s.created_at,
             CASE WHEN EXISTS (
               SELECT 1 FROM swipes r
               WHERE r.swiper_id = s.swiped_id AND r.swiped_id = $1 AND r.swipetype IN ('like','superlike')
             ) THEN 1 ELSE 0 END AS is_mutual
      FROM swipes s
      JOIN profiles p ON p.user_id = s.swiped_id
      LEFT JOIN photos ph ON p.user_id = ph.user_id AND ph.is_primary = 1
      WHERE s.swiper_id = $1 AND s.swipetype IN ('like','superlike')
      ORDER BY s.created_at DESC`, [userId]);
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Error in GET /api/likes:', err.message);
    return res.status(503).json({ error: 'Could not fetch likes.', details: err.message });
  }
});

// ===========================================================================
//  ANALYTICS — aggregated insights for the admin dashboard (admin-only).
//  Turns the raw tables into business metrics: who's on the platform,
//  how active they are, and how well matching is working.
// ===========================================================================
app.get('/api/stats', requireAdmin, async (req, res) => {
  try {
    const [totals, byGender, ageDist, byCity, swipeKinds] = await Promise.all([
      pool.query(`
        SELECT
          (SELECT COUNT(*) FROM users)::int                                          AS users,
          (SELECT COUNT(*) FROM swipes)::int                                         AS swipes,
          (SELECT COUNT(*) FROM swipes WHERE swipetype IN ('like','superlike'))::int AS likes,
          (SELECT COUNT(*) FROM matches)::int                                        AS matches,
          (SELECT COUNT(*) FROM users WHERE is_admin = 1)::int                       AS admins`),
      pool.query(`
        SELECT COALESCE(gender, 'O') AS gender, COUNT(*)::int AS count
        FROM profiles GROUP BY COALESCE(gender, 'O')`),
      pool.query(`
        SELECT bucket, COUNT(*)::int AS count FROM (
          SELECT CASE
            WHEN a < 25 THEN '18–24'
            WHEN a < 32 THEN '25–31'
            WHEN a < 39 THEN '32–38'
            WHEN a < 46 THEN '39–45'
            ELSE '46+'
          END AS bucket
          FROM (SELECT EXTRACT(YEAR FROM AGE(birth_date))::int AS a
                FROM profiles WHERE birth_date IS NOT NULL) t
        ) b GROUP BY bucket`),
      pool.query(`
        SELECT location_name AS city, COUNT(*)::int AS count
        FROM profiles
        WHERE location_name IS NOT NULL AND location_name <> ''
        GROUP BY location_name ORDER BY count DESC, city ASC LIMIT 7`),
      pool.query(`
        SELECT swipetype AS kind, COUNT(*)::int AS count
        FROM swipes GROUP BY swipetype`),
    ]);

    const t = totals.rows[0];
    const matchRate = t.likes ? Math.round((t.matches / t.likes) * 100) : 0;

    // Order the age buckets consistently (SQL GROUP BY is unordered).
    const AGE_ORDER = ['18–24', '25–31', '32–38', '39–45', '46+'];
    const ageMap = Object.fromEntries(ageDist.rows.map((r) => [r.bucket, r.count]));
    const ageDistribution = AGE_ORDER.map((bucket) => ({ bucket, count: ageMap[bucket] || 0 }));

    return res.status(200).json({
      totals: { ...t, matchRate },
      byGender: byGender.rows,
      ageDistribution,
      byCity: byCity.rows,
      swipeKinds: swipeKinds.rows,
    });
  } catch (err) {
    console.error('Error in GET /api/stats:', err.message);
    return res.status(503).json({ error: 'Could not compute stats.', details: err.message });
  }
});

// GET /api/liked-me/:userId — people who liked or superliked ME (an "incoming"
// view). Superlikes are flagged and sorted first; mutual likes are marked.
app.get('/api/liked-me/:userId', async (req, res) => {
  const userId = parseInt(req.params.userId, 10);
  if (!Number.isInteger(userId)) return res.status(400).json({ error: 'userId must be an integer.' });
  try {
    const { rows } = await pool.query(`
      SELECT p.user_id, p.first_name, p.last_name, p.location_name,
             ${AGE_EXPR} AS age,
             COALESCE(ph.url, p.profile_photo_url) AS photo_url,
             s.swipetype, s.created_at,
             CASE WHEN EXISTS (
               SELECT 1 FROM swipes r
               WHERE r.swiper_id = $1 AND r.swiped_id = s.swiper_id AND r.swipetype IN ('like','superlike')
             ) THEN 1 ELSE 0 END AS is_mutual
      FROM swipes s
      JOIN profiles p ON p.user_id = s.swiper_id
      LEFT JOIN photos ph ON p.user_id = ph.user_id AND ph.is_primary = 1
      WHERE s.swiped_id = $1 AND s.swipetype IN ('like','superlike')
      ORDER BY (s.swipetype = 'superlike') DESC, s.created_at DESC`, [userId]);
    return res.status(200).json(rows);
  } catch (err) {
    console.error('Error in GET /api/liked-me:', err.message);
    return res.status(503).json({ error: 'Could not fetch incoming likes.', details: err.message });
  }
});

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});
