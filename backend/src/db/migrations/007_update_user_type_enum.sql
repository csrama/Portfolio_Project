DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumtypid = 'user_type_enum'::regtype 
    AND enumlabel = 'dependent'
  ) THEN
    ALTER TYPE user_type_enum ADD VALUE 'dependent';
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'relationship_enum') THEN
    CREATE TYPE relationship_enum AS ENUM ('spouse', 'child', 'parent', 'sibling', 'other');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invitation_status_enum') THEN
    CREATE TYPE invitation_status_enum AS ENUM ('pending', 'accepted', 'rejected');
  END IF;
END
$$;