*Task 1 (new command to create the whole project)
- use 'flutter create project --platforms android,ios  <project_name>'

- use 'flutter pub add <package_name>' to add the needed packages

- use our feature_cli command to creat lib 



*Task 2 (update some files and create new files in the lib creating command)
 
 - update the main file to be like this
 import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:torento/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:torento/features/homelayout/presentation/bloc/homelayout_bloc.dart';
import 'package:torento/features/profile/presentation/bloc/profile_bloc.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/di/injector.dart';
import 'core/local/user_hive_helper.dart';
import 'core/utils/bloc_observer.dart';
import 'core/utils/screen_util_like.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/booking/presentation/bloc/booking_bloc.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  await UserHiveHelper.init(); // Initialize Hive and default user
  // Initialize dependencies
  await setupInjector();
  runApp(const TorentoApp());
}

class TorentoApp extends StatelessWidget {
  // Static navigator key
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const TorentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => injector<AuthBloc>()),
        BlocProvider(create: (_) => injector<HomelayoutBloc>()),
        BlocProvider(create: (_) => injector<ProfileBloc>()),
        BlocProvider(create: (_) => injector<BookingBloc>()),
        BlocProvider(create: (_) => injector<ChatBloc>()),
        // Add other global BLoCs here
      ],
      child: ValueListenableBuilder(
        valueListenable: UserHiveHelper.getBoxListenable(),
        builder: (context, box, child) {
          final user = UserHiveHelper.getUser();
          final locale = user?.language ?? 'ar';

          return SafeArea(
            top: false,
            child: MaterialApp(
              navigatorKey: TorentoApp.navigatorKey, // Assign the key
              title: 'Torento',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              initialRoute: AppRoutes.splash,
              locale: Locale(locale),
              themeMode: ThemeMode.light, // Or control this with a BLoC
              onGenerateRoute: AppRouter.onGenerateRoute,
              builder: (context, child) {
                if (child != null) {
                  ScreenUtil.init(context: context);
                }
                return child!;
              },
            ),
          );
        },
      ),
    );
  }
}
for the hive listener and etc...

- update the dio client to be like this 
import 'dart:developer';
import 'package:bel3lm/features/authentication/data/models/user_hive_helper.dart';
import 'package:dio/dio.dart';
import '../../config/routes/app_router.dart';
import '../../main.dart';
import '../utils/extensions/context_extensions.dart';
import '../utils/flutter_secure_storage_helper.dart';
import 'api_consumer.dart';
import '../error/exceptions.dart';
import '../constants/app_constants.dart';
import '../utils/snackbar_helper.dart';

class DioClient implements ApiConsumer {
  final Dio dio;

  DioClient(this.dio) {
    dio.options
      ..baseUrl = AppConstants.baseUrl
      ..responseType = ResponseType.json
      ..connectTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers = {
        'accept': 'application/json',
        'content-type': 'application/json',
        'app-lang': UserHiveHelper.getUser()?.language ?? 'en',
      };

    // --- ADVANCED LOGGING & AUTH INTERCEPTOR ---
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await FlutterSecureStorageHelper.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            log('🚀 [AUTH] Bearer $token');
          }

          log('🚀 [REQUEST] [${options.method}] URL: ${options.uri}');
          if (options.data != null) {
            if (options.data is Future<FormData> || options.data is FormData) {
              final formData = await options.data as FormData;
              final fields = formData.fields
                  .map((e) => '${e.key}: ${e.value}')
                  .toList();
              final files = formData.files
                  .map((e) => '${e.key}: ${e.value.filename}')
                  .toList();

              log('📦 [FORM DATA FIELDS]: $fields');
              log('📂 [FORM DATA FILES]: $files');
            } else {
              log('📦 [BODY]: ${options.data}');
            }
          }
          if (options.queryParameters.isNotEmpty) {
            log('❓ [QUERY PARAMS]: ${options.queryParameters}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          log(
            '✅ [RESPONSE] [${response.statusCode}] FROM: ${response.requestOptions.path}',
          );
          log('📄 [DATA]: ${response.data}');

          // Show global success snackbar if a valid string 'message' is present
          if (response.data is Map && response.data['message'] != null) {
            final message = response.data['message'];
            if (message is String && message.isNotEmpty) {
              // Avoid showing it on pure GET requests if they just return a dataset without a success "message" field
              // But if the backend explicitly sends {"message": "Success"}, we show it.
              final context = Bel3lmApp.navigatorKey.currentContext;
              if (context != null && response.requestOptions.method != 'GET') {
                SnackbarHelper.showSuccess(context, message: message);
              }
            }
          }

          return handler.next(response);
        },
        onError: (DioException e, handler) {
          log('❌ [ERROR] [${e.response?.statusCode ?? 'NO STATUS'}]');
          log('🔗 PATH: ${e.requestOptions.path}');
          log('⚠️ TYPE: ${e.type}');
          log('💬 MESSAGE: ${e.message}');
          if (e.response?.data != null) {
            log('📥 ERROR DATA: ${e.response?.data}');
          }

          final context = Bel3lmApp.navigatorKey.currentContext;
          if (context != null) {
            if (e.type == DioExceptionType.badResponse) {
              final statusCode = e.response?.statusCode;
              final String errorMessage = e.response?.data is Map
                  ? (e.response?.data['message'] ??
                        'Server error ($statusCode)')
                  : 'Server error ($statusCode)';
              SnackbarHelper.showError(context, message: errorMessage);
            } else if (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout ||
                e.type == DioExceptionType.sendTimeout ||
                e.type == DioExceptionType.connectionError) {
              SnackbarHelper.showError(
                context,
                message: 'Network error, please check your connection.',
              );
            } else {
              SnackbarHelper.showError(
                context,
                message: e.message ?? 'An unknown error occurred.',
              );
            }
          }

          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            log(
              '🚫 [AUTH] 401 Unauthorized - Consider triggering logout here.',
            );
            // FlutterSecureStorageHelper.deleteToken();
            // UserHiveHelper.clearAllUsers();
            final context = Bel3lmApp.navigatorKey.currentContext;

            if (context != null) {
              final String location = context.currentRouteName.toString();
              final authRoutes = [
                AppRoutes.login,
                AppRoutes.signup,
                AppRoutes.forgetPassword,
                AppRoutes.newPassword,
                AppRoutes.verifyOtp,
                AppRoutes.splash,
                AppRoutes.onboarding,
              ];

              if (!authRoutes.contains(location)) {
                log('🚀 Redirecting to Login from $location');
                // Use goNamed or go to reset the stack entirely
                context.go(AppRoutes.login);
              }
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> delete(String path, {dynamic data}) async {
    try {
      final response = await dio.delete(path, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  void _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      throw NetworkException(
        message: 'Network error, please check your connection.',
      );
    }

    if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Server error')
          : 'Server error';
      throw ServerException(message: message, statusCode: statusCode);
    }

    throw ServerException(message: e.message ?? 'An unknown error occurred.');
  }
}

- and make new file for import 'package:flutter/material.dart';
import '../../core/utils/screen_util_like.dart';
import '../../main.dart'; // To access Bel3lmApp.navigatorKey

class SnackbarHelper {
  static void showSuccess(BuildContext? context, {required String message}) {
    final ctx = context ?? Bel3lmApp.navigatorKey.currentContext;
    if (ctx == null) return;

    _showCustomSnackbar(
      context: ctx,
      message: message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext? context, {required String message}) {
    final ctx = context ?? Bel3lmApp.navigatorKey.currentContext;
    if (ctx == null) return;

    _showCustomSnackbar(
      context: ctx,
      message: message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
    );
  }

  static void showInfo(BuildContext? context, {required String message}) {
    final ctx = context ?? Bel3lmApp.navigatorKey.currentContext;
    if (ctx == null) return;

    _showCustomSnackbar(
      context: ctx,
      message: message,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info_outline,
    );
  }

  static void _showCustomSnackbar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    // Hide any existing snackbar before showing a new one
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24.r),
            12.hor,
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
      margin: EdgeInsets.only(
        bottom: 24.h,
        left: 20.w,
        right: 20.w,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
- and for import 'package:bel3lm/core/utils/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

class AppRefreshIndicator extends StatelessWidget {
  final Widget child;
  final RefreshCallback onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const AppRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? context.colors.primary,
      backgroundColor: backgroundColor ?? Colors.white,
      strokeWidth: 2.5,
      child: child,
    );
  }
}



