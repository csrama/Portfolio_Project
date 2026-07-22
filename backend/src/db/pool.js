require('dotenv').config();
const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;
console.log('🔍 DATABASE_URL exists:', !!connectionString);
console.log('🔍 DATABASE_URL starts with:', connectionString ? connectionString.substring(0, 30) : 'UNDEFINED');
const pool = new Pool({
  connectionString,
  ssl: { rejectUnauthorized: false },
});

pool.on('error', (err) => {
  console.error('❌ Unexpected DB pool error:', err);
});

function normalizeUserType(userType) {
  if (!userType) {
    return 'general_user';
  }
  return userType === 'patient' ? 'general_user' : userType;
}

function denormalizeUserType(userType) {
  if (userType === 'general_user' || !userType) {
    return 'patient';
  }
  return userType;
}

function normalizeUser(user) {
  if (!user) return null;
  return {
    id: user.id,
    email: user.email,
    full_name: user.full_name,
    user_type: normalizeUserType(user.user_type),
    age: user.age || null,
    sex: user.sex || null,
    medical_condition: user.medical_condition || null,
    is_onboarding_complete: user.is_onboarding_complete || false,
    is_active: user.is_active !== false,
    created_at: user.created_at || new Date().toISOString(),
    updated_at: user.updated_at || new Date().toISOString()
  };
}

async function queryWithFallback(text, params = []) 
{
  try {
    return await pool.query(text, params);
  } catch (error) {
    console.error(' DB query failed:', error.message);
    throw error;
  }
}

const db = {
  async query(text, params = []) {
    return queryWithFallback(text, params);
  },

  async searchMedicines(term)
   {
    const { rows } = await queryWithFallback(
      `SELECT id, name_en, name_ar, dosage, category
       FROM medicines
       WHERE name_en ILIKE $1 OR name_ar ILIKE $1
       ORDER BY name_en
       LIMIT 15`,
      [`%${term}%`]
    );

    return rows;
  },

  async createUser(data) 
  {
    const { rows } = await queryWithFallback(
      `INSERT INTO users (email, password_hash, full_name, user_type, age, sex, medical_condition, is_onboarding_complete, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        (data.email || '').toLowerCase(),
        data.password_hash,
        data.full_name || null,
        denormalizeUserType(data.user_type),
        data.age || null,
        data.sex || null,
        data.medical_condition || null,
        data.is_onboarding_complete || false,
        data.is_active !== false
      ]
    );
    return normalizeUser(rows[0]);
  },

  async findUserByEmail(email) 
  {
    const normalizedEmail = (email || '').toLowerCase();
    
    const { rows } = await queryWithFallback('SELECT * FROM users WHERE email = $1', [normalizedEmail]);
    return rows[0] || null;
  },

  async findUserById(id) 
  {
    const { rows } = await queryWithFallback('SELECT * FROM users WHERE id = $1', [id]);
    return rows[0] || null;
  },

  async updateUser(userId, updates) 
  {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (updates.full_name !== undefined) {
      fields.push(`full_name = $${paramIndex++}`);
      values.push(updates.full_name);
    }
    if (updates.age !== undefined) {
      fields.push(`age = $${paramIndex++}`);
      values.push(updates.age);
    }
    if (updates.sex !== undefined) {
      fields.push(`sex = $${paramIndex++}`);
      values.push(updates.sex);
    }
    if (updates.medical_condition !== undefined) {
      fields.push(`medical_condition = $${paramIndex++}`);
      values.push(updates.medical_condition);
    }
    if (updates.is_active !== undefined) {
      fields.push(`is_active = $${paramIndex++}`);
      values.push(updates.is_active);
    }

    if (fields.length === 0) return null;

    fields.push(`updated_at = NOW()`);
    values.push(userId);

    const { rows } = await queryWithFallback(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );
    return rows[0] || null;
  },

  async deleteUser(userId) 
  {
    const { rows } = await queryWithFallback(
      `DELETE FROM users WHERE id = $1 RETURNING id`,
      [userId]
    );
    return rows[0] || null;
  },

  async createMedication(data) 
  {
    const { rows } = await queryWithFallback(
      `INSERT INTO medications (
        user_id, dependent_id, name, dosage, form, instructions, color,
        total_quantity, low_stock_threshold, is_active,
        type, days_of_week, period, time, doses_per_day
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
      RETURNING *`,
      [
        data.user_id,
        data.dependent_id || null,
        data.name,
        data.dosage || null,
        data.form || 'tablet',
        data.instructions || null,
        data.color || null,
        data.total_quantity || 1,
        data.low_stock_threshold || 1,
        data.is_active !== false,
        data.type ?? 0,
        data.days_of_week ?? [],
        data.period ?? 'صباحا',
        data.time ?? '08:00',
        data.doses_per_day ?? 1
      ]
    );
    return rows[0];
  },

  async createDependentDirect(data) 
  {
    const { rows } = await queryWithFallback(
      `INSERT INTO dependents (
        caregiver_user_id, dependent_user_id, full_name, date_of_birth,
        relationship, profile_image_url, medical_conditions,
        invitation_status, invited_at, accepted_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, 'accepted', NOW(), NOW())
      RETURNING *`,
      [
        data.caregiver_user_id,
        data.dependent_user_id || null,
        data.full_name || '',
        data.date_of_birth || null,
        data.relationship,
        data.profile_image_url || null,
        data.medical_conditions || []
      ]
    );
    return rows[0];
  },

  async createDependent(data) 
  {
    const { rows } = await queryWithFallback(
      `INSERT INTO dependents (
        caregiver_user_id, dependent_user_id, full_name, date_of_birth,
        relationship, profile_image_url, medical_conditions,
        invitation_status, invitation_token, invited_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *`,
      [
        data.caregiver_user_id,
        data.dependent_user_id || null,
        data.full_name || '',
        data.date_of_birth || null,
        data.relationship,
        data.profile_image_url || null,
        data.medical_conditions || [],
        data.invitation_status || 'pending',
        data.invitation_token || null,
        new Date().toISOString()
      ]
    );
    return rows[0];
  },

  async listDependents(caregiverId) 
  {
    const { rows } = await queryWithFallback(
      'SELECT * FROM dependents WHERE caregiver_user_id = $1 ORDER BY created_at DESC',
      [caregiverId]
    );
    return rows;
  },

  async listDependentsWithUsers(caregiverId)
   {
    const { rows } = await queryWithFallback(
      `SELECT d.*, 
              u.id as user_id,
              u.email, 
              u.full_name as user_full_name, 
              u.user_type, 
              u.is_active,
              u.is_onboarding_complete
       FROM dependents d
       LEFT JOIN users u ON d.dependent_user_id = u.id
       WHERE d.caregiver_user_id = $1
       ORDER BY d.created_at DESC`,
      [caregiverId]
    );
    return rows;
  },

  async getDependentWithUser(dependentId, caregiverId) 
  {
    const { rows } = await queryWithFallback(
      `SELECT d.*, 
              u.id as user_id,
              u.email, 
              u.full_name as user_full_name, 
              u.user_type, 
              u.is_active,
              u.is_onboarding_complete
       FROM dependents d
       LEFT JOIN users u ON d.dependent_user_id = u.id
       WHERE d.id = $1 AND d.caregiver_user_id = $2`,
      [dependentId, caregiverId]
    );
    return rows[0] || null;
  },

  async getDependentById(dependentId, caregiverId) 
  {
    const { rows } = await queryWithFallback(
      'SELECT * FROM dependents WHERE id = $1 AND caregiver_user_id = $2',
      [dependentId, caregiverId]
    );
    return rows[0] || null;
  },

  async getDependentByInviteToken(token)
  {
    const { rows } = await queryWithFallback(
      'SELECT * FROM dependents WHERE invitation_token = $1',
      [token]
    );
    return rows[0] || null;
  },

  async updateDependent(dependentId, caregiverId, updates)
   {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (updates.relationship !== undefined) {
      fields.push(`relationship = $${paramIndex++}`);
      values.push(updates.relationship);
    }

    if (fields.length === 0) {
      return this.getDependentById(dependentId, caregiverId);
    }

    fields.push(`updated_at = NOW()`);
    values.push(dependentId, caregiverId);

    const { rows } = await queryWithFallback(
      `UPDATE dependents
       SET ${fields.join(', ')}
       WHERE id = $${paramIndex} AND caregiver_user_id = $${paramIndex + 1}
       RETURNING *`,
      values
    );
    return rows[0] || null;
  },

  async deleteDependent(dependentId, caregiverId)
   {
    const { rows } = await queryWithFallback(
      'DELETE FROM dependents WHERE id = $1 AND caregiver_user_id = $2 RETURNING id',
      [dependentId, caregiverId]
    );
    return rows[0] || null;
  },

  async acceptDependentInvite(dependentId) 
  {
    const { rows } = await queryWithFallback(
      `UPDATE dependents
       SET invitation_status = 'accepted', accepted_at = NOW(), updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [dependentId]
    );
    return rows[0] || null;
  },

  async claimDependentInvite(token, userId)
   {
    const dependent = await this.getDependentByInviteToken(token);
    if (!dependent) return null;
    if (dependent.invitation_status !== 'pending') return null;
    if (dependent.dependent_user_id && dependent.dependent_user_id !== userId) 
      {
      await queryWithFallback('DELETE FROM users WHERE id = $1', [dependent.dependent_user_id]);
    }

    const { rows } = await queryWithFallback(
      `UPDATE dependents
       SET dependent_user_id = $2, invitation_status = 'accepted', accepted_at = NOW(), updated_at = NOW()
       WHERE invitation_token = $1 AND invitation_status = 'pending'
       RETURNING *`,
      [token, userId]
    );
    return rows[0] || null;
  },

  async listMedications(userId, dependentId = null) 
  {
    let queryText;
    let params;

    if (dependentId) {
      queryText = `SELECT * FROM medications WHERE user_id = $1 OR dependent_id = $1 ORDER BY created_at DESC`;
      params = [dependentId];
    } else {
      queryText = `SELECT * FROM medications WHERE user_id = $1 AND (dependent_id IS NULL) ORDER BY created_at DESC`;
      params = [userId];
    }

    const { rows } = await queryWithFallback(queryText, params);
    return rows;
  },

  async getMedicationById(id) 
  {
    const { rows } = await queryWithFallback('SELECT * FROM medications WHERE id = $1', [id]);
    return rows[0] || null;
  },

  async updateMedication({ id, userId, updates }) 
  {
    const { rows } = await queryWithFallback(
      `UPDATE medications
       SET
         name = COALESCE($2, name),
         dosage = COALESCE($3, dosage),
         form = COALESCE($4, form),
         instructions = COALESCE($5, instructions),
         total_quantity = COALESCE($6, total_quantity),
         is_active = COALESCE($7, is_active),
         updated_at = NOW()
       WHERE id = $1 AND (user_id = $8 OR dependent_id = $8)
       RETURNING *`,
      [
        id,
        updates.name ?? null,
        updates.dosage ?? null,
        updates.form ?? null,
        updates.instructions ?? null,
        updates.total_quantity ?? null,
        updates.is_active ?? null,
        userId
      ]
    );

    return rows[0] || null;
  },

  async deleteMedication({ id, userId }) 
  {
    const { rows } = await queryWithFallback(
      `UPDATE medications
       SET is_active = FALSE, updated_at = NOW()
       WHERE id = $1 AND (user_id = $2 OR dependent_id = $2)
       RETURNING *`,
      [id, userId]
    );

    return rows[0] || null;
  },

  async createSchedule(data) 
  {
    const { rows } = await queryWithFallback(
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

  async listSchedules(userId) 
  {
    const { rows } = await queryWithFallback('SELECT * FROM schedules WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    return rows;
  },

  async createDoseRecord(data)
   {
    const { rows } = await queryWithFallback(
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

  async listDoseRecords(userId)
   {
    const { rows } = await queryWithFallback('SELECT * FROM dose_records WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    return rows;
  },

  async updateDoseRecord(id, updates)
   {
    const { rows } = await queryWithFallback(
      `UPDATE dose_records SET status = COALESCE($2, status), taken_time = COALESCE($3, taken_time), dose_taken = COALESCE($4, dose_taken), updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id, updates.status, updates.taken_time || null, updates.dose_taken]
    );
    return rows[0] || null;
  },

  async createNotification(data) 
  {
    const { rows } = await queryWithFallback(
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

module.exports = {
  pool: db,
  db,
  normalizeUser,
  pgPool: pool
};