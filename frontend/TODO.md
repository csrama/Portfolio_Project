# Fix Plan - Dart/Flutter Compilation Errors

## ✅ File 1: `app_settings_provider.dart`
- [x] Remove `Null get SharedPreferences => null`
- [x] Add proper imports (`shared_preferences`, `flutter/material.dart`)
- [x] Remove all stub/fake classes at bottom
- [x] Remove empty `notifyListeners()` override

## ✅ File 2: `auth_repository.dart`
- [x] Remove `Null get SharedPreferences => null`
- [x] Add `import 'package:shared_preferences/shared_preferences.dart';`

## ✅ File 3: `main.dart`
- [x] Fix `main()` function to properly call `WidgetsFlutterBinding.ensureInitialized()` and `runApp()`
- [x] Remove all stub classes at bottom
- [x] Add proper imports

## ✅ File 4: `home_screen.dart` (largest file)
- [x] Remove all "Stashed changes" text artifacts (~20+ locations)
- [x] Remove duplicate method definitions
- [x] Fix duplicate properties in SnackBar/ElevatedButton calls
- [x] Move `_MedicationCard`, `_AddMedicationSheet`, `_AddMedicationSheetState` to top-level
- [x] Fix `_dosePeriodLabel` usage order
- [x] Fix `DropdownButtonFormField` `initialValue` → `value`

