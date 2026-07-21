# Bug Fixes TODO

## ✅ Bugs Identified

### File: `frontend/lib/views/dashboard/home_screen.dart`
1. **`_getGreeting()` is malformed** - contains leftover code from `_medicationsForDate()`
2. **`_medicationsForDate()` is MISSING** - needed for filtering meds by day
3. **`_arabicDigits()` is MISSING** - needed for Arabic numeral display
4. **`_weekdayNameFromDate()` is MISSING** - needed for Arabic weekday names
5. **`fetchDependents()` never called in initState** - dependent list stays empty

### File: `frontend/lib/main.dart`
6. **app_links v6.4.1 API changed** - `getInitialLink()` returns `Uri?` not `String`, and `linkStream` is now `uriStream`

## Progress
- [ ] 1. Fix `_getGreeting()` + add `_medicationsForDate()`
- [ ] 2. Add `_arabicDigits()` + `_weekdayNameFromDate()`
- [ ] 3. Add `_loadDependents()` call in initState
- [ ] 4. Fix `main.dart` app_links API
- [ ] 5. Run flutter pub get
- [ ] 6. Run flutter analyze to verify
- [ ] 7. Launch the app

