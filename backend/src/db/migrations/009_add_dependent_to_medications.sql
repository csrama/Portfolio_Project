SET search_path TO public;

ALTER TABLE medications
ADD COLUMN IF NOT EXISTS dependent_id INTEGER
REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE medications
ADD COLUMN IF NOT EXISTS type INTEGER DEFAULT 0;

ALTER TABLE medications
ADD COLUMN IF NOT EXISTS days_of_week TEXT[] DEFAULT ARRAY[]::TEXT[];

ALTER TABLE medications
ADD COLUMN IF NOT EXISTS period TEXT DEFAULT 'صباحا';

ALTER TABLE medications
ADD COLUMN IF NOT EXISTS time TEXT DEFAULT '08:00';

ALTER TABLE medications
ADD COLUMN IF NOT EXISTS doses_per_day INTEGER DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_medications_dependent_id ON medications(dependent_id);
CREATE INDEX IF NOT EXISTS idx_medications_user_id ON medications(user_id);