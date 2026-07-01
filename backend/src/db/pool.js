require('dotenv').config();
const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });

function normalizeUser(user) {
  return {
    id: user.id,
    email: user.email,
    full_name: user.full_name,
    user_type: user.user_type || 'patient',
    age: user.age || null,
    sex: user.sex || null,
    medical_condition: user.medical_condition || null,
    is_onboarding_complete: user.is_onboarding_complete || false,
    is_active: user.is_active !== false,
    created_at: user.created_at || new Date().toISOString(),
    updated_at: user.updated_at || new Date().toISOString()
  };
}

const db = {
  async query(text, params = []) {
    return pool.query(text, params);
  },

  async createUser(data) {
    const { rows } = await pool.query(
      `INSERT INTO users (email, password_hash, full_name, user_type, age, sex, medical_condition, is_onboarding_complete, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        data.email,
        data.password_hash,
        data.full_name || null,
        data.user_type || 'patient',
        data.age || null,
        data.sex || null,
        data.medical_condition || null,
        data.is_onboarding_complete || false,
        data.is_active !== false
      ]
    );
    return normalizeUser(rows[0]);
  },

  async findUserByEmail(email) {
    const { rows } = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    return rows[0] || null;
  },

  async findUserById(id) {
    const { rows } = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    return rows[0] || null;
  },

  async createMedication(data) {
    const { rows } = await pool.query(
      `INSERT INTO medications (user_id, name, dosage, form, instructions, color, total_quantity, low_stock_threshold, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        data.user_id,
        data.name,
        data.dosage || null,
        data.form || 'tablet',
        data.instructions || null,
        data.color || null,
        data.total_quantity || 1,
        data.low_stock_threshold || 1,
        data.is_active !== false
      ]
    );
    return rows[0];
  },

  async listMedications(userId) {
    const { rows } = await pool.query('SELECT * FROM medications WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    return rows;
  },

  async getMedicationById(id) {
    const { rows } = await pool.query('SELECT * FROM medications WHERE id = $1', [id]);
    return rows[0] || null;
  },

  async createSchedule(data) {
    const { rows } = await pool.query(
      `INSERT INTO schedules (user_id, medication_id, days_of_week, time_of_day, is_active)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        data.user_id,
        data.medication_id,
        data.days_of_week || ['Monday'],
        data.time_of_day || '08:00',
        data.is_active !== false
      ]
    );
    return rows[0];
  },

  async listSchedules(userId) {
    const { rows } = await pool.query('SELECT * FROM schedules WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    return rows;
  },

  async createDoseRecord(data) {
    const { rows } = await pool.query(
      `INSERT INTO dose_records (user_id, medication_id, schedule_id, scheduled_time, taken_time, status, dose_taken)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        data.user_id,
        data.medication_id,
        data.schedule_id || null,
        data.scheduled_time || new Date().toISOString(),
        data.taken_time || null,
        data.status || 'PENDING',
        Boolean(data.dose_taken)
      ]
    );
    return rows[0];
  },

  async listDoseRecords(userId) {
    const { rows } = await pool.query('SELECT * FROM dose_records WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    return rows;
  },

  async updateDoseRecord(id, updates) {
    const { rows } = await pool.query(
      `UPDATE dose_records SET status = COALESCE($2, status), taken_time = COALESCE($3, taken_time), dose_taken = COALESCE($4, dose_taken), updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id, updates.status, updates.taken_time || null, updates.dose_taken]
    );
    return rows[0] || null;
  },

  async createNotification(data) {
    const { rows } = await pool.query(
      `INSERT INTO notification_logs (user_id, type, title, body, data, sent_at, delivered)
       VALUES ($1, $2, $3, $4, $5, NOW(), TRUE)
       RETURNING *`,
      [
        data.user_id,
        data.type || 'info',
        data.title || 'Reminder',
        data.body || '',
        JSON.stringify(data.data || {})
      ]
    );
    return rows[0];
  }
};

module.exports = { pool: db, db, normalizeUser };

