CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_medications_user_id ON medications (user_id);
CREATE INDEX IF NOT EXISTS idx_schedules_user_id ON schedules (user_id);
CREATE INDEX IF NOT EXISTS idx_dose_records_user_id ON dose_records (user_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON notification_logs (user_id);

