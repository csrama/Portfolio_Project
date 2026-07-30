-- ============================================
-- تحديث user_type_enum: إزالة 'patient' والاكتفاء بـ 'caregiver', 'dependent'
-- ============================================

-- تحديث جميع المستخدمين الذين نوعهم 'patient' إلى 'dependent'
UPDATE users SET user_type = 'dependent' WHERE user_type = 'patient';

-- تغيير الـ ENUM
ALTER TYPE public.user_type_enum RENAME TO user_type_enum_old;

CREATE TYPE public.user_type_enum AS ENUM ('caregiver', 'dependent');

ALTER TABLE users 
  ALTER COLUMN user_type DROP DEFAULT,
  ALTER COLUMN user_type TYPE public.user_type_enum 
    USING user_type::text::public.user_type_enum,
  ALTER COLUMN user_type SET DEFAULT 'dependent';

DROP TYPE public.user_type_enum_old;

