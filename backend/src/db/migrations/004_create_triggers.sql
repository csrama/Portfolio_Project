CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_touch_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TRIGGER medications_touch_updated_at
BEFORE UPDATE ON medications
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TRIGGER schedules_touch_updated_at
BEFORE UPDATE ON schedules
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TRIGGER dose_records_touch_updated_at
BEFORE UPDATE ON dose_records
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

