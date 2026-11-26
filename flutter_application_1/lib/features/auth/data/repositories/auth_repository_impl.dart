import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final sessionModel = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      await localDataSource.cacheSession(sessionModel);
      return Right(sessionModel);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Terjadi kesalahan tidak terduga: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final sessionModel = await remoteDataSource.login(
        email: email,
        password: password,
      );
      await localDataSource.cacheSession(sessionModel);
      return Right(sessionModel);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Terjadi kesalahan tidak terduga: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final saved = await localDataSource.getSavedSession();
      if (saved != null && saved.token.isNotEmpty) {
        try {
          await remoteDataSource.logout(saved.token);
        } catch (_) {
          // Tetap bersihkan sesi lokal meski remote server tidak dapat dijangkau
        }
      }
      await localDataSource.clearSession();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Gagal menghapus sesi: $e'));
    }
  }

  @override
  Future<Either<Failure, AuthSession?>> getSavedSession() async {
    try {
      final saved = await localDataSource.getSavedSession();
      return Right(saved);
    } catch (e) {
      return Left(ServerFailure('Gagal membaca sesi lokal: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> getProfile() async {
    try {
      final saved = await localDataSource.getSavedSession();
      if (saved == null || saved.token.isEmpty) {
        return const Left(AuthFailure('Sesi autentikasi tidak ditemukan.'));
      }
      final userModel = await remoteDataSource.getProfile(saved.token);
      // Update saved session user info
      await localDataSource.cacheSession(AuthSessionModel(user: userModel, token: saved.token));
      return Right(userModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Gagal memuat profil: $e'));
    }
  }
}
