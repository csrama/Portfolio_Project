# TODO - Tracking pills / low stock alerts

## Backend
- [ ] إضافة دالة في `backend/src/db/pool.js` لحساب `remaining_quantity` لكل دواء بناءً على `total_quantity - عدد dose_records حيث dose_taken=true`.
- [ ] إضافة endpoint في `backend/src/routes/medications.js`: `GET /medications/stocks` يرجع قائمة الأدوية مع remaining + low_stock.

## Frontend
- [x] تعديل `frontend/lib/views/dashboard/home_screen.dart` لإضافة قسم/Widget يعرض تنبيهات المخزون المنخفض.

- [ ] (اختياري) إضافة loading/error state للتنبيهات.

## Verification
- [ ] تشغيل backend + اختبار endpoint عبر browser/postman.
- [ ] تشغيل Flutter dashboard والتأكد من ظهور التنبيهات.

