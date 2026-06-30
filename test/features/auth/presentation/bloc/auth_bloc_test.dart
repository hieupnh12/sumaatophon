import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sumaatophon/features/auth/domain/entities/user_entity.dart';
import 'package:sumaatophon/features/auth/domain/repositories/auth_repository.dart';
import 'package:sumaatophon/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc - Phone OTP Login', () {
    const testPhone = '0123456789';
    const testOtp = '123456';
    const testUser = UserEntity(
      id: 'test_id',
      name: 'Test User',
      email: 'test@example.com',
      phoneNumber: testPhone,
      role: UserRole.user,
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthOtpSent] when OtpRequested is successful',
      build: () {
        when(() => mockAuthRepository.requestOtp(testPhone))
            .thenAnswer((_) async => Future.value());
        return authBloc;
      },
      act: (bloc) => bloc.add(const OtpRequested(phone: testPhone)),
      expect: () => [
        isA<AuthLoading>(),
        const AuthOtpSent(message: 'login_otp_sent_success'),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.requestOtp(testPhone)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when OtpRequested fails',
      build: () {
        when(() => mockAuthRepository.requestOtp(testPhone))
            .thenThrow(Exception('Network Error'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const OtpRequested(phone: testPhone)),
      expect: () => [
        isA<AuthLoading>(),
        const AuthError(message: 'login_otp_send_error|Network Error'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthenticatedState] when OtpLoginSubmitted is successful',
      build: () {
        when(() => mockAuthRepository.verifyOtp(testPhone, testOtp))
            .thenAnswer((_) async => testUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const OtpLoginSubmitted(phone: testPhone, otp: testOtp)),
      expect: () => [
        isA<AuthLoading>(),
        const AuthenticatedState(testUser),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.verifyOtp(testPhone, testOtp)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when OtpLoginSubmitted fails',
      build: () {
        when(() => mockAuthRepository.verifyOtp(testPhone, testOtp))
            .thenThrow(Exception('Invalid OTP'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const OtpLoginSubmitted(phone: testPhone, otp: testOtp)),
      expect: () => [
        isA<AuthLoading>(),
        const AuthError(message: 'login_otp_verify_error|Invalid OTP'),
      ],
    );
  });
}
