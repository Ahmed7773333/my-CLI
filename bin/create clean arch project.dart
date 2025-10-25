import 'dart:io';
import 'package:recase/recase.dart';

/// Runs the 'create project' command logic.
void runCreateProject(List<String> rest) {
  if (rest.length < 2 || rest[0] != 'project') {
    print('Usage: feature_cli create project <project_name>');
    exit(0);
  }
  final name = rest[1];
  final r = ReCase(name);
  final baseDir = Directory(r.snakeCase);
  if (baseDir.existsSync()) {
    stdout
        .writeln('⚠️   Directory already exists at ${baseDir.path}. Aborting.');
    exit(1);
  }

  stdout.writeln('Creating project ${r.pascalCase} at ${baseDir.path}...');

  for (final entry in templates.entries) {
    final relPath = entry.key;
    final contentTpl = entry.value;
    final finalPath = relPath.replaceAll('__snake__', r.snakeCase);
    final outFile = File('${baseDir.path}/$finalPath');
    outFile.createSync(recursive: true);
    outFile.writeAsStringSync(_render(contentTpl, r));
    stdout.writeln('✅ Created: ${outFile.path}');
  }
  stdout.writeln(
      '\n🎉 Project "${r.pascalCase}" created successfully at: ${baseDir.path}');
  stdout.writeln(
      '\nTo get started:\n\n  cd ${baseDir.path}\n  flutter pub get\n  flutter run\n');
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

// All templates for the new project are stored here.
const Map<String, String> templates = {
  // ===========================
  // ROOT FILES
  // ===========================

  'pubspec.yaml': '''
name: __snake__
description: A new Flutter project, "__pascal__".
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # flutter_localizations: # Uncomment for localization
  #   sdk: flutter

  # Core
  cupertino_icons: ^1.0.2
  equatable: ^2.0.5
  get_it: ^7.6.4
  flutter_bloc: ^8.1.3
  dartz: ^0.10.1
  dio: ^5.3.3
  intl: ^0.18.1
  flutter_secure_storage: ^9.0.0
  recase: ^4.1.0 # Useful for utils

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true

  # assets:
  #   - assets/images/
  #   - assets/fonts/

  # fonts:
  #   - family: Poppins
  #     fonts:
  #       - asset: assets/fonts/Poppins-Regular.ttf
  #       - asset: assets/fonts/Poppins-Bold.ttf
  #         weight: 700
''',

  'README.md': '''
# __pascal__

A new Flutter project created with Clean Architecture.

## Getting Started

This project is a starting point for a Flutter application.

1.  `cd __snake__`
2.  `flutter pub get`
3.  `flutter run`
''',

  '.gitignore': '''
# Dart
.dart_tool/
.packages
build/

# Flutter
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/
*.iml
*.metadata

# IDEs
.idea/
.vscode/

# Misc
*.swp
*~
''',

  'analysis_options.yaml': '''
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # prefer_single_quotes: true
    # camel_case_types: true
''',

  // ===========================
  // LIB/MAIN
  // ===========================

  'lib/main.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/di/injector.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize dependencies
  await setupInjector();
  runApp(const __pascal__App());
}

class __pascal__App extends StatelessWidget {
  // Static navigator key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  const __pascal__App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => injector<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        // Add other global BLoCs here
      ],
      child: MaterialApp(
        navigatorKey: __pascal__App.navigatorKey, // Assign the key
        title: '__pascal__',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Or control this with a BLoC
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: const SplashPage(),
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
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case AppRoutes.login:
        return RightRouting(const LoginPage());
      case AppRoutes.home:
        return RightRouting(const HomePage());
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
import '../../features/auth/di/auth_injector.dart';

final injector = GetIt.instance;

Future<void> setupInjector() async {
  // External
  injector.registerSingleton<Dio>(Dio());
  injector.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  // Core
  injector.registerSingleton<ApiConsumer>(DioClient(injector<Dio>()));

  // Features
  await initAuthInjector();
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
  Future<dynamic> post(String path, {Map<String, dynamic>? data});
  Future<dynamic> put(String path, {Map<String, dynamic>? data});
  Future<dynamic> delete(String path, {Map<String, dynamic>? data});
}
''',

  'lib/core/network/dio_client.dart': '''
import 'package:dio/dio.dart';
import 'api_consumer.dart';
import '../error/exceptions.dart';
import '../constants/app_constants.dart';

class DioClient implements ApiConsumer {
  final Dio dio;

  DioClient(this.dio) {
    dio.options
      ..baseUrl = AppConstants.baseUrl
      ..responseType = ResponseType.json
      ..connectTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30);
    
    // Add interceptors for logging, auth, etc.
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> put(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await dio.delete(path, data: data);
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
      throw NetworkException(message: 'Network error, please check your connection.');
    }

    if (e.type == DioExceptionType.badResponse) {
      final message = e.response?.data?['message'] ?? 'Server error';
      throw ServerException(message: message);
    }

    throw ServerException(message: e.message ?? 'An unknown error occurred.');
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

  'lib/core/utils/screen_util_like.dart': '''
// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/widgets.dart';

import '../../main.dart'; // Changed from my_app.dart

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
    // Changed from MyApp
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
    // Changed from MyApp
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

};
