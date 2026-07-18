import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'medicine_reminders_channel',
          channelName: 'تذكيرات الأدوية',
          channelDescription: 'تذكيرات لمواعيد تناول الأدوية',
          defaultColor: Color(0xFF1D9E75),
          ledColor: Color(0xFF1D9E75),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
        ),
      ],
    );
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
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'medicine_reminders_channel',
        title: 'حان موعد الدواء',
        body: medicineName,
        notificationLayout: NotificationLayout.Default,
        autoDismissible: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'TAKEN',
          label: 'تناولت ✓',
          actionType: ActionType.SilentAction,
          color: Color(0xFF1D9E75),
        ),
        NotificationActionButton(
          key: 'NOT_TAKEN', 
          label: 'لم أتناول ✗',
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
