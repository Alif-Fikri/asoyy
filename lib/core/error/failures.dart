abstract class Failure {
  final String message;
  const Failure(this.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Item not found']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
