import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fretmaster/core/errors/failures.dart';
import 'package:fretmaster/core/usecases/usecase.dart';
import 'package:fretmaster/features/auth/domain/entities/auth_session.dart';
import 'package:fretmaster/features/auth/domain/entities/user.dart';
import 'package:fretmaster/features/auth/domain/usecases/get_saved_session_usecase.dart';
import 'package:fretmaster/features/auth/domain/usecases/login_usecase.dart';
import 'package:fretmaster/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fretmaster/features/auth/domain/usecases/register_usecase.dart';
import 'package:fretmaster/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fretmaster/features/auth/presentation/bloc/auth_event.dart';
import 'package:fretmaster/features/auth/presentation/bloc/auth_state.dart';

class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetSavedSessionUseCase extends Mock implements GetSavedSessionUseCase {}

void main() {
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetSavedSessionUseCase mockGetSavedSessionUseCase;
  late AuthBloc authBloc;

  const tUser = User(id: 1, name: 'Slash', email: 'slash@fretmaster.com');
  const tSession = AuthSession(user: tUser, token: 'mock_token_123');

  setUpAll(() {
    registerFallbackValue(const RegisterParams(name: '', email: '', password: '', passwordConfirmation: ''));
    registerFallbackValue(const LoginParams(email: '', password: ''));
    registerFallbackValue(NoParams());
  });

  setUp(() {
    mockRegisterUseCase = MockRegisterUseCase();
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetSavedSessionUseCase = MockGetSavedSessionUseCase();

    authBloc = AuthBloc(
      registerUseCase: mockRegisterUseCase,
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
      getSavedSessionUseCase: mockGetSavedSessionUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('Initial state must be AuthInitial', () {
    expect(authBloc.state, equals(const AuthInitial()));
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Authenticated] when saved session is present',
      build: () {
        when(() => mockGetSavedSessionUseCase(any()))
            .thenAnswer((_) async => const Right(tSession));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const Authenticated(user: tUser, token: 'mock_token_123'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Unauthenticated] when no saved session exists',
      build: () {
        when(() => mockGetSavedSessionUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const Unauthenticated(),
      ],
    );
  });

  group('AuthLoginSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when login is successful',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => const Right(tSession));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginSubmitted(
        email: 'slash@fretmaster.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthLoading(message: 'Memverifikasi kredensial...'),
        const Authenticated(user: tUser, token: 'mock_token_123'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailureState] when login fails',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Email atau password salah.')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginSubmitted(
        email: 'slash@fretmaster.com',
        password: 'wrongpassword',
      )),
      expect: () => [
        const AuthLoading(message: 'Memverifikasi kredensial...'),
        const AuthFailureState('Email atau password salah.'),
      ],
    );
  });

  group('AuthRegisterSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when register succeeds',
      build: () {
        when(() => mockRegisterUseCase(any()))
            .thenAnswer((_) async => const Right(tSession));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthRegisterSubmitted(
        name: 'Slash',
        email: 'slash@fretmaster.com',
        password: 'password123',
        passwordConfirmation: 'password123',
      )),
      expect: () => [
        const AuthLoading(message: 'Mendaftarkan akun musisi...'),
        const Authenticated(user: tUser, token: 'mock_token_123'),
      ],
    );
  });

  group('AuthLogoutSubmitted', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on logout',
      build: () {
        when(() => mockLogoutUseCase(any()))
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutSubmitted()),
      expect: () => [
        const AuthLoading(message: 'Menghapus sesi...'),
        const Unauthenticated(message: 'Anda telah berhasil logout.'),
      ],
    );
  });
}
