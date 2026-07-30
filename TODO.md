# TODO - تغيير واجهة إضافة التابع

## المهام
- [x] الموافقة على الخطة
- [x] 1. تعديل `backend/src/routes/dependents.js` - إضافة دعم `date_of_birth` + إزالة `caregiverCheck`
- [x] 2. تعديل `frontend/lib/views/dashboard/add_dependent_screen.dart` - إزالة وضعي الاختيار، إضافة العمر، إزالة توليد الرابط
- [x] 3. تعديل `frontend/lib/views/dashboard/dependents_screen.dart` - تعديل `_showAddDependentSheet` لحقول: الاسم، البريد، كلمة المرور، العمر، العلاقة
- [x] 4. تعديل `frontend/lib/services/dependent_service.dart` - إضافة `dateOfBirth` وتصحيح endpoint إلى `/dependents/create-with-account`
- [x] 5. تعديل `frontend/lib/providers/dependent_provider.dart` - إضافة `dateOfBirth` إلى `addNewDependent`
- [x] 6. تعديل `frontend/lib/views/dashboard/dependents_screen.dart` - تمرير `dateOfBirth` إلى `addNewDependent`

## ✅ تم الانتهاء من جميع التعديلات بنجاح

