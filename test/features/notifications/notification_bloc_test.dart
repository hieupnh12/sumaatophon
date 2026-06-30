import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumaatophon/features/notifications/presentation/bloc/notification_bloc.dart';

import 'helpers/fake_notification_repository.dart';
import 'helpers/notification_test_fixtures.dart';

void main() {
  late FakeNotificationRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeNotificationRepository();
  });

  // Unit Test: kiểm tra logic đếm thông báo chưa đọc trong NotificationBloc.
  blocTest<NotificationBloc, NotificationState>(
    'loads notifications and calculates unread count',
    build: () {
      when(() => fakeRepository.getNotifications(NotificationTestFixtures.customerId))
          .thenAnswer((_) async => NotificationTestFixtures.loadResult);
      return NotificationBloc(repository: fakeRepository);
    },
    act: (bloc) => bloc.add(
      const LoadNotificationsEvent(customerId: NotificationTestFixtures.customerId),
    ),
    expect: () => [
      isA<NotificationState>().having((s) => s.isLoading, 'loading', true),
      isA<NotificationState>()
          .having((s) => s.items.length, 'items', NotificationTestFixtures.sampleItems.length)
          .having((s) => s.unreadCount, 'unreadCount', NotificationTestFixtures.sampleUnreadCount)
          .having((s) => s.isLoading, 'loading', false),
    ],
  );
}
