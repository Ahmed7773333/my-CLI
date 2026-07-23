import 'dart:io';
import 'package:recase/recase.dart';

/// ======================
/// Create lib command
/// ======================

/// Runs the 'create lib' command logic.
/// Creates only the lib folder structure (without root project files).
void runCreateLib(List<String> rest) {
  if (rest.length < 2 || rest[0] != 'lib') {
    print('Usage: feature_cli create lib <app_name>');
    exit(0);
  }
  final name = rest[1];
  final r = ReCase(name);
  final libDir = Directory('lib');
  if (libDir.existsSync()) {
    stdout.writeln('⚠️  lib directory already exists. Aborting.');
    exit(1);
  }

  stdout.writeln('Creating lib structure for ${r.pascalCase}...');

  for (final entry in libTemplates.entries) {
    final relPath = entry.key;
    final contentTpl = entry.value;
    final finalPath = relPath.replaceAll('__snake__', r.snakeCase);
    final outFile = File(finalPath);
    outFile.createSync(recursive: true);
    outFile.writeAsStringSync(_render(contentTpl, r));
    stdout.writeln('✅ Created: ${outFile.path}');
  }
  stdout.writeln(
    '\n🎉 Lib structure for "${r.pascalCase}" created successfully!',
  );
  stdout.writeln(
    '\nMake sure your pubspec.yaml has the required dependencies.',
  );
}

/// simple template renderer
String _render(String tpl, ReCase r) {
  return tpl
      .replaceAll('__pascal__', r.pascalCase)
      .replaceAll('__snake__', r.snakeCase)
      .replaceAll('__camel__', r.camelCase)
      .replaceAll('__kebab__', r.paramCase)
      .replaceAll('__upper__', r.constantCase);
}

// All lib templates - only creates lib folder structure
const Map<String, String> libTemplates = {
  // ===========================
  // ROOT FILES
  // ===========================
  'l10n.yaml': '''
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
''',

  // ===========================
  // LIB/MAIN
  // ===========================
  'lib/main.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:__snake__/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:__snake__/features/homelayout/presentation/bloc/homelayout_bloc.dart';
import 'package:__snake__/features/profile/presentation/bloc/profile_bloc.dart';
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
  runApp(const __pascal__App());
}

class __pascal__App extends StatelessWidget {
  // Static navigator key
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const __pascal__App({super.key});

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
              navigatorKey: __pascal__App.navigatorKey, // Assign the key
              title: '__pascal__',
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
''',

  // ===========================
  // LIB/CONFIG
  // ===========================
  'lib/config/routes/app_router.dart': '''
import 'package:flutter/material.dart';
import 'custom_routes.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // case AppRoutes.splash:
      //   return MaterialPageRoute(builder: (_) => const SplashPage());
      // case AppRoutes.login:
      //   return RightRouting(const LoginPage());
      // case AppRoutes.home:
      //   return RightRouting(const HomePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for \${settings.name}'),
            ),
          ),
        );
    }
  }
}
''',

  'lib/config/routes/custom_routes.dart': '''
import 'package:flutter/material.dart';

class TopRouting extends PageRouteBuilder {
  final dynamic page;
  TopRouting(this.page)
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var tween =
                Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero);
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

class BottomRouting extends PageRouteBuilder {
  final dynamic page;
  BottomRouting(this.page)
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var tween =
                Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero);
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

class RightRouting extends PageRouteBuilder {
  final dynamic page;
  RightRouting(this.page)
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var tween =
                Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero);
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}

class LeftRouting extends PageRouteBuilder {
  final dynamic page;
  LeftRouting(this.page)
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var tween =
                Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero);
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        );
}
''',

  'lib/config/theme/app_theme.dart': '''
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
  );
}
''',

  // ===========================
  // LIB/CORE
  // ===========================
  'lib/core/di/injector.dart': '''
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../network/api_consumer.dart';
import '../network/dio_client.dart';

final injector = GetIt.instance;

Future<void> setupInjector() async {
  // External
  injector.registerSingleton<Dio>(Dio());
  injector.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  // Core
  injector.registerSingleton<ApiConsumer>(DioClient(injector<Dio>()));

  // Features
  // await initAuthInjector();
  // await initHomeInjector();
  // ... add other feature injectors
}
''',

  'lib/core/constants/app_constants.dart': '''
class AppConstants {
  static const String baseUrl = 'https://api.example.com';
  static const String authTokenKey = 'auth_token';
}
''',

  'lib/core/error/exceptions.dart': '''
class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'An unknown server error occurred.'});
}

class CacheException implements Exception {
  final String message;
  CacheException({this.message = 'An unknown cache error occurred.'});
}

class NetworkException implements Exception {
  final String message;
  NetworkException({this.message = 'A network error occurred. Please check your connection.'});
}
''',

  'lib/core/error/failures.dart': '''
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
''',

  'lib/core/network/api_consumer.dart': '''
abstract class ApiConsumer {
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters});
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters});
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters});
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters});
  Future<dynamic> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters});
}
''',

  'lib/core/network/dio_client.dart': '''
import 'dart:developer';
import 'package:dio/dio.dart';
import '../../config/routes/app_router.dart';
import '../../main.dart';
import '../utils/extensions/context_extensions.dart';
import '../utils/flutter_secure_storage_helper.dart';
import 'api_consumer.dart';
import '../error/exceptions.dart';
import '../constants/app_constants.dart';
import '../utils/snackbar_helper.dart';
import '../local/user_hive_helper.dart';

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
            options.headers['Authorization'] = 'Bearer \$token';
            log('🚀 [AUTH] Bearer \$token');
          }

          log('🚀 [REQUEST] [\${options.method}] URL: \${options.uri}');
          if (options.data != null) {
            if (options.data is Future<FormData> || options.data is FormData) {
              final formData = await options.data as FormData;
              final fields = formData.fields
                  .map((e) => '\${e.key}: \${e.value}')
                  .toList();
              final files = formData.files
                  .map((e) => '\${e.key}: \${e.value.filename}')
                  .toList();

              log('📦 [FORM DATA FIELDS]: \$fields');
              log('📂 [FORM DATA FILES]: \$files');
            } else {
              log('📦 [BODY]: \${options.data}');
            }
          }
          if (options.queryParameters.isNotEmpty) {
            log('❓ [QUERY PARAMS]: \${options.queryParameters}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          log(
            '✅ [RESPONSE] [\${response.statusCode}] FROM: \${response.requestOptions.path}',
          );
          log('📄 [DATA]: \${response.data}');

          // Show global success snackbar if a valid string 'message' is present
          if (response.data is Map && response.data['message'] != null) {
            final message = response.data['message'];
            if (message is String && message.isNotEmpty) {
              final context = __pascal__App.navigatorKey.currentContext;
              if (context != null && response.requestOptions.method != 'GET') {
                SnackbarHelper.showSuccess(context, message: message);
              }
            }
          }

          return handler.next(response);
        },
        onError: (DioException e, handler) {
          log('❌ [ERROR] [\${e.response?.statusCode ?? 'NO STATUS'}]');
          log('🔗 PATH: \${e.requestOptions.path}');
          log('⚠️ TYPE: \${e.type}');
          log('💬 MESSAGE: \${e.message}');
          if (e.response?.data != null) {
            log('📥 ERROR DATA: \${e.response?.data}');
          }

          final context = __pascal__App.navigatorKey.currentContext;
          if (context != null) {
            if (e.type == DioExceptionType.badResponse) {
              final statusCode = e.response?.statusCode;
              final String errorMessage = e.response?.data is Map
                  ? (e.response?.data['message'] ??
                        'Server error (\$statusCode)')
                  : 'Server error (\$statusCode)';
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
            final context = __pascal__App.navigatorKey.currentContext;

            if (context != null) {
              final String location = context.currentRouteName.toString();
              final authRoutes = [
                AppRoutes.login,
                AppRoutes.home, // wait, should authRoutes contain home? Normally not, let's keep it general
              ];

              if (location != AppRoutes.login) {
                log('🚀 Redirecting to Login from \$location');
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
''',

  'lib/core/utils/local_notification_service.dart': '''
import 'dart:developer';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static const String _channelKey = 'basic_channel';
  static const String _channelName = 'Basic Notifications';
  static const String _channelDescription =
      'Notification channel for basic tests';

  static Future<void> init() async {
    log('Initializing LocalNotificationService...');
    try {
      await AwesomeNotifications()
          .initialize('resource://mipmap/launcher_icon', [
            NotificationChannel(
              channelKey: _channelKey,
              channelName: _channelName,
              channelDescription: _channelDescription,
              defaultColor: const Color(0xFF9D50DD),
              ledColor: const Color(0xFF9D50DD),
              importance: NotificationImportance.High,
              channelShowBadge: true,
              playSound: true,
              criticalAlerts: true,
            ),
          ], debug: true);

      await _requestPermission();
      _setListeners();
      log('LocalNotificationService initialized successfully.');
    } catch (e) {
      log('Error initializing LocalNotificationService: \$e');
    }
  }

  static Future<void> _requestPermission() async {
    final bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static void _setListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    log('onNotificationCreatedMethod: \${receivedNotification.id}');
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    log('onNotificationDisplayedMethod: \${receivedNotification.id}');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    log('onDismissActionReceivedMethod: \${receivedAction.id}');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    log('onActionReceivedMethod: \${receivedAction.id}');
    // Navigation logic goes here
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: _channelKey,
        title: title,
        body: body,
        payload: payload,
      ),
    );
  }
}
''',

  'lib/core/utils/firebase_messaging_service.dart': '''
import 'dart:async';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notification_service.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Stream that emits every foreground FCM message so other parts of the app
  /// (e.g. NotificationBloc) can react to new pushes.
  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundMessageController.stream;

  Future<void> init() async {
    await _requestPermission();
    _onMessage(); // Foreground
    _onMessageOpenedApp(); // Background / Terminated (when clicked)

    // Check if app was opened from a terminated state via notification
    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    final NotificationSettings settings = await _firebaseMessaging
        .requestPermission();

    log('User granted permission: \${settings.authorizationStatus}');
  }

  Future<String?> getToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      log("FCM Token: \$token");
      return token;
    } catch (e) {
      log("Error getting FCM token: \$e");
      return null;
    }
  }

  Stream<String> get onTokenRefresh {
    return _firebaseMessaging.onTokenRefresh.map((event) {
      log("FCM Token Refreshed: \$event");
      return event;
    });
  }

  void _onMessage() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: \${message.data}');

      // Notify listeners (e.g. NotificationBloc) about the new message
      _foregroundMessageController.add(message);

      if (message.notification != null) {
        log('Message also contained a notification: \${message.notification}');

        // Show local notification
        LocalNotificationService.showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'No Title',
          body: message.notification!.body ?? 'No Body',
          payload: message.data.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }
    });
  }

  void _onMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    log('Handling message open: \${message.messageId}');

    if (message.data['route'] != null) {
      // Navigation logic will go here
    }
  }

  void dispose() {
    _foregroundMessageController.close();
  }
}
''',

  'lib/core/utils/assets.dart': '''
class Assets {
  static const String logo = 'assets/images/logo_app.png';
  static const String rank1 = 'assets/icons/rank1.png';
  static const String rank2 = 'assets/icons/rank2.png';
  static const String rank3 = 'assets/icons/rank3.png';
}
''',

  'lib/core/local/user_data.dart': '''
import 'package:hive/hive.dart';

part 'user_data.g.dart';

@HiveType(typeId: 0)
class UserData extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String? phone;

  @HiveField(2)
  String? firstName;

  @HiveField(3)
  String? secondName;

  @HiveField(4)
  String? name;

  @HiveField(5)
  String? email;

  @HiveField(6)
  String? role;

  @HiveField(7)
  String? createdAt;

  @HiveField(8)
  String? token;

  @HiveField(9)
  String? language; // 'ar' or 'en'

  @HiveField(10)
  String? image;

  @HiveField(11)
  bool? onBoardingCompleted;

  @HiveField(12)
  bool? isVerified;

  @HiveField(13)
  int? countryId;

  @HiveField(14)
  int? cityId;

  @HiveField(15)
  int? placeRequestsCount;

  @HiveField(16)
  int? approvedRequestsCount;

  @HiveField(17)
  int? rejectedRequestsCount;

  @HiveField(18)
  int? pendingRequestsCount;

  UserData({
    this.id,
    this.phone,
    this.firstName,
    this.secondName,
    this.name,
    this.email,
    this.role,
    this.createdAt,
    this.token,
    this.language = 'ar', // Defaulting to Arabic for the Egyptian market
    this.image,
    this.onBoardingCompleted,
    this.isVerified,
    this.countryId,
    this.cityId,
    this.placeRequestsCount,
    this.approvedRequestsCount,
    this.rejectedRequestsCount,
    this.pendingRequestsCount,
  });

  UserData copyWith({
    int? id,
    String? phone,
    String? firstName,
    String? secondName,
    String? name,
    String? email,
    String? role,
    String? createdAt,
    String? token,
    String? language,
    String? image,
    bool? onBoardingCompleted,
    bool? isVerified,
    int? countryId,
    int? cityId,
    int? placeRequestsCount,
    int? approvedRequestsCount,
    int? rejectedRequestsCount,
    int? pendingRequestsCount,
  }) {
    return UserData(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      secondName: secondName ?? this.secondName,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
      language: language ?? this.language,
      image: image ?? this.image,
      onBoardingCompleted: onBoardingCompleted ?? this.onBoardingCompleted,
      isVerified: isVerified ?? this.isVerified,
      countryId: countryId ?? this.countryId,
      cityId: cityId ?? this.cityId,
      placeRequestsCount: placeRequestsCount ?? this.placeRequestsCount,
      approvedRequestsCount: approvedRequestsCount ?? this.approvedRequestsCount,
      rejectedRequestsCount: rejectedRequestsCount ?? this.rejectedRequestsCount,
      pendingRequestsCount: pendingRequestsCount ?? this.pendingRequestsCount,
    );
  }

  set phoneSetter(String? value) {
    phone = value;
    save();
  }

  set nameSetter(String? value) {
    name = value;
    save();
  }

  set firstNameSetter(String? value) {
    firstName = value;
    save();
  }

  set secondNameSetter(String? value) {
    secondName = value;
    save();
  }

  set emailSetter(String? value) {
    email = value;
    save();
  }

  set roleSetter(String? value) {
    role = value;
    save();
  }

  set createdAtSetter(String? value) {
    createdAt = value;
    save();
  }

  set tokenSetter(String? value) {
    token = value;
    save();
  }

  set languageSetter(String? value) {
    language = value;
    save();
  }

  set imageSetter(String? value) {
    image = value;
    save();
  }

  set onBoardingCompletedSetter(bool? value) {
    onBoardingCompleted = value;
    save();
  }

  /// ✅ Factory: From JSON (Mapped to your Dwanza API response)
  factory UserData.fromJson(Map<String, dynamic> json, {String? token}) {
    final user = json['user'] ?? json;
    return UserData(
      id: user['id'],
      phone: user['phone'],
      firstName: user['first_name'],
      secondName: user['second_name'],
      name: user['name'],
      email: user['email'],
      role: user['role'],
      createdAt: user['created_at'],
      token: token ?? json['token'],
      image: user['image_link'],
      onBoardingCompleted: user['on_boarding_completed'],
      isVerified: user['is_verified']==1,
      countryId: user['country_id'],
      cityId: user['city_id'],
      placeRequestsCount: user['place_requests_count'],
      approvedRequestsCount: user['approved_requests_count'],
      rejectedRequestsCount: user['rejected_requests_count'],
      pendingRequestsCount: user['pending_requests_count'],
    );
  }

  set citySetter(int value) {
    cityId = value;
    save();
  }

  /// ✅ To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'first_name': firstName,
      'second_name': secondName,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt,
      'token': token,
      'language': language,
      'image': image,
      'on_boarding_completed': onBoardingCompleted,
      'is_verified': isVerified,
      'country_id': countryId,
      'city_id': cityId,
      'place_requests_count': placeRequestsCount,
      'approved_requests_count': approvedRequestsCount,
      'rejected_requests_count': rejectedRequestsCount,
      'pending_requests_count': pendingRequestsCount,
    };
  }
}
''',

  'lib/core/local/user_data.g.dart': '''
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserDataAdapter extends TypeAdapter<UserData> {
  @override
  final int typeId = 0;

  @override
  UserData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserData(
      id: fields[0] as int?,
      phone: fields[1] as String?,
      firstName: fields[2] as String?,
      secondName: fields[3] as String?,
      name: fields[4] as String?,
      email: fields[5] as String?,
      role: fields[6] as String?,
      createdAt: fields[7] as String?,
      token: fields[8] as String?,
      language: fields[9] as String?,
      image: fields[10] as String?,
      onBoardingCompleted: fields[11] as bool?,
      isVerified: fields[12] as bool?,
      countryId: fields[13] as int?,
      cityId: fields[14] as int?,
      placeRequestsCount: fields[15] as int?,
      approvedRequestsCount: fields[16] as int?,
      rejectedRequestsCount: fields[17] as int?,
      pendingRequestsCount: fields[18] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.phone)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.secondName)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.role)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.token)
      ..writeByte(9)
      ..write(obj.language)
      ..writeByte(10)
      ..write(obj.image)
      ..writeByte(11)
      ..write(obj.onBoardingCompleted)
      ..writeByte(12)
      ..write(obj.isVerified)
      ..writeByte(13)
      ..write(obj.countryId)
      ..writeByte(14)
      ..write(obj.cityId)
      ..writeByte(15)
      ..write(obj.placeRequestsCount)
      ..writeByte(16)
      ..write(obj.approvedRequestsCount)
      ..writeByte(17)
      ..write(obj.rejectedRequestsCount)
      ..writeByte(18)
      ..write(obj.pendingRequestsCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
''',

  'lib/core/local/user_hive_helper.dart': '''
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'user_data.dart';

class UserHiveHelper {
  // Box names
  static const String _userBoxName = 'userBox';
  static const String _userId = 'currentUser';

  static Future<void> initNotifications() async {
    // await LocalNotificationService.init();
    // await injector<FirebaseMessagingService>().init();
  }

  // Initialize Hive and register adapters
  static Future<void> init() async {
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
    } catch (e, st) {
      log('Error initializing Hive: \$e\\n\$st');
    }

    try {
      Hive.registerAdapter(UserDataAdapter());
    } catch (e, st) {
      log('Error registering Hive adapters: \$e\\n\$st');
    }

    try {
      await Hive.openBox<UserData>(_userBoxName);
    } catch (e, st) {
      log('Error opening Hive box: \$e\\n\$st');
    }

    try {
      if (UserHiveHelper.getUser() == null) {
        UserHiveHelper.saveUser(
          UserData(
            id: null,
            name: null,
            firstName: null,
            secondName: null,
            email: null,
            phone: null,
            createdAt: DateTime.now().toIso8601String(),
            language: 'en',
            role: null,
            token: null,
            onBoardingCompleted: false,
          ),
        );
      }
    } catch (e, st) {
      log('Error setting default user: \$e\\n\$st');
    }
  }

  // --------------------- User CRUD Operations ---------------------

  /// Creates or updates a user
  static void saveUser(UserData user) {
    final box = Hive.box<UserData>(_userBoxName);
    box.put(_userId, user);
  }

  /// Gets a user by email
  static UserData? getUser() {
    final box = Hive.box<UserData>(_userBoxName);
    return box.get(_userId);
  }

  /// Gets all users
  static List<UserData> getAllUsers() {
    final box = Hive.box<UserData>(_userBoxName);
    return box.values.toList();
  }

  /// Updates specific fields of a user
  static void updateUser(UserData user) {
    final box = Hive.box<UserData>(_userBoxName);
    box.put(_userId, user);
  }

  /// Deletes a user by email
  static void deleteUser() {
    final box = Hive.box<UserData>(_userBoxName);
    box.delete(_userId);
  }

  /// Clears all users
  static void clearAllUsers() {
    final box = Hive.box<UserData>(_userBoxName);
    box.clear();
  }

  // --------------------- Helper Methods ---------------------

  /// Closes all boxes
  static void closeBoxes() {
    Hive.close();
  }

  /// Deletes all boxes (for testing/logout)
  static void deleteAllBoxes() {
    Hive.deleteBoxFromDisk(_userBoxName);
  }

  /// Get listenable box for UI bindings
  static ValueListenable<Box<UserData>> getBoxListenable() {
    return Hive.box<UserData>(_userBoxName).listenable();
  }
}
''',

  'lib/core/utils/extensions/context_extensions.dart': '''
import 'package:flutter/material.dart';
// import 'package:timegates/l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  // AppLocalizations get strings => AppLocalizations.of(this)!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  ThemeData get theme => Theme.of(this);
}

/// 🌍 A complete BuildContext extension to handle all navigation types
/// like GoRouter but using Flutter's native Navigator system.
extension RoutingExtension on BuildContext {
  /// 🔹 Push a route by name with optional arguments
  Future<T?> pushNamed<T extends Object?>(String routeName, {Object? extra}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: extra);
  }

  /// 🔹 Replace the current route with a new one
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? extra,
  }) {
    return Navigator.of(
      this,
    ).pushReplacementNamed<T, TO>(routeName, result: result, arguments: extra);
  }

  /// 🔹 Push a route and remove all previous routes until [predicate]
  Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName, {
    bool Function(Route<dynamic>)? predicate,
    Object? extra,
  }) {
    return Navigator.of(this).pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (Route<dynamic> route) => false,
      arguments: extra,
    );
  }

  Future<void> popNamedUntil<T extends Object?>(
    String routeName, {
    Object? extra,
  }) async {
    // Pop until route with name == routeName
    Navigator.of(this).popUntil((ModalRoute.withName(routeName)));

    // Then optionally pop one more with a result
    // return Navigator.of(this).maybePop<T>(extra as T?);
  }

  /// 🔹 Push a new MaterialPageRoute directly (widget navigation)
  Future<T?> push<T extends Object?>(Widget page) {
    return Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  /// 🔹 Replace current screen with a new widget
  Future<T?> replace<T extends Object?, TO extends Object?>(
    Widget page, {
    TO? result,
  }) {
    return Navigator.of(this).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => page),
      result: result,
    );
  }

  /// 🔹 Push a page with fade transition
  Future<T?> pushFade<T extends Object?>(Widget page, {int duration = 300}) {
    return Navigator.of(this).push<T>(
      PageRouteBuilder(
        pageBuilder: (_, i, ii) => page,
        transitionsBuilder: (_, animation, i, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: duration),
      ),
    );
  }

  /// 🔹 Push a page with slide transition (customizable direction)
  Future<T?> pushSlide<T extends Object?>(
    Widget page, {
    int duration = 300,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return Navigator.of(this).push<T>(
      PageRouteBuilder(
        pageBuilder: (_, i, ii) => page,
        transitionsBuilder: (_, animation, i, child) {
          final tween = Tween(
            begin: begin,
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: duration),
      ),
    );
  }

  /// 🔹 Push and clear the entire navigation stack
  Future<T?> go<T extends Object?>(String routeName, {Object? extra}) {
    return Navigator.of(
      this,
    ).pushNamedAndRemoveUntil<T>(routeName, (route) => false, arguments: extra);
  }

  /// 🔹 Pop the current screen
  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  void simplePop<T extends Object?>([T? result]) {
    // Try to pop bottom sheet, dialog, or normal page.
    if (Navigator.canPop(this)) {
      Navigator.of(this, rootNavigator: true).maybePop(result);
    }
  }

  /// 🔹 Pop until a certain route name
  void popUntil(String routeName) {
    Navigator.of(this).popUntil(ModalRoute.withName(routeName));
  }

  /// 🔹 Try to pop if possible
  void maybePop<T extends Object?>([T? result]) {
    Navigator.of(this).maybePop(result);
  }

  /// 🔹 Pop all until first route
  void popToFirst() {
    Navigator.of(this).popUntil((route) => route.isFirst);
  }

  /// 🔹 Check if can pop
  bool get canPop => Navigator.of(this).canPop();

  /// 🔹 Get the current route name (if available)
  String? get currentRouteName => ModalRoute.of(this)?.settings.name;

  /// 🔹 Push dialog route (alert or custom)
  Future<T?> showDialogRoute<T>({
    required Widget builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (contexxt) => builder,
    );
  }

  /// 🔹 Push bottom sheet route
  Future<T?> showBottomSheetRoute<T>({
    required Widget builder,
    bool isScrollControlled = true,
    Color? backgroundColor,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      backgroundColor: backgroundColor,
      isScrollControlled: isScrollControlled,
      builder: (contexxt) => builder,
    );
  }
}
''',

  'lib/core/utils/extensions/time_extensions.dart': '''
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension TimeOfDayMinutesX on TimeOfDay {
  /// Returns the number of minutes since midnight (0–1439)
  int get minutesSinceMidnight => hour * 60 + minute;
  String get formatTimeOfDay {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, hour, minute);
    return DateFormat.jm().format(dt);
  }
}
''',

  'lib/core/utils/validators.dart': '''
/// Input validators
class Validators {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password, {int minLength = 6}) {
    return password.length >= minLength;
  }
  
  static bool hasMinLength(String text, int minLength) {
    return text.length >= minLength;
  }

  static bool isNotEmpty(String? text) {
    return text != null && text.trim().isNotEmpty;
  }

  static bool isValidPhone(String phone) {
    // Basic international phone number regex
    final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\\s\\./0-9]*\$');
    return phoneRegex.hasMatch(phone);
  }

  static bool doPasswordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }
}
''',

  'lib/core/utils/flutter_secure_storage_helper.dart': '''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class FlutterSecureStorageHelper {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.authTokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.authTokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.authTokenKey);
  }
}
''',

  'lib/core/utils/snackbar_helper.dart': '''
import 'package:flutter/material.dart';
import 'screen_util_like.dart';
import '../../main.dart'; // To access __pascal__App.navigatorKey

class SnackbarHelper {
  static void showSuccess(BuildContext? context, {required String message}) {
    final ctx = context ?? __pascal__App.navigatorKey.currentContext;
    if (ctx == null) return;

    _showCustomSnackbar(
      context: ctx,
      message: message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext? context, {required String message}) {
    final ctx = context ?? __pascal__App.navigatorKey.currentContext;
    if (ctx == null) return;

    _showCustomSnackbar(
      context: ctx,
      message: message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
    );
  }

  static void showInfo(BuildContext? context, {required String message}) {
    final ctx = context ?? __pascal__App.navigatorKey.currentContext;
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
''',

  'lib/core/utils/screen_util_like.dart': r'''
// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../../main.dart';

class ScreenUtil {
  ScreenUtil._();

  // defaults (like typical designs)
  static double designWidth = 375.0;
  static double designHeight = 812.0;

  static double _screenWidth = 0;
  static double _screenHeight = 0;
  static double _scaleWidth = 1;
  static double _scaleHeight = 1;
  static double _scaleText = 1;
  static bool _inited = false;

  /// Initialize once (call early, e.g. in top-level widget build)
  static void init({
    BuildContext? context,
    double designW = 375,
    double designH = 812,
  }) {
    final ctx = context ?? __pascal__App.navigatorKey.currentContext; 
    if (ctx == null) {
      // If no context available, do nothing now — will auto-init later on demand
      designWidth = designW;
      designHeight = designH;
      _inited = false;
      return;
    }

    final mq = MediaQuery.sizeOf(ctx);
    designWidth = designW;
    designHeight = designH;
    _screenWidth = mq.width;
    _screenHeight = mq.height;
    _scaleWidth = _screenWidth / designWidth;
    _scaleHeight = _screenHeight / designHeight;
    // text scaling uses the smaller scale (keeps fonts proportional)
    _scaleText = math.min(_scaleWidth, _scaleHeight);
    _inited = true;
  }

  // ensure initialized; try to init from navigatorKey if not done.
  static void _ensureInit() {
    if (_inited) return;
    final ctx = __pascal__App.navigatorKey.currentContext;
    if (ctx != null) {
      init(context: ctx, designW: designWidth, designH: designHeight);
    } else {
      // fallback to reasonable defaults using window if possible
      final window = WidgetsBinding.instance.window;
      final physical = window.physicalSize;
      if (physical.isEmpty) return;
      _screenWidth = physical.width / window.devicePixelRatio;
      _screenHeight = physical.height / window.devicePixelRatio;
      _scaleWidth = _screenWidth / designWidth;
      _scaleHeight = _screenHeight / designHeight;
      _scaleText = math.min(_scaleWidth, _scaleHeight);
      _inited = true;
    }
  }

  // getters used by extension
  static double get screenWidth {
    _ensureInit();
    return _screenWidth;
  }

  static double get screenHeight {
    _ensureInit();
    return _screenHeight;
  }

  static double get scaleWidth {
    _ensureInit();
    return _scaleWidth;
  }

  static double get scaleHeight {
    _ensureInit();
    return _scaleHeight;
  }

  static double get scaleText {
    _ensureInit();
    return _scaleText;
  }
}

/// Extension matching ScreenUtil-like behavior.
///
/// Usage examples:
///  - 16.w  -> scales 16 by screenWidth / designWidth
///  - 50.h  -> scales 50 by screenHeight / designHeight
///  - 1.sw  -> returns screen width
///  - 1.sh  -> returns screen height
///  - 14.sp -> scaled font size
extension Sizee on num {
  /// Actual screen width multiplier:
  /// 1.sw == device screen width
  double get sw {
    return this * ScreenUtil.screenWidth;
  }

  /// Actual screen height multiplier:
  /// 1.sh == device screen height
  double get sh {
    return this * ScreenUtil.screenHeight;
  }

  /// Width scaled relative to design width:
  /// e.g. 20.w => 20 * (screenWidth / designWidth)
  double get w {
    return (toDouble()) * ScreenUtil.scaleWidth;
  }

  /// Height scaled relative to design height:
  /// e.g. 50.h => 50 * (screenHeight / designHeight)
  double get h {
    return (toDouble()) * ScreenUtil.scaleHeight;
  }

  /// Radius scaled by text scale (or smaller of width/height scale)
  double get r {
    return (toDouble()) * ScreenUtil.scaleText;
  }

  Widget get ver {
    return SizedBox(height: toDouble().h);
  }

  Widget get hor {
    return SizedBox(width: toDouble().w);
  }
}
''',

  // ===========================
  // LIB/SHARED
  // ===========================
  'lib/shared/widgets/loading_widget.dart': '''
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
''',

  'lib/shared/widgets/app_refresh_indicator.dart': '''
import 'package:flutter/material.dart';
import 'package:__snake__/core/utils/extensions/context_extensions.dart';

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
''',

  'lib/shared/widgets/custom_textfield.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  /// The label text displayed above the field.
  final String? label;

  /// The hint text displayed inside the field when empty.
  final String? hintText;

  /// Whether the field is required (shows a red asterisk next to the label).
  final bool isRequired;

  /// Controller for the text field.
  final TextEditingController? controller;

  /// The keyboard type (e.g., email, number, phone).
  final TextInputType? keyboardType;

  /// The text input action (e.g., next, done, search).
  final TextInputAction? textInputAction;

  /// Whether the text is obscured (for passwords).
  final bool obscureText;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Maximum number of lines.
  final int maxLines;

  /// Minimum number of lines.
  final int? minLines;

  /// Maximum character length.
  final int? maxLength;

  /// Prefix icon inside the field.
  final Widget? prefixIcon;

  /// Suffix icon inside the field (e.g., visibility toggle).
  final Widget? suffixIcon;

  /// Prefix widget (e.g., country code).
  final Widget? prefix;

  /// Suffix widget.
  final Widget? suffix;

  /// Form field validator.
  final String? Function(String?)? validator;

  /// Called when the field value changes.
  final ValueChanged<String>? onChanged;

  /// Called when the field is submitted.
  final ValueChanged<String>? onFieldSubmitted;

  /// Called when the field is tapped.
  final VoidCallback? onTap;

  /// Called when editing is complete.
  final VoidCallback? onEditingComplete;

  /// Called when the field is saved (via Form).
  final FormFieldSetter<String>? onSaved;

  /// Focus node for controlling focus.
  final FocusNode? focusNode;

  /// Initial value (use instead of controller if not needed).
  final String? initialValue;

  /// Input formatters (e.g., digits only, max length).
  final List<TextInputFormatter>? inputFormatters;

  /// Auto-validation mode.
  final AutovalidateMode? autovalidateMode;

  /// Whether to auto-correct text.
  final bool autocorrect;

  /// Whether to enable suggestions.
  final bool enableSuggestions;

  /// Text alignment inside the field.
  final TextAlign textAlign;

  /// Style for the input text.
  final TextStyle? style;

  /// Style for the label text.
  final TextStyle? labelStyle;

  /// Style for the hint text.
  final TextStyle? hintStyle;

  /// Style for the error text.
  final TextStyle? errorStyle;

  /// Custom content padding inside the field.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether the field fills the background color.
  final bool filled;

  /// Background fill color.
  final Color? fillColor;

  /// Custom border radius.
  final double borderRadius;

  /// Custom border color.
  final Color? borderColor;

  /// Custom focused border color.
  final Color? focusedBorderColor;

  /// Custom error border color.
  final Color? errorBorderColor;

  /// Border width.
  final double borderWidth;

  /// Custom enabled border.
  final InputBorder? enabledBorder;

  /// Custom focused border.
  final InputBorder? focusedBorder;

  /// Custom error border.
  final InputBorder? errorBorder;

  /// Custom focused error border.
  final InputBorder? focusedErrorBorder;

  /// Custom disabled border.
  final InputBorder? disabledBorder;

  /// Text capitalization.
  final TextCapitalization textCapitalization;

  /// Whether to expand to fill available space.
  final bool expands;

  /// Counter text.
  final String? counterText;

  /// Helper text below the field.
  final String? helperText;

  /// Cursor color.
  final Color? cursorColor;

  /// Space between the label and the text field.
  final double labelSpacing;

  /// Whether to show the counter.
  final bool showCounter;

  /// Whether this field is specifically for phone numbers.
  final bool isPhoneField;

  /// The country code to display if this is a phone field.
  final String? countryCode;

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.isRequired = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.onSaved,
    this.focusNode,
    this.initialValue,
    this.inputFormatters,
    this.autovalidateMode,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textAlign = TextAlign.start,
    this.style,
    this.labelStyle,
    this.hintStyle,
    this.errorStyle,
    this.contentPadding,
    this.filled = true,
    this.fillColor,
    this.borderRadius = 12.0,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderWidth = 1.0,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
    this.textCapitalization = TextCapitalization.none,
    this.expands = false,
    this.counterText,
    this.helperText,
    this.cursorColor,
    this.labelSpacing = 8.0,
    this.showCounter = false,
    this.isPhoneField = false,
    this.countryCode = '+234',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          _buildLabel(theme),
          SizedBox(height: labelSpacing),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: isPhoneField ? TextInputType.phone : keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: expands ? null : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          focusNode: focusNode,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onTap: onTap,
          onEditingComplete: onEditingComplete,
          onSaved: onSaved,
          inputFormatters: [
            if (isPhoneField) FilteringTextInputFormatter.digitsOnly,
            ...?inputFormatters,
          ],
          autovalidateMode: autovalidateMode,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          textAlign: textAlign,
          textCapitalization: textCapitalization,
          expands: expands,
          cursorColor: cursorColor,
          style:
              style ??
              theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
          decoration: _buildDecoration(theme),
        ),
      ],
    );
  }

  Widget _buildLabel(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label!,
          style:
              labelStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildDecoration(ThemeData theme) {
    final defaultBorderRadius = BorderRadius.circular(borderRadius);

    final defaultEnabledBorder = OutlineInputBorder(
      borderRadius: defaultBorderRadius,
      borderSide: BorderSide(
        color: borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.3),
        width: borderWidth,
      ),
    );

    final defaultFocusedBorder = OutlineInputBorder(
      borderRadius: defaultBorderRadius,
      borderSide: BorderSide(
        color: focusedBorderColor ?? theme.colorScheme.primary,
        width: borderWidth + 0.5,
      ),
    );

    final defaultErrorBorder = OutlineInputBorder(
      borderRadius: defaultBorderRadius,
      borderSide: BorderSide(
        color: errorBorderColor ?? theme.colorScheme.error,
        width: borderWidth,
      ),
    );

    final defaultFocusedErrorBorder = OutlineInputBorder(
      borderRadius: defaultBorderRadius,
      borderSide: BorderSide(
        color: errorBorderColor ?? theme.colorScheme.error,
        width: borderWidth + 0.5,
      ),
    );

    final defaultDisabledBorder = OutlineInputBorder(
      borderRadius: defaultBorderRadius,
      borderSide: BorderSide(
        color: theme.colorScheme.outline.withValues(alpha: 0.15),
        width: borderWidth,
      ),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
      errorStyle: errorStyle,
      prefixIcon: isPhoneField
          ? Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color:
                          borderColor ??
                          theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 16),
                    Text(
                      countryCode ?? '+234',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            )
          : prefixIcon,
      suffixIcon: suffixIcon,
      prefix: prefix,
      suffix: suffix,
      filled: filled,
      fillColor:
          fillColor ??
          (enabled
              ? theme.colorScheme.surface
              : theme.colorScheme.onSurface.withValues(alpha: 0.04)),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: enabledBorder ?? defaultEnabledBorder,
      focusedBorder: focusedBorder ?? defaultFocusedBorder,
      errorBorder: errorBorder ?? defaultErrorBorder,
      focusedErrorBorder: focusedErrorBorder ?? defaultFocusedErrorBorder,
      disabledBorder: disabledBorder ?? defaultDisabledBorder,
      counterText: showCounter ? null : (counterText ?? ''),
      helperText: helperText,
    );
  }
}
''',

  'lib/shared/widgets/custom_elevated_button.dart': '''
import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final TextStyle? textStyle;

  const CustomElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56.0,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 30.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle:
              textStyle ??
              theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(text),
      ),
    );
  }
}
''',

  'lib/shared/widgets/error_display_widget.dart': '''
import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorDisplayWidget({
    super.key, 
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if(onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              )
            ]
          ],
        ),
      ),
    );
  }
}
''',

  // ===========================
  // LIB/FEATURES (empty placeholder)
  // ===========================
  'lib/features/.gitkeep': '''
''',

  // ===========================
  // LIB/CORE/UTILS - ADDITIONAL
  // ===========================
  'lib/core/utils/app_colors.dart': '''
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.blue;
  static const Color secondary = Colors.orange;
  // Add other main colors here
}
''',

  'lib/core/utils/bloc_observer.dart': '''
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    log('onCreate -- \${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log('onChange -- \${bloc.runtimeType}, \$change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log('onError -- \${bloc.runtimeType}, \$error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    log('onClose -- \${bloc.runtimeType}');
  }
}
''',

  // ===========================
  // LIB/CORE/NETWORK/ENDPOINTS
  // ===========================
  'lib/core/network/endpoints.dart': '''
class Endpoints {
  // static const String baseUrl = 'https://api.example.com';
  // static const String login = '/login';
}
''',

  // ===========================
  // LIB/L10N
  // ===========================
  'lib/l10n/app_en.arb': '''
{
  "hello": "Hello"
}
''',

  'lib/l10n/app_ar.arb': '''
{
  "hello": "مرحبا"
}
''',
};
