const defaultRemindersEnabled = false;
const defaultReminderOffsetDays = 1;
const reminderOffsetDayOptions = <int>[0, 1, 3, 7];

bool isValidReminderOffsetDays(int value) {
  return reminderOffsetDayOptions.contains(value);
}
