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
  notifications: []
};

function normalizeUserType(userType) {
  if (!userType) {
    return 'general_user';
  }
  return userType === 'patient' ? 'general_user' : userType;
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
    throw new Error('Database unavailable');
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
        normalizeUserType(data.user_type),
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

  async createMedication(data) {
    if (useMemoryStore) {
      const medication = {
        id: memoryStore.medications.length + 1,
        user_id: data.user_id,
        name: data.name,
        dosage: data.dosage || null,
        form: data.form || 'tablet',
        instructions: data.instructions || null,
        color: data.color || null,
        total_quantity: data.total_quantity || 1,
        low_stock_threshold: data.low_stock_threshold || 1,
        is_active: data.is_active !== false,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      };
      memoryStore.medications.push(medication);
      return medication;
    }

    const { rows } = await queryWithFallback(
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
    if (useMemoryStore) {
      return memoryStore.medications.filter((item) => item.user_id === Number(userId));
    }

    const { rows } = await queryWithFallback('SELECT * FROM medications WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    return rows;
  },

  async getMedicationById(id) {
    if (useMemoryStore) {
      return memoryStore.medications.find((item) => item.id === Number(id)) || null;
    }

    const { rows } = await queryWithFallback('SELECT * FROM medications WHERE id = $1', [id]);
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

module.exports = { pool: db, db, normalizeUser };

