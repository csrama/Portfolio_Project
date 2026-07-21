# Bug Fixes TODO

## ✅ Bugs Fixed

1. ✅ **`_MedicationCard` constructor malformed** - Fixed the invalid initializer list (`: showDoseActions = false : selectedDate : ...`) to proper parameter defaults with commas
2. ✅ **Missing dependencies in pubspec.yaml** - Added `http`, `shared_preferences`, `provider`, `app_links`, `awesome_notifications`
3. ✅ **Duplicate `assets:` key in pubspec.yaml** - Fixed YAML structure
4. ✅ **Empty `adherence_service.dart`** - Implemented with `getAdherenceRate()` and `getDoseLogs()` methods
5. ✅ **Wrong import path in `main.dart`** - Changed `package:frontend/services/notification_service.dart` to relative import

## Progress
- [x] 1. Fix `_MedicationCard` constructor in home_screen.dart
- [x] 2. Fix pubspec.yaml (dependencies + assets)
- [x] 3. Implement adherence_service.dart
- [ ] 4. Run flutter pub get
- [ ] 5. Run flutter analyze to verify
- [ ] 6. Launch the app

