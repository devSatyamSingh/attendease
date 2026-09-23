import 'package:dio/dio.dart';
import '../errors/failure.dart';


Failure handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
      return const TimeoutFailure(message: "Connection timed out. Please try again.");

    case DioExceptionType.receiveTimeout:
      return const TimeoutFailure(message: "Server is taking too long to respond.");

    case DioExceptionType.connectionError:
      return const NetworkFailure();

    case DioExceptionType.cancel:
      return const UnknownFailure(message: "Request was cancelled.");

    case DioExceptionType.badCertificate:
      return const NetworkFailure(message: "Secure connection failed. Please try again.");

    case DioExceptionType.badResponse:
      return _mapBadResponse(error);

    case DioExceptionType.unknown:
    default:
      return const NetworkFailure(message: "Unable to connect. Please check your internet.");
  }
}

Failure _mapBadResponse(DioException error) {
  final int? statusCode = error.response?.statusCode;
  final dynamic data = error.response?.data;

  String? code;
  String? message;

  if (data is Map<String, dynamic>) {
    final errorBlock = data['error'];
    if (errorBlock is Map<String, dynamic>) {
      code = errorBlock['code']?.toString();
      message = errorBlock['message']?.toString();
    } else {
      message = data['message']?.toString();
    }
  }

  if (code != null) {
    return FailureMapper.fromErrorCode(
      code,
      fallbackMessage: message,
      statusCode: statusCode,
    );
  }

  // No structured error body from backend — fall back to HTTP status.
  switch (statusCode) {
    case 401:
      return AuthFailure(
        message: message ?? "Session expired. Please log in again.",
        statusCode: statusCode,
      );
    case 403:
      return AuthFailure(
        message: message ?? "You don't have permission to do this.",
        statusCode: statusCode,
      );
    case 404:
      return ServerFailure(
        message: message ?? "Requested data was not found.",
        statusCode: statusCode,
      );
    case 409:
      return ServerFailure(
        message: message ?? "This action conflicts with existing data.",
        statusCode: statusCode,
      );
    case 422:
      return ValidationFailure(
        message: message ?? "Please check the details you entered.",
        statusCode: statusCode,
      );
    case 500:
    case 502:
    case 503:
      return ServerFailure(
        message: "Server is currently unavailable. Please try again later.",
        statusCode: statusCode,
      );
    default:
      return ServerFailure(
        message: message ?? "Something went wrong. Please try again.",
        statusCode: statusCode,
      );
  }
}

class ApiException implements Exception {
  final String message;
  final String? code;

  const ApiException(this.message, {this.code});

  @override
  String toString() => "ApiException: $message";
}