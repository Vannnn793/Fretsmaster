import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class GetSavedSessionUseCase implements UseCase<AuthSession?, NoParams> {
  final AuthRepository repository;

  GetSavedSessionUseCase(this.repository);

  @override
  Future<Either<Failure, AuthSession?>> call(NoParams params) {
    return repository.getSavedSession();
  }
}
