import '../errors/failures.dart';

/// Result type for handling success/failure scenarios
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class ResultError<T> extends Result<T> {
  final Failure failure;
  const ResultError(this.failure);
}
