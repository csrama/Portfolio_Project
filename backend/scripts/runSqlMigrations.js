const fs = require('fs');
const path = require('path');
const { Client } = require('pg');
require('dotenv').config();

const migrationsDir = path.join(__dirname, '..', 'src', 'db', 'migrations');
const args = process.argv.slice(2);
const reset = args.includes('--reset');

async function run() {
  const client = new Client({ connectionString: process.env.DATABASE_URL });

  try {
    await client.connect();
    console.log('Connected to database. Running SQL migrations...');

    if (reset) {
      console.log('Resetting public schema...');
      await client.query('DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;');
    }

    const files = fs.readdirSync(migrationsDir)
      .filter((file) => file.endsWith(".sql"))
      .sort((a, b) => a.localeCompare(b));

    for (const file of files) {
      const filePath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(filePath, 'utf8');

      console.log(`Applying migration: ${file}`);
      await client.query(sql);
    }

    console.log('SQL migrations completed successfully.');
  } catch (err) {
    if (err.code === 'ECONNREFUSED' || err.code === 'ENOTFOUND' || err.message?.includes('getaddrinfo')) {
      console.warn('Database unavailable. Skipping migrations and continuing with the in-memory test store.');
      process.exitCode = 0;
      return;
    }

    console.error('Migration failed:', err.message);
    process.exitCode = 1;
  } finally {
    if (client) {
      try {
        await client.end();
      } catch (cleanupError) {
        console.warn('Failed to close database client cleanly:', cleanupError.message);
      }
    }
  }
}

run();
