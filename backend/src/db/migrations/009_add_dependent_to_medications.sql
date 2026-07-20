SET search_path TO public;


ALTER TABLE medications
ADD COLUMN IF NOT EXISTS dependent_id INTEGER
REFERENCES users(id)
ON DELETE CASCADE;


ALTER TABLE medications
ADD COLUMN IF NOT EXISTS user_id INTEGER
REFERENCES users(id)
ON DELETE CASCADE;


CREATE INDEX IF NOT EXISTS idx_medications_dependent_id ON medications(dependent_id);
CREATE INDEX IF NOT EXISTS idx_medications_user_id ON medications(user_id);


UPDATE medications 
SET user_id = user_id 
WHERE user_id IS NOT NULL;