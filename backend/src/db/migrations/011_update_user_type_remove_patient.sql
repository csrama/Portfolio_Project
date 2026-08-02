ALTER TYPE public.user_type_enum RENAME TO user_type_enum_old;

CREATE TYPE public.user_type_enum AS ENUM ('caregiver', 'dependent');

ALTER TABLE users
  ALTER COLUMN user_type DROP DEFAULT,
  ALTER COLUMN user_type TYPE public.user_type_enum
  USING (
    CASE
      WHEN user_type::text = 'patient' THEN 'dependent'
      ELSE user_type::text
    END
  )::public.user_type_enum,
  ALTER COLUMN user_type SET DEFAULT 'dependent';

DROP TYPE public.user_type_enum_old;