import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumaatophon/core/theme/language_cubit.dart';
import 'package:sumaatophon/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:sumaatophon/features/chat/presentation/pages/chat_conversation_page.dart';

import 'chat_test_fixtures.dart';

class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

class MockLanguageCubit extends MockBloc<String, String> implements LanguageCubit {}

class FakeChatEvent extends Fake implements ChatEvent {}

class FakeChatState extends Fake implements ChatState {}

void registerChatWidgetTestFallbacks() {
  registerFallbackValue(FakeChatEvent());
  registerFallbackValue(FakeChatState());
}

MockChatBloc createMockChatBloc() {
  final mockChatBloc = MockChatBloc();
  when(() => mockChatBloc.state).thenReturn(ChatTestFixtures.defaultChatState);
  when(() => mockChatBloc.stream).thenAnswer((_) => const Stream.empty());
  return mockChatBloc;
}

MockLanguageCubit createMockLanguageCubit() {
  final mockLanguageCubit = MockLanguageCubit();
  when(() => mockLanguageCubit.state).thenReturn('vi');
  return mockLanguageCubit;
}

Widget buildChatConversationTestWidget({
  required MockChatBloc chatBloc,
  required MockLanguageCubit languageCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ChatBloc>.value(value: chatBloc),
      BlocProvider<LanguageCubit>.value(value: languageCubit),
    ],
    child: const MaterialApp(
      home: ChatConversationPage(embedded: true),
    ),
  );
}
