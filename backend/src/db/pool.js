require('dotenv').config();
const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL;
let pool;
let useMemoryStore = false;

try {
  pool = new Pool({ connectionString });
} catch (error) {
  pool = null;
  useMemoryStore = true;
}

const memoryStore = {
  users: [],
  medications: [],
  schedules: [],
  doseRecords: [],
  notifications: [],
  dependents: []
};

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

async function queryWithFallback(text, params = []) {
  if (!pool) {
    throw new Error('قاعدة البيانات غير متوفرة');
  }

  try {
    return await pool.query(text, params);
  } catch (error) {
    if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND' || error.message?.includes('getaddrinfo')) {
      useMemoryStore = true;
      return { rows: [] };
    }
    throw error;
  }
}

const db = {
  async query(text, params = []) {
    return queryWithFallback(text, params);
  },

  async searchMedicines(term) {
    if (useMemoryStore) {
      return [];
    }

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

  async createUser(data) {
    if (useMemoryStore) {
      const user = {
        id: memoryStore.users.length + 1,
        email: (data.email || '').toLowerCase(),
        password_hash: data.password_hash,
        full_name: data.full_name || null,
        user_type: normalizeUserType(data.user_type),
        age: data.age || null,
        sex: data.sex || null,
        medical_condition: data.medical_condition || null,
        is_onboarding_complete: data.is_onboarding_complete || false,
        is_active: data.is_active !== false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      memoryStore.users.push(user);
      return normalizeUser(user);
    }

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

  async findUserByEmail(email) {
    const normalizedEmail = (email || '').toLowerCase();
    if (useMemoryStore) {
      return memoryStore.users.find((user) => user.email === normalizedEmail) || null;
    }

    const { rows } = await queryWithFallback('SELECT * FROM users WHERE email = $1', [normalizedEmail]);
    return rows[0] || null;
  },

  async findUserById(id) {
    if (useMemoryStore) {
      return memoryStore.users.find((user) => user.id === Number(id)) || null;
    }

    const { rows } = await queryWithFallback('SELECT * FROM users WHERE id = $1', [id]);
    return rows[0] || null;
  },

  async updateUser(userId, updates) {
    if (useMemoryStore) {
      const user = memoryStore.users.find((u) => u.id === Number(userId));
      if (!user) return null;
      Object.assign(user, updates);
      return user;
    }

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

  async deleteUser(userId) {
    if (useMemoryStore) {
      const index = memoryStore.users.findIndex((item) => item.id === Number(userId));
      if (index === -1) return null;
      memoryStore.users.splice(index, 1);
      return { id: Number(userId) };
    }

    const { rows } = await queryWithFallback(
      `DELETE FROM users WHERE id = $1 RETURNING id`,
      [userId]
    );
    return rows[0] || null;
  },

  async createMedication(data) {
    if (useMemoryStore) {
      const medication = {
        id: memoryStore.medications.length + 1,
        user_id: data.user_id,
        dependent_id: data.dependent_id || null,
        name: data.name,
        dosage: data.dosage || null,
        form: data.form || 'tablet',
        instructions: data.instructions || null,
        color: data.color || null,
        total_quantity: data.total_quantity || 1,
        low_stock_threshold: data.low_stock_threshold || 1,
        is_active: data.is_active !== false,
        type: data.type ?? 0,
        days_of_week: data.days_of_week ?? [],
        period: data.period ?? 'صباحا',
        time: data.time ?? '08:00',
        doses_per_day: data.doses_per_day ?? 1,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      memoryStore.medications.push(medication);
      return medication;
    }

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

  async createDependent(data) {
    if (useMemoryStore) {
      const dependent = {
        id: memoryStore.dependents.length + 1,
        caregiver_user_id: data.caregiver_user_id,
        dependent_user_id: data.dependent_user_id || null,
        full_name: data.full_name,
        date_of_birth: data.date_of_birth || null,
        relationship: data.relationship,
        profile_image_url: data.profile_image_url || null,
        medical_conditions: data.medical_conditions || [],
        invitation_status: data.invitation_status || 'pending',
        invitation_token: data.invitation_token || null,
        invited_at: new Date().toISOString(),
        accepted_at: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      memoryStore.dependents.push(dependent);
      return dependent;
    }

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
        data.full_name,
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

  async listDependents(caregiverId) {
    if (useMemoryStore) {
      return memoryStore.dependents.filter((item) => item.caregiver_user_id === Number(caregiverId));
    }

    const { rows } = await queryWithFallback(
      'SELECT * FROM dependents WHERE caregiver_user_id = $1 ORDER BY created_at DESC',
      [caregiverId]
    );
    return rows;
  },

  async listDependentsWithUsers(caregiverId) {
    if (useMemoryStore) {
      return memoryStore.dependents
        .filter((item) => item.caregiver_user_id === Number(caregiverId))
        .map((item) => {
          const user = memoryStore.users.find((u) => u.id === item.dependent_user_id);
          return { ...item, user };
        });
    }

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

  async getDependentWithUser(dependentId, caregiverId) {
    if (useMemoryStore) {
      const dependent = memoryStore.dependents.find(
        (item) => item.id === Number(dependentId) && item.caregiver_user_id === Number(caregiverId)
      );
      if (!dependent) return null;
      const user = memoryStore.users.find((u) => u.id === dependent.dependent_user_id);
      return { ...dependent, user };
    }

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

  async getDependentById(dependentId, caregiverId) {
    if (useMemoryStore) {
      return memoryStore.dependents.find(
        (item) => item.id === Number(dependentId) && item.caregiver_user_id === Number(caregiverId)
      ) || null;
    }

    const { rows } = await queryWithFallback(
      'SELECT * FROM dependents WHERE id = $1 AND caregiver_user_id = $2',
      [dependentId, caregiverId]
    );
    return rows[0] || null;
  },

  async getDependentByInviteToken(token) {
    if (useMemoryStore) {
      return memoryStore.dependents.find((item) => item.invitation_token === token) || null;
    }

    const { rows } = await queryWithFallback(
      'SELECT * FROM dependents WHERE invitation_token = $1',
      [token]
    );
    return rows[0] || null;
  },

  async updateDependent(dependentId, caregiverId, updates) {
    if (useMemoryStore) {
      const dependent = memoryStore.dependents.find(
        (item) => item.id === Number(dependentId) && item.caregiver_user_id === Number(caregiverId)
      );
      if (!dependent) return null;

      Object.assign(dependent, {
        relationship: updates.relationship ?? dependent.relationship,
        updated_at: new Date().toISOString()
      });
      return dependent;
    }

    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (updates.relationship !== undefined) {
      fields.push(`relationship = $${paramIndex++}`);
      values.push(updates.relationship);
    }

    if (fields.length === 0) {
      return getDependentById(dependentId, caregiverId);
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

  async deleteDependent(dependentId, caregiverId) {
    if (useMemoryStore) {
      const index = memoryStore.dependents.findIndex(
        (item) => item.id === Number(dependentId) && item.caregiver_user_id === Number(caregiverId)
      );
      if (index === -1) return null;
      memoryStore.dependents.splice(index, 1);
      return { id: Number(dependentId) };
    }

    const { rows } = await queryWithFallback(
      'DELETE FROM dependents WHERE id = $1 AND caregiver_user_id = $2 RETURNING id',
      [dependentId, caregiverId]
    );
    return rows[0] || null;
  },

  async acceptDependentInvite(dependentId) {
    if (useMemoryStore) {
      const dependent = memoryStore.dependents.find((item) => item.id === Number(dependentId));
      if (!dependent) return null;
      dependent.invitation_status = 'accepted';
      dependent.accepted_at = new Date().toISOString();
      return dependent;
    }

    const { rows } = await queryWithFallback(
      `UPDATE dependents
       SET invitation_status = 'accepted', accepted_at = NOW(), updated_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [dependentId]
    );
    return rows[0] || null;
  },

  async listMedications(userId, dependentId = null) {
    if (useMemoryStore) {
      return memoryStore.medications.filter((item) => {
        if (dependentId) {
          return item.user_id === Number(dependentId) || item.dependent_id === Number(dependentId);
        }
        return item.user_id === Number(userId) && !item.dependent_id;
      });
    }

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

  async getMedicationById(id) {
    if (useMemoryStore) {
      return memoryStore.medications.find((item) => item.id === Number(id)) || null;
    }

    const { rows } = await queryWithFallback('SELECT * FROM medications WHERE id = $1', [id]);
    return rows[0] || null;
  },

  async updateMedication({ id, userId, updates }) {
    if (useMemoryStore) {
      const medication = memoryStore.medications.find(
        (item) => item.id === Number(id) && (item.user_id === Number(userId) || item.dependent_id === Number(userId))
      );
      if (!medication) return null;

      Object.assign(medication, {
        name: updates.name ?? medication.name,
        dosage: updates.dosage ?? medication.dosage,
        form: updates.form ?? medication.form,
        instructions: updates.instructions ?? medication.instructions,
        total_quantity: updates.total_quantity ?? medication.total_quantity,
        is_active: updates.is_active ?? medication.is_active,
        updated_at: new Date().toISOString()
      });

      return medication;
    }

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

  async deleteMedication({ id, userId }) {
    if (useMemoryStore) {
      const medication = memoryStore.medications.find(
        (item) => item.id === Number(id) && (item.user_id === Number(userId) || item.dependent_id === Number(userId))
      );
      if (!medication) return null;
      medication.is_active = false;
      medication.updated_at = new Date().toISOString();
      return medication;
    }

    const { rows } = await queryWithFallback(
      `UPDATE medications
       SET is_active = FALSE, updated_at = NOW()
       WHERE id = $1 AND (user_id = $2 OR dependent_id = $2)
       RETURNING *`,
      [id, userId]
    );

    return rows[0] || null;
  },

  async createSchedule(data) {
    if (useMemoryStore) {
      const schedule = {
        id: memoryStore.schedules.length + 1,
        user_id: data.user_id,
        medication_id: data.medication_id || null,
        days_of_week: data.days_of_week || ['Monday'],
        time_of_day: data.time_of_day || '08:00',
        is_active: data.is_active !== false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      memoryStore.schedules.push(schedule);
      return schedule;
    }

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

  async listSchedules(userId) {
    if (useMemoryStore) {
      return memoryStore.schedules.filter((item) => item.user_id === Number(userId));
    }

    const { rows } = await queryWithFallback('SELECT * FROM schedules WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    return rows;
  },

  async createDoseRecord(data) {
    if (useMemoryStore) {
      const record = {
        id: memoryStore.doseRecords.length + 1,
        user_id: data.user_id,
        medication_id: data.medication_id || null,
        schedule_id: data.schedule_id || null,
        scheduled_time: data.scheduled_time || new Date().toISOString(),
        taken_time: data.taken_time || null,
        status: data.status || 'PENDING',
        dose_taken: Boolean(data.dose_taken),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      memoryStore.doseRecords.push(record);
      return record;
    }

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

  async listDoseRecords(userId) {
    if (useMemoryStore) {
      return memoryStore.doseRecords.filter((item) => item.user_id === Number(userId));
    }

    const { rows } = await queryWithFallback('SELECT * FROM dose_records WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    return rows;
  },

  async updateDoseRecord(id, updates) {
    if (useMemoryStore) {
      const record = memoryStore.doseRecords.find((item) => item.id === Number(id));
      if (!record) return null;
      Object.assign(record, updates, { updated_at: new Date().toISOString() });
      return record;
    }

    const { rows } = await queryWithFallback(
      `UPDATE dose_records SET status = COALESCE($2, status), taken_time = COALESCE($3, taken_time), dose_taken = COALESCE($4, dose_taken), updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [id, updates.status, updates.taken_time || null, updates.dose_taken]
    );
    return rows[0] || null;
  },

  async createNotification(data) {
    if (useMemoryStore) {
      const notification = {
        id: memoryStore.notifications.length + 1,
        user_id: data.user_id,
        type: data.type || 'info',
        title: data.title || 'Reminder',
        body: data.body || '',
        data: data.data || {},
        sent_at: new Date().toISOString(),
        delivered: true
      };
      memoryStore.notifications.push(notification);
      return notification;
    }

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
  pgPool: pool,
  get useMemoryStore() {
    return useMemoryStore;
  }
};