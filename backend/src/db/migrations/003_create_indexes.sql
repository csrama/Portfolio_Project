-- Performance indexes for the core tables
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users (user_type);

CREATE INDEX IF NOT EXISTS idx_medications_user_id ON medications (user_id);
CREATE INDEX IF NOT EXISTS idx_medications_is_active ON medications (is_active);

CREATE INDEX IF NOT EXISTS idx_schedules_user_id ON schedules (user_id);
CREATE INDEX IF NOT EXISTS idx_schedules_medication_id ON schedules (medication_id);
CREATE INDEX IF NOT EXISTS idx_schedules_is_active ON schedules (is_active);

CREATE INDEX IF NOT EXISTS idx_dose_records_user_id ON dose_records (user_id);
CREATE INDEX IF NOT EXISTS idx_dose_records_medication_id ON dose_records (medication_id);
CREATE INDEX IF NOT EXISTS idx_dose_records_schedule_id ON dose_records (schedule_id);
CREATE INDEX IF NOT EXISTS idx_dose_records_scheduled_time ON dose_records (scheduled_time);
CREATE INDEX IF NOT EXISTS idx_dose_records_status ON dose_records (status);

CREATE INDEX IF NOT EXISTS idx_notification_logs_user_id ON notification_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_sent_at ON notification_logs (sent_at);

