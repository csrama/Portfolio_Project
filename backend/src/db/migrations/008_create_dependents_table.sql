CREATE TABLE IF NOT EXISTS dependents (
  id SERIAL PRIMARY KEY,
  caregiver_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  date_of_birth DATE,
  relationship TEXT NOT NULL,
  profile_image_url TEXT,
  medical_conditions TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE medications
ADD COLUMN dependent_id INTEGER REFERENCES dependents(id) ON DELETE CASCADE;
