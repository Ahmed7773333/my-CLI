import 'dart:io';
import 'package:recase/recase.dart';

/// ======================
/// Create feature command
/// ======================

/// Reads the package name from pubspec.yaml in the current directory.
String _getPackageName() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stdout.writeln(
        '⚠️  pubspec.yaml not found. Using "your_app" as package name.');
    return 'your_app';
  }
  final content = pubspec.readAsStringSync();
  final nameMatch =
      RegExp(r'^name:\s*([\w_]+)', multiLine: true).firstMatch(content);
  if (nameMatch != null) {
    return nameMatch.group(1)!;
  }
  stdout.writeln(
      '⚠️  Could not parse package name from pubspec.yaml. Using "your_app".');
  return 'your_app';
}

/// Runs the 'create feature' command logic.
void runCreateFeature(List<String> rest) {
  if (rest.length < 2 || rest[0] != 'feature') {
    print('Usage: feature_cli create feature <feature_name>');
    exit(0);
  }
  final name = rest[1];
  final r = ReCase(name);
  final baseDir = Directory('lib/features/${r.snakeCase}');
  if (baseDir.existsSync()) {
    stdout.writeln('⚠️  Feature already exists at ${baseDir.path}');
    exit(1);
  }
  // Create feature files inside lib/features/__snake__/
  for (final entry in featureTemplates.entries) {
    final relPath = entry.key;
    final contentTpl = entry.value;
    final finalPath = relPath.replaceAll('__snake__', r.snakeCase);
    final outFile = File('${baseDir.path}/$finalPath');
    outFile.createSync(recursive: true);
    outFile.writeAsStringSync(_render(contentTpl, r));
    stdout.writeln('✅ Created: ${outFile.path}');
  }
  // Get the package name from pubspec.yaml
  final packageName = _getPackageName();
  // Create test files in main test folder (test/features/__snake__/)
  final testDir = Directory('test/features/${r.snakeCase}');
  for (final entry in testTemplates.entries) {
    final relPath = entry.key;
    final contentTpl = entry.value;
    final finalPath = relPath.replaceAll('__snake__', r.snakeCase);
    final outFile = File('${testDir.path}/$finalPath');
    outFile.createSync(recursive: true);
    outFile.writeAsStringSync(_render(contentTpl, r, packageName: packageName));
    stdout.writeln('✅ Created: ${outFile.path}');
  }
  stdout.writeln(
      '\n🎉 Feature "${r.pascalCase}" created successfully at: ${baseDir.path}');
  stdout.writeln('📋 Tests created at: ${testDir.path}');
  stdout.writeln(
      'Register your feature by calling init__pascal__Injector() in lib/core/di/injector.dart');
}

/// simple template renderer
String _render(String tpl, ReCase r, {String packageName = 'your_app'}) {
  return tpl
      .replaceAll('__pascal__', r.pascalCase)
      .replaceAll('__snake__', r.snakeCase)
      .replaceAll('__camel__', r.camelCase)
      .replaceAll('__kebab__', r.paramCase)
      .replaceAll('__package__', packageName);
}

// Feature templates - created inside lib/features/__snake__/
const Map<String, String> featureTemplates = {
  // ===========================
  // 📂 DI
  // ===========================
  'di/__snake___injector.dart': '''
import '../../../core/di/injector.dart';
import '../data/datasources/local/__snake___local_data_source_impl.dart';
import '../data/datasources/remote/__snake___remote_data_source_impl.dart';
import '../data/repositories/__snake___repository_impl.dart';
import '../domain/repositories/__snake___repository.dart';
import '../domain/usecases/get___snake__.dart';
import '../presentation/bloc/__snake___bloc.dart';
import '../../__snake__/domain/datasources/__snake___local_data_source.dart' as local_ds;
import '../../__snake__/domain/datasources/__snake___remote_data_source.dart' as remote_ds;

Future<void> init__pascal__Injector() async {
  // BLoC
  injector.registerFactory(() => __pascal__Bloc(
        get__pascal__: injector(),
      ));

  // UseCases
  injector.registerLazySingleton(() => Get__pascal__UseCase(injector()));

  // Repositories
  injector.registerLazySingleton<__pascal__Repository>(() => __pascal__RepositoryImpl(
        remote: injector(),
        local: injector(),
      ));

  // DataSources
  // Register implementations for the interfaces
  injector.registerLazySingleton<remote_ds.__pascal__RemoteDataSource>(
      () => __pascal__RemoteDataSourceImpl());
  injector.registerLazySingleton<local_ds.__pascal__LocalDataSource>(
      () => __pascal__LocalDataSourceImpl());
}
''',

  // ===========================
  // 📂 DATA LAYER - MODELS
  // ===========================
  'data/models/__snake__model.dart': '''
// fake model for __pascal__
class __pascal__Model {
  final String id;
  final String title;

  __pascal__Model({required this.id, required this.title});

  factory __pascal__Model.fake() {
    return __pascal__Model(id: '1', title: 'Fake __pascal__');
  }
}
''',

  // ===========================
  // 📂 DOMAIN - DATASOURCE INTERFACES
  // ===========================
  'domain/datasources/__snake___remote_data_source.dart': '''
import '../../data/models/__snake__model.dart';

abstract class __pascal__RemoteDataSource {
  Future<__pascal__Model> fetch();
}
''',

  'domain/datasources/__snake___local_data_source.dart': '''
import '../../data/models/__snake__model.dart';

abstract class __pascal__LocalDataSource {
  Future<void> save(__pascal__Model model);
  Future<__pascal__Model?> load();
}
''',

  // ===========================
  // 📂 DATA - DATASOURCE IMPLEMENTATIONS
  // ===========================
  'data/datasources/remote/__snake___remote_data_source_impl.dart': '''
import '../../../domain/datasources/__snake___remote_data_source.dart';
import '../../models/__snake__model.dart';

class __pascal__RemoteDataSourceImpl implements __pascal__RemoteDataSource {
  // final ApiConsumer apiConsumer;
  // __pascal__RemoteDataSourceImpl({required this.apiConsumer});

  @override
  Future<__pascal__Model> fetch() async {
    // final response = await apiConsumer.get('/__kebab__');
    // return __pascal__Model.fromJson(response);
    await Future.delayed(const Duration(milliseconds: 300));
    return __pascal__Model.fake();
  }
}
''',

  'data/datasources/local/__snake___local_data_source_impl.dart': '''
import '../../../domain/datasources/__snake___local_data_source.dart';
import '../../models/__snake__model.dart';

class __pascal__LocalDataSourceImpl implements __pascal__LocalDataSource {
  // final FlutterSecureStorage storage;
  // __pascal__LocalDataSourceImpl({required this.storage});
  
  __pascal__Model? _cache;

  @override
  Future<void> save(__pascal__Model model) async {
    _cache = model;
  }

  @override
  Future<__pascal__Model?> load() async {
    return _cache;
  }
}
''',

  // ===========================
  // 📂 DATA - REPOSITORY (depends on domain interfaces)
  // ===========================
  'data/repositories/__snake___repository_impl.dart': '''
import '../../domain/repositories/__snake___repository.dart';
import '../../domain/datasources/__snake___remote_data_source.dart';
import '../../domain/datasources/__snake___local_data_source.dart';
import '../models/__snake__model.dart';
// import 'package:dartz/dartz.dart';
// import '../../../../core/error/failures.dart';
// import '../../../../core/error/exceptions.dart';

class __pascal__RepositoryImpl implements __pascal__Repository {
  final __pascal__RemoteDataSource remote;
  final __pascal__LocalDataSource local;

  __pascal__RepositoryImpl({
    required this.remote,
    required this.local,
  });

  @override
  Future<__pascal__Model> get__pascal__() async {
    final cached = await local.load();
    if (cached != null) return cached;

    final data = await remote.fetch();
    await local.save(data);
    return data;
  }
}
''',

  // ===========================
  // 📂 DOMAIN - ENTITIES / REPO / USECASE
  // ===========================
  'domain/entities/__snake__.dart': '''
import 'package:equatable/equatable.dart';

class __pascal__Entity extends Equatable {
  final String id;
  final String title;

  const __pascal__Entity({required this.id, required this.title});
  
  @override
  List<Object> get props => [id, title];
}
''',

  'domain/repositories/__snake___repository.dart': '''
import '../../data/models/__snake__model.dart';
// import 'package:dartz/dartz.dart';
// import '../../../../core/error/failures.dart';

abstract class __pascal__Repository {
  // Future<Either<Failure, __pascal__Model>> get__pascal__();
  Future<__pascal__Model> get__pascal__();
}
''',

  'domain/usecases/get___snake__.dart': '''
import '../repositories/__snake___repository.dart';
// import 'package:dartz/dartz.dart';
// import '../../../../core/error/failures.dart';
// import '../entities/__snake__.dart';

class Get__pascal__UseCase {
  final __pascal__Repository repository;

  Get__pascal__UseCase(this.repository);

  Future call() => repository.get__pascal__();
}
''',

  // ===========================
  // 📂 PRESENTATION - BLOC / STATE / EVENT
  // ===========================
  'presentation/bloc/__snake___event.dart': '''
import 'package:equatable/equatable.dart';

abstract class __pascal__Event extends Equatable {
  const __pascal__Event();
  @override
  List<Object> get props => [];
}

class Load__pascal__Event extends __pascal__Event {}
''',

  'presentation/bloc/__snake___state.dart': '''
import 'package:equatable/equatable.dart';

enum __pascal__Status { initial, loading, loaded, error }

class __pascal__State extends Equatable {
  const __pascal__State({
    this.status = __pascal__Status.initial,
    this.message = '',
    // final __pascal__Entity? entity,
  });

  final __pascal__Status status;
  final String message;
  // final __pascal__Entity? entity;

  __pascal__State copyWith({
    __pascal__Status? status,
    String? message,
    // __pascal__Entity? entity,
  }) {
    return __pascal__State(
      status: status ?? this.status,
      message: message ?? this.message,
      // entity: entity ?? this.entity,
    );
  }

  @override
  List<Object> get props => [status, message]; // props..add(entity)
}
''',

  'presentation/bloc/__snake___bloc.dart': '''
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get___snake__.dart';
import '__snake___event.dart';
import '__snake___state.dart';

class __pascal__Bloc extends Bloc<__pascal__Event, __pascal__State> {
  final Get__pascal__UseCase get__pascal__;

  __pascal__Bloc({required this.get__pascal__})
      : super(const __pascal__State()) {
    on<Load__pascal__Event>(_onLoad);
  }

  FutureOr<void> _onLoad(
      Load__pascal__Event event, Emitter<__pascal__State> emit) async {
    emit(state.copyWith(status: __pascal__Status.loading));
    try {
      await get__pascal__(); // simple version
      emit(state.copyWith(status: __pascal__Status.loaded));
    } catch (e) {
      emit(state.copyWith(status: __pascal__Status.error, message: e.toString()));
    }
  }
}
''',

  // ===========================
  // 📂 PRESENTATION - PAGES
  // ===========================
  'presentation/pages/__snake___page.dart': r'''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../di/__snake___injector.dart';
import '../../../../core/di/injector.dart';
import '../bloc/__snake___bloc.dart';
import '../bloc/__snake___event.dart';
import '../bloc/__snake___state.dart';

class __pascal__Page extends StatelessWidget {
  const __pascal__Page({super.key});

  @override
  Widget build(BuildContext context) {
    // You can provide the BLoC locally
    return BlocProvider(
      create: (context) => injector<__pascal__Bloc>()..add(Load__pascal__Event()),
      child: const __pascal__View(),
    );
  }
}

class __pascal__View extends StatelessWidget {
  const __pascal__View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('__pascal__')),
      body: Center(
        child: BlocBuilder<__pascal__Bloc, __pascal__State>(
          builder: (context, state) {
            switch (state.status) {
              case __pascal__Status.initial:
              case __pascal__Status.loading:
                return const CircularProgressIndicator();
              case __pascal__Status.loaded:
                return const Text('Data Loaded ✅');
              case __pascal__Status.error:
                return Text('Error: \${state.message}');
            }
          },
        ),
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<__pascal__Bloc>().add(Load__pascal__Event()),
        child: const Icon(Icons.refresh),
       ),
    );
  }
}
''',

  // ===========================
  // 📂 PRESENTATION - WIDGETS
  // ===========================
  'presentation/widgets/__snake___widget.dart': r'''
import 'package:flutter/material.dart';

class Fake__pascal__Widget extends StatefulWidget {
  const Fake__pascal__Widget({super.key});

  @override
  State<Fake__pascal__Widget> createState() => _Fake__pascal__WidgetState();
}

class _Fake__pascal__WidgetState extends State<Fake__pascal__Widget> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Fake __pascal__ Widget: counter = \$counter'),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => setState(() => counter++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
''',
};

// Test templates - created in main test folder (test/features/__snake__/)
const Map<String, String> testTemplates = {
  // ===========================
  // 📂 TESTS - UNIT / WIDGET / INTEGRATION
  // ===========================
  '__snake___unit_test.dart': r'''
// This unit test demonstrates repository behavior using mock implementations.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:__package__/features/__snake__/data/models/__snake__model.dart';
import 'package:__package__/features/__snake__/data/repositories/__snake___repository_impl.dart';
import 'package:__package__/features/__snake__/domain/datasources/__snake___remote_data_source.dart';
import 'package:__package__/features/__snake__/domain/datasources/__snake___local_data_source.dart';

class MockRemoteDS extends Mock implements __pascal__RemoteDataSource {}
class MockLocalDS extends Mock implements __pascal__LocalDataSource {}

void main() {
  late __pascal__RepositoryImpl repository;
  late MockRemoteDS mockRemote;
  late MockLocalDS mockLocal;

  setUp(() {
    mockRemote = MockRemoteDS();
    mockLocal = MockLocalDS();
    repository = __pascal__RepositoryImpl(remote: mockRemote, local: mockLocal);
  });

  test('should return cached data if exists', () async {
    final fakeModel = __pascal__Model.fake();
    when(() => mockLocal.load()).thenAnswer((_) async => fakeModel);

    final result = await repository.get__pascal__();

    expect(result.id, fakeModel.id);
    verifyNever(() => mockRemote.fetch());
  });

  test('should fetch from remote when cache is empty', () async {
    final fakeModel = __pascal__Model.fake();
    when(() => mockLocal.load()).thenAnswer((_) async => null);
    when(() => mockRemote.fetch()).thenAnswer((_) async => fakeModel);
    when(() => mockLocal.save(any())).thenAnswer((_) async {});

    final result = await repository.get__pascal__();

    expect(result.id, fakeModel.id);
    verify(() => mockRemote.fetch()).called(1);
    verify(() => mockLocal.save(any())).called(1);
  });
}
''',

  '__snake___widget_test.dart': r'''
// Widget test skeleton for the feature page.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:__package__/features/__snake__/presentation/pages/__snake___page.dart';
import 'package:__package__/features/__snake__/presentation/bloc/__snake___bloc.dart';
import 'package:__package__/core/di/injector.dart' as core_injector;

void main() {
  testWidgets('Shows loading and then loaded text', (tester) async {
    // If you use dependency injection, make sure injector is configured in tests.
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => core_injector.injector<__pascal__Bloc>(),
          child: const __pascal__Page(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Data Loaded ✅'), findsOneWidget);
  });
}
''',

  '__snake___integration_test.dart': r'''
// Integration test skeleton for the feature.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:__package__/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Load feature end-to-end', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Data Loaded ✅'), findsOneWidget);
  });
}
''',
};
