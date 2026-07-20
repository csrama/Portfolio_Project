DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'dependent_id'
  ) THEN
    ALTER TABLE medications ADD COLUMN dependent_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
  END IF;
END $$;


DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE medications ADD COLUMN user_id INTEGER REFERENCES users(id) ON DELETE CASCADE;
  END IF;
END $$;


DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'type'
  ) THEN
    ALTER TABLE medications ADD COLUMN type INTEGER DEFAULT 0;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'days_of_week'
  ) THEN
    ALTER TABLE medications ADD COLUMN days_of_week TEXT[] DEFAULT ARRAY[]::TEXT[];
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'period'
  ) THEN
    ALTER TABLE medications ADD COLUMN period TEXT DEFAULT 'صباحا';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'time'
  ) THEN
    ALTER TABLE medications ADD COLUMN time TEXT DEFAULT '08:00';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'doses_per_day'
  ) THEN
    ALTER TABLE medications ADD COLUMN doses_per_day INTEGER DEFAULT 1;
  END IF;
END $$;


CREATE INDEX IF NOT EXISTS idx_medications_dependent_id ON medications(dependent_id);
CREATE INDEX IF NOT EXISTS idx_medications_user_id ON medications(user_id);