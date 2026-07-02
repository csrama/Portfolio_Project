-- Enums used by the medication management backend
CREATE SCHEMA IF NOT EXISTS public;
SET search_path TO public, pg_catalog;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA public;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type_enum') THEN
    CREATE TYPE public.user_type_enum AS ENUM ('patient', 'caregiver', 'doctor');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dose_status_enum') THEN
    CREATE TYPE dose_status_enum AS ENUM ('PENDING', 'TAKEN', 'MISSED', 'SKIPPED');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
    CREATE TYPE notification_type_enum AS ENUM ('medication_reminder', 'missed_dose', 'low_stock', 'adherence_report', 'caregiver_alert');
  END IF;
END
$$;

