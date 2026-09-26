import 'package:dio/dio.dart';
import 'package:flutter/scheduler.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/navigator_key.dart';
import '../core/routes/route_name.dart';
import '../services/storage_service.dart';
import '../utils/app_utils.dart';
import 'api_urls.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  // ------------------------------------------------------------
  // 401-refresh concurrency guard (unchanged from before).
  // ------------------------------------------------------------
  bool _isRefreshing = false;
  final List<Future<void> Function(String newToken)> _pendingRequests = [];

  // ------------------------------------------------------------
  // Force-logout guard. When the employee gets approved on a NEW
  // device, this OLD device's every in-flight/next request comes back
  // 403 DEVICE_NOT_AUTHORIZED — often several at once (dashboard,
  // profile, leave, holidays all firing together). Without this guard
  // each one would independently try to clear storage and navigate,
  // firing pushNamedAndRemoveUntil() multiple times in a row.
  // ------------------------------------------------------------
  bool _isForceLoggingOut = false;

  /// Error codes where retrying or refreshing can NEVER help — the
  /// session is over, full stop, no matter what the access token says.
  /// See the API error-code catalogue: these all mean "log in again".
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
        final errorCode = _extractErrorCode(error);
        final errorMessage = _extractErrorMessage(error);

        // ---- Case 1: fatal — this device/account is done. ----
        // Runs BEFORE the 401-only check below because
        // DEVICE_NOT_AUTHORIZED actually comes back as 403, not 401 —
        // it would never have been caught by the old-token-refresh
        // logic at all, which is exactly why every screen was just
        // silently failing instead of logging the employee out.
        if (_fatalErrorCodes.contains(errorCode)) {
          await _forceLogout(message: errorMessage);
          return handler.next(error);
        }

        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (!isUnauthorized || alreadyRetried) {
          return handler.next(error);
        }

        // ---- Case 2: expired access token — try refreshing once. ----
        if (_isRefreshing) {
          _pendingRequests.add((newToken) async {
            final retried = await _retryWithNewToken(
              error.requestOptions,
              newToken,
            );
            handler.resolve(retried);
          });
          return;
        }

        _isRefreshing = true;
        try {
          final newToken = await _refreshAccessToken();

          if (newToken == null) {
            // Refresh token is dead too — this really is the end of
            // the session. Same treatment as a fatal error code.
            _pendingRequests.clear();
            await _forceLogout();
            return handler.next(error);
          }

          for (final callback in _pendingRequests) {
            await callback(newToken);
          }
          _pendingRequests.clear();

          final retried = await _retryWithNewToken(
            error.requestOptions,
            newToken,
          );
          handler.resolve(retried);
        } catch (_) {
          _pendingRequests.clear();
          handler.next(error);
        } finally {
          _isRefreshing = false;
        }
      },
    );
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

  /// The ONE place that decides "this employee is logged out, full
  /// stop" — clears every saved token/session value, then throws them
  /// back to Login with the ENTIRE navigation stack wiped
  /// (`pushNamedAndRemoveUntil`), so the back button can never return
  /// to a screen that needs a session that no longer exists.
  ///
  /// Works from anywhere — Dashboard, Profile, a leave form mid-fill —
  /// because it goes through the global `navigatorKey`, not a
  /// BuildContext handed down from a specific screen.
  Future<void> _forceLogout({String? message}) async {
    if (_isForceLoggingOut) return;
    _isForceLoggingOut = true;

    await StorageService().clearSession();

    final navState = navigatorKey.currentState;
    if (navState != null) {
      navState.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);

      // Wait one frame so the Login screen's own Scaffold exists
      // before we try to show a SnackBar on top of it.
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

    _isForceLoggingOut = false;
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

      // Plain Dio instance — deliberately NOT `dio` above — so a 401 on
      // this call doesn't re-trigger this same interceptor and loop.
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