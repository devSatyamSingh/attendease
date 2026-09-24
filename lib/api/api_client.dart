import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../core/constants/app_constants.dart';
import '../services/storage_service.dart';
import 'api_urls.dart';

/// AttendEase — singleton Dio client.
///
/// Never create `Dio()` anywhere else in the app — always go through
/// `ApiClient().dio`. That's what makes token-attach, logging, and
/// 401-refresh-and-retry work everywhere automatically, for every
/// single request, without a repository ever thinking about it.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  // ------------------------------------------------------------
  // 401-refresh concurrency guard.
  // If 5 API calls fire at once and the token has expired, all 5 get
  // a 401 back roughly together. Without this guard each one would
  // independently try to refresh the token — 5 refresh calls racing
  // each other, and the backend would likely reject 4 of them,
  // logging the user out for no reason. Instead: the FIRST 401 starts
  // a refresh; every other 401 that arrives while that refresh is
  // still in flight gets queued and is automatically retried with the
  // new token once it's ready.
  // ------------------------------------------------------------
  bool _isRefreshing = false;
  final List<Future<void> Function(String newToken)> _pendingRequests = [];

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
      // Logs every request/response — only in debug builds, never in
      // a release build (keeps tokens and response bodies out of
      // production logs).
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
        final isUnauthorized = error.response?.statusCode == 401;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        // Not a 401, or we already retried this exact request once
        // (and it STILL failed) -> stop here, let it surface as a
        // normal Failure via handleDioError.
        if (!isUnauthorized || alreadyRetried) {
          return handler.next(error);
        }

        // A refresh is already running -> queue this request instead
        // of starting a second refresh call.
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
            // Refresh token itself is invalid/expired.
            _pendingRequests.clear();
            // TODO: force logout — clear StorageService tokens and
            // navigate to Login (e.g. via a global navigatorKey, since
            // an interceptor has no BuildContext of its own).
            return handler.next(error);
          }

          // Replay every request that queued up while we refreshed.
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

  Future<Response<dynamic>> _retryWithNewToken(
      RequestOptions options,
      String newToken,
      ) {
    options.headers["Authorization"] = "Bearer $newToken";
    // Marks this request so a second 401 on the SAME request doesn't
    // loop forever trying to refresh again.
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

      // Backend only rotates the access_token on refresh — the
      // refresh_token itself stays the same, so we don't overwrite it.
      await StorageService().saveAccessToken(newAccessToken);
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }
}