sealed class Result<T, E> {
  const Result();

  factory Result.success(T data) => Success(data);
  factory Result.failure(E error) => Failure(error);

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(E error) onFailure,
  }) =>
      switch (this) {
        Success<T, E>(:final data) => onSuccess(data),
        Failure<T, E>(:final error) => onFailure(error),
      };
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.data);
  final T data;
}

final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  final E error;
}
