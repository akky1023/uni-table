import 'schedule.dart';

class DeadlineChoice {
  final DateTime date;
  final DbRow slot;
  final Session? session;
  const DeadlineChoice(this.date, this.slot, {this.session});
  factory DeadlineChoice.fromSession(Session session) =>
      DeadlineChoice(session.date, session.slot, session: session);
  DateTime get start => atMinute(date, slot['start_minute'] as int);
}
