DROP TABLE IF EXISTS dependents CASCADE;

CREATE TABLE IF NOT EXISTS dependents (
  id SERIAL PRIMARY KEY,
  caregiver_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  dependent_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  date_of_birth DATE,
  relationship TEXT NOT NULL CHECK (relationship IN ('spouse', 'child', 'parent', 'sibling', 'other')),
  profile_image_url TEXT,
  medical_conditions TEXT[] DEFAULT ARRAY[]::TEXT[],
  invitation_status TEXT NOT NULL DEFAULT 'pending' CHECK (invitation_status IN ('pending', 'accepted', 'rejected')),
  invitation_token TEXT UNIQUE,
  invited_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(caregiver_user_id, dependent_user_id)
);

CREATE INDEX IF NOT EXISTS idx_dependents_caregiver ON dependents(caregiver_user_id);
CREATE INDEX IF NOT EXISTS idx_dependents_dependent ON dependents(dependent_user_id);
CREATE INDEX IF NOT EXISTS idx_dependents_invitation_token ON dependents(invitation_token);