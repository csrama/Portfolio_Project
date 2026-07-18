SET search_path TO public;

-- نوع الدواء
ALTER TABLE medications
ADD COLUMN IF NOT EXISTS type INTEGER NOT NULL DEFAULT 0;

-- أيام الأسبوع
ALTER TABLE medications
ADD COLUMN IF NOT EXISTS days_of_week TEXT[] DEFAULT ARRAY[]::TEXT[];

-- الفترة (صباحاً، مساءً...)
ALTER TABLE medications
ADD COLUMN IF NOT EXISTS period TEXT DEFAULT 'صباحا';

-- وقت الجرعة
ALTER TABLE medications
ADD COLUMN IF NOT EXISTS time TEXT DEFAULT '08:00';

-- عدد الجرعات في اليوم
ALTER TABLE medications
ADD COLUMN IF NOT EXISTS doses_per_day INTEGER NOT NULL DEFAULT 1;