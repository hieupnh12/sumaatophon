import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumaatophon/core/theme/theme_cubit.dart';
import 'package:sumaatophon/core/theme/language_cubit.dart';
import 'package:sumaatophon/core/l10n/app_localizations.dart';
import 'package:sumaatophon/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sumaatophon/features/auth/presentation/pages/login_page.dart';


class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockThemeCubit extends MockBloc<ThemeMode, ThemeMode> implements ThemeCubit {}
class MockLanguageCubit extends MockBloc<String, String> implements LanguageCubit {}

// Fake event
class FakeAuthEvent extends Fake implements AuthEvent {}
class FakeAuthState extends Fake implements AuthState {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;
  late MockLanguageCubit mockLanguageCubit;

  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeAuthState());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();
    mockLanguageCubit = MockLanguageCubit();

    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockThemeCubit.state).thenReturn(ThemeMode.light);
    when(() => mockLanguageCubit.state).thenReturn('vi');
  });

  Widget createWidgetUnderTest() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
        BlocProvider<LanguageCubit>.value(value: mockLanguageCubit),
      ],
      child: const MaterialApp(

        supportedLocales: [Locale('vi'), Locale('en'), Locale('ja')],
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders phone input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find phone input by icon (Icons.phone) or Type
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows error snackbar when phone is empty and continue is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assuming there is an ElevatedButton or a GestureDetector for the continue button.
      // We look for a button containing the text "Tiếp tục" or similar, or find by type.
      // Since it's a bit complex with localization, we find the primary button.
      final continueButton = find.byType(ElevatedButton).first;
      await tester.tap(continueButton);
      await tester.pump(); // trigger snackbar

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('adds OtpRequested event when valid phone is entered and continued', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final phoneInput = find.byType(TextFormField);
      await tester.enterText(phoneInput, '0987654321');
      await tester.pumpAndSettle();

      final continueButton = find.byType(ElevatedButton).first;
      await tester.tap(continueButton);
      await tester.pump();

      verify(() => mockAuthBloc.add(const OtpRequested(phone: '0987654321'))).called(1);
    });
  });
}
