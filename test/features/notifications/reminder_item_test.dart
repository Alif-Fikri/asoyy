import 'package:asoyy/features/debt/domain/entities/debt_entity.dart';
import 'package:asoyy/features/notifications/domain/reminder_item.dart';
import 'package:asoyy/features/split_bill/domain/entities/bill_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = Color(0xFFFF0000);

List<ReminderItem> build({
  List<BillEntity> bills = const [],
  List<DebtEntity> debts = const [],
  required DateTime now,
}) =>
    buildReminders(
      alarms: const [],
      events: const [],
      holidays: const [],
      paydayDay: null,
      recurringBills: const [],
      splitBills: bills,
      debts: debts,
      now: now,
      alarmColor: _red,
      holidayColor: _red,
      paydayColor: _red,
      recurringBillColor: _red,
      debtColor: _red,
      paydayLabel: 'Gajian',
      isId: true,
    );

BillEntity billWith(List<ParticipantEntity> participants, DateTime date) =>
    BillEntity(
      id: 'bill1',
      title: 'MakanMalam',
      totalAmount: participants.fold(0, (s, p) => s + p.amount),
      date: date,
      participants: participants,
      splitEqually: true,
    );

DebtEntity linkedDebt({
  String id = 'd1',
  String person = 'Sari',
  String? note = 'MakanMalam',
  bool settled = false,
  required DateTime date,
}) =>
    DebtEntity(
      id: id,
      personName: person,
      amount: 75000,
      direction: DebtDirection.theyOweMe,
      note: note,
      date: date,
      isSettled: settled,
      sourceBillId: 'bill1',
      sourceParticipantId: 'p2',
    );

void main() {
  final now = DateTime(2026, 9, 14, 14);
  final billDate = DateTime(2026, 9, 14);

  group('a bill participant tracked as a debt', () {
    final participants = [
      const ParticipantEntity(id: 'p1', name: 'Budi', amount: 75000, isPaid: true),
      const ParticipantEntity(id: 'p2', name: 'Sari', amount: 75000),
    ];

    test('is reminded once, not twice', () {
      final items = build(
        bills: [billWith(participants, billDate)],
        debts: [linkedDebt(date: billDate)],
        now: now,
      );

      expect(items, hasLength(1));
      expect(items.single.id, 'debt-d1');
    });

    test('keeps the bill name in the reminder title', () {
      final items = build(
        bills: [billWith(participants, billDate)],
        debts: [linkedDebt(date: billDate)],
        now: now,
      );
      expect(items.single.title, 'Sari · MakanMalam');
    });

    test('falls back to the participant reminder when no debt exists', () {
      final items = build(
        bills: [billWith(participants, billDate)],
        now: now,
      );

      expect(items, hasLength(1));
      expect(items.single.id, 'bill-bill1-p2');
      expect(items.single.title, 'Sari · MakanMalam');
    });

    test('a settled debt leaves nothing behind', () {
      final items = build(
        bills: [billWith(participants, billDate)],
        debts: [linkedDebt(date: billDate, settled: true)],
        now: now,
      );
      expect(items, isEmpty);
    });

    test('a participant who paid is never reminded', () {
      final items = build(
        bills: [
          billWith(
            [
              const ParticipantEntity(
                  id: 'p1', name: 'Budi', amount: 75000, isPaid: true),
            ],
            billDate,
          )
        ],
        now: now,
      );
      expect(items, isEmpty);
    });

    test('a debt from another bill does not hide this participant', () {
      final items = build(
        bills: [billWith(participants, billDate)],
        debts: [
          DebtEntity(
            id: 'other',
            personName: 'Sari',
            amount: 75000,
            direction: DebtDirection.theyOweMe,
            date: billDate,
            sourceBillId: 'bill-lain',
            sourceParticipantId: 'p2',
          ),
        ],
        now: now,
      );

      expect(items.map((i) => i.id), containsAll(['bill-bill1-p2', 'debt-other']));
    });
  });

  group('a debt without a bill behind it', () {
    test('shows just the person when there is no note', () {
      final items = build(
        debts: [
          DebtEntity(
            id: 'd9',
            personName: 'Andi',
            amount: 50000,
            direction: DebtDirection.iOwe,
            date: billDate,
          ),
        ],
        now: now,
      );
      expect(items.single.title, 'Andi');
    });
  });

  group('reminders that have already passed', () {
    test('a timed reminder in the past is dropped', () {
      final items = buildReminders(
        alarms: const [],
        events: const [],
        holidays: const [],
        paydayDay: null,
        recurringBills: const [],
        splitBills: const [],
        debts: const [],
        now: now,
        alarmColor: _red,
        holidayColor: _red,
        paydayColor: _red,
        recurringBillColor: _red,
        debtColor: _red,
        paydayLabel: 'Gajian',
        isId: true,
      );
      expect(items, isEmpty);
    });

    test('every reminder returned is still ahead of now', () {
      final items = build(
        bills: [
          billWith(
            [const ParticipantEntity(id: 'p1', name: 'Budi', amount: 10000)],
            DateTime(2026, 8, 1),
          )
        ],
        debts: [linkedDebt(id: 'd2', date: DateTime(2026, 7, 1), note: null)],
        now: now,
      );

      for (final item in items) {
        expect(item.when.isBefore(now), isFalse, reason: item.title);
      }
    });

    test('the list comes back in time order', () {
      final items = build(
        bills: [
          billWith(
            [
              const ParticipantEntity(id: 'p1', name: 'Budi', amount: 1),
              const ParticipantEntity(id: 'p3', name: 'Cici', amount: 1),
            ],
            billDate,
          )
        ],
        debts: [linkedDebt(id: 'd3', date: DateTime(2026, 9, 13))],
        now: now,
      );

      for (var i = 1; i < items.length; i++) {
        expect(items[i].when.isBefore(items[i - 1].when), isFalse);
      }
    });
  });
}
