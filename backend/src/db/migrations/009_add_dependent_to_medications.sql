SET search_path TO public;


ALTER TABLE medications
ADD COLUMN IF NOT EXISTS dependent_id INTEGER
REFERENCES dependents(id)
ON DELETE CASCADE;


CREATE INDEX IF NOT EXISTS idx_medications_dependent_id
ON medications(dependent_id);