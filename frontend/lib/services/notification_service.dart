import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static String _isArabic = 'ar';

  /// Call this to update the language preference before scheduling
  static void setLanguage(String languageCode) {
    _isArabic = languageCode;
  }

  static Future<void> init() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'medicine_reminders_channel',
        channelName: _isArabic == 'ar'
            ? 'تذكيرات الأدوية'
            : 'Medicine Reminders',
        channelDescription: _isArabic == 'ar'
            ? 'تذكيرات لمواعيد تناول الأدوية'
            : 'Medication reminders',
        defaultColor: Color(0xFF1D9E75),
        ledColor: Color(0xFF1D9E75),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
      ),
    ]);
  }

  static Future<void> requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  static Future<void> scheduleMedicineReminder({
    required int id,
    required String medicineName,
    required int hour,
    required int minute,
  }) async {
    final title = _isArabic == 'ar' ? 'حان موعد الدواء' : 'Medicine time';
    final takenLabel = _isArabic == 'ar' ? 'تناولت ✓' : 'Taken ✓';
    final notTakenLabel = _isArabic == 'ar' ? 'لم أتناول ✗' : "Didn't take ✗";

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'medicine_reminders_channel',
        title: title,
        body: medicineName,
        notificationLayout: NotificationLayout.Default,
        autoDismissible: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'TAKEN',
          label: takenLabel,
          actionType: ActionType.SilentAction,
          color: Color(0xFF1D9E75),
        ),
        NotificationActionButton(
          key: 'NOT_TAKEN',
          label: notTakenLabel,
          actionType: ActionType.SilentAction,
          color: Color(0xFFB85C5C),
        ),
      ],
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
