SET search_path TO public;

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT,
  user_type user_type_enum NOT NULL DEFAULT 'patient',
  age INTEGER,
  sex TEXT,
  medical_condition TEXT,
  is_onboarding_complete BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS medications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  dependent_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  dosage TEXT,
  form TEXT DEFAULT 'tablet',
  instructions TEXT,
  color TEXT,
  total_quantity INTEGER NOT NULL DEFAULT 1,
  low_stock_threshold INTEGER NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  type INTEGER DEFAULT 0,
  days_of_week TEXT[] DEFAULT ARRAY[]::TEXT[],
  period TEXT DEFAULT 'صباحا',
  time TEXT DEFAULT '08:00',
  doses_per_day INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS schedules (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  medication_id INTEGER REFERENCES medications(id) ON DELETE CASCADE,
  days_of_week TEXT[] NOT NULL DEFAULT ARRAY['Monday'],
  time_of_day TEXT NOT NULL DEFAULT '08:00',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS dose_records (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  medication_id INTEGER REFERENCES medications(id) ON DELETE CASCADE,
  schedule_id INTEGER REFERENCES schedules(id) ON DELETE SET NULL,
  scheduled_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  taken_time TIMESTAMPTZ,
  status dose_status_enum NOT NULL DEFAULT 'PENDING',
  dose_taken BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notification_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type notification_type_enum NOT NULL DEFAULT 'medication_reminder',
  title TEXT NOT NULL DEFAULT 'Reminder',
  body TEXT NOT NULL DEFAULT '',
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivered BOOLEAN NOT NULL DEFAULT TRUE
);