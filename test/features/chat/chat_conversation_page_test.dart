import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/chat_widget_test_helpers.dart';

void main() {
  late MockChatBloc mockChatBloc;
  late MockLanguageCubit mockLanguageCubit;

  setUpAll(registerChatWidgetTestFallbacks);

  setUp(() {
    mockChatBloc = createMockChatBloc();
    mockLanguageCubit = createMockLanguageCubit();
  });

  // Widget Test: kiểm tra nút gửi ảnh và gửi tin nhắn hiển thị đúng trên màn chat.
  testWidgets('shows attach-image and send buttons on staff chat screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      buildChatConversationTestWidget(
        chatBloc: mockChatBloc,
        languageCubit: mockLanguageCubit,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhập tin nhắn...'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });
}
