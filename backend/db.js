// db.js — a single, shared PostgreSQL connection pool (Neon).
// The whole app talks to the database through this one pool.

const { Pool } = require('pg');
require('dotenv').config();

// Neon requires SSL. The connection string lives in DATABASE_URL (never hardcoded).
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 10,
  idleTimeoutMillis: 30000,
});

pool.on('error', (err) => {
  console.error('Unexpected idle client error:', err.message);
});

// Small helper so routes can run a query without grabbing a client each time.
function query(text, params) {
  return pool.query(text, params);
}

module.exports = { pool, query };
