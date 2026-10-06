import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/navigator_key.dart';
import '../core/routes/route_name.dart';
import '../services/storage_service.dart';
import '../utils/app_utils.dart';
import 'api_urls.dart';

class _PendingRequest {
  final RequestOptions options;
  final DioException error;
  final ErrorInterceptorHandler handler;

  _PendingRequest(this.options, this.error, this.handler);
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];
  // Force-logout guard. Ek hi baar logout + navigation hona chahiye,
  bool _isForceLoggingOut = false;
  static const Set<String> _fatalErrorCodes = {
    'DEVICE_NOT_AUTHORIZED',
    'ACCOUNT_INACTIVE',
    'EMPLOYEE_INACTIVE',
  };

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiUrls.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: const {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      ),
    );

    dio.interceptors.addAll([
      _authInterceptor(),
      if (!const bool.fromEnvironment('dart.vm.product'))
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
        ),
    ]);
  }

  /// Login / refresh-token ke errors session-expiry nahi hote —
  bool _isAuthEndpoint(RequestOptions options) {
    final path = options.path;
    return path.contains(ApiUrls.login) || path.contains(ApiUrls.refreshToken);
  }

  /// Kya ye request token ke saath gayi thi?
  bool _hadAuthHeader(RequestOptions options) {
    final auth = options.headers["Authorization"];
    return auth != null && auth.toString().isNotEmpty;
  }

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers["Authorization"] = "Bearer $token";
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        final req = error.requestOptions;
        if (_isAuthEndpoint(req)) {
          return handler.next(error);
        }
        if (!_hadAuthHeader(req)) {
          return handler.next(error);
        }
        final errorCode = _extractErrorCode(error);
        final errorMessage = _extractErrorMessage(error);
        if (_fatalErrorCodes.contains(errorCode)) {
          final isFcmTokenRequest =
          req.path.contains('/notifications/fcm-token');

          if (!isFcmTokenRequest) {
            await _forceLogout(message: errorMessage);
          }
          return handler.next(error);
        }
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = req.extra['retried'] == true;
        if (!isUnauthorized || alreadyRetried) {
          return handler.next(error);
        }
        if (_isRefreshing) {
          _pendingRequests.add(_PendingRequest(req, error, handler));
          return;
        }

        _isRefreshing = true;
        try {
          final newToken = await _refreshAccessToken();
          if (newToken == null) {
            _failPendingRequests();
            await _forceLogout();
            return handler.next(error);
          }
          final pending = List<_PendingRequest>.from(_pendingRequests);
          _pendingRequests.clear();
          for (final p in pending) {
            try {
              final retried = await _retryWithNewToken(p.options, newToken);
              p.handler.resolve(retried);
            } on DioException catch (e) {
              p.handler.next(e);
            } catch (_) {
              p.handler.next(p.error);
            }
          }
          try {
            final retried = await _retryWithNewToken(req, newToken);
            handler.resolve(retried);
          } on DioException catch (e) {
            handler.next(e);
          }
        } catch (_) {
          _failPendingRequests();
          handler.next(error);
        } finally {
          _isRefreshing = false;
        }
      },
    );
  }

  void _failPendingRequests() {
    final pending = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    for (final p in pending) {
      p.handler.next(p.error);
    }
  }

  String? _extractErrorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorBlock = data['error'];
      if (errorBlock is Map<String, dynamic>) {
        return errorBlock['code']?.toString();
      }
    }
    return null;
  }

  String? _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorBlock = data['error'];
      if (errorBlock is Map<String, dynamic>) {
        return errorBlock['message']?.toString();
      }
    }
    return null;
  }

  Future<void> _forceLogout({String? message}) async {
    if (_isForceLoggingOut) return;
    _isForceLoggingOut = true;

    try {
      final stillLoggedIn = await StorageService().isLoggedIn();
      if (!stillLoggedIn) return;

      await StorageService().clearSession();

      final navState = navigatorKey.currentState;
      if (navState != null) {
        navState.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          final ctx = navigatorKey.currentContext;
          if (ctx != null) {
            AppUtils.showErrorSnackbar(
              ctx,
              message ??
                  "You've been logged out because this device is no longer authorized.",
            );
          }
        });
      }
    } finally {
      _isForceLoggingOut = false;
    }
  }

  Future<Response<dynamic>> _retryWithNewToken(
      RequestOptions options,
      String newToken,
      ) {
    options.headers["Authorization"] = "Bearer $newToken";
    options.extra['retried'] = true;
    return dio.fetch(options);
  }

  Future<String?> _getAccessToken() async {
    return StorageService().getAccessToken();
  }

  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await StorageService().getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return null;
      final plainDio = Dio(BaseOptions(baseUrl: ApiUrls.baseUrl));
      final response = await plainDio.post(
        ApiUrls.refreshToken,
        data: {"refresh_token": refreshToken},
      );

      final data = response.data;
      if (data is! Map<String, dynamic> || data['data'] is! Map) return null;
      final newAccessToken = data['data']['access_token'] as String?;
      if (newAccessToken == null || newAccessToken.isEmpty) return null;
      await StorageService().saveAccessToken(newAccessToken);
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }
}