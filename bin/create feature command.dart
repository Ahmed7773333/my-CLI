import 'dart:io';
import 'package:recase/recase.dart';

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
      '\n🎉 Feature "${r.pascalCase}" created successfully at: ${baseDir.path}');
  stdout.writeln(
      'Register your feature by calling init__pascal__Injector() in lib/core/di/injector.dart');
}

/// simple template renderer
String _render(String tpl, ReCase r) {
  return tpl
      .replaceAll('__pascal__', r.pascalCase)
      .replaceAll('__snake__', r.snakeCase)
      .replaceAll('__camel__', r.camelCase)
      .replaceAll('__kebab__', r.paramCase);
}

// All templates are kept in this file, scoped to the 'create' command.
const Map<String, String> templates = {
  // ===========================
  // 📂 DI
  // ===========================

  'di/__snake___injector.dart': '''
import '../../../core/di/injector.dart';
import '../data/datasources/local/__snake___local_data_source.dart';
import '../data/datasources/remote/__snake___remote_data_source.dart';
import '../data/repositories/__snake___repository_impl.dart';
import '../domain/repositories/__snake___repository.dart';
import '../domain/usecases/get___snake__.dart';
import '../presentation/bloc/__snake___bloc.dart';

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
  // Note: Registering as RemoteDataSourceImpl/LocalDataSourceImpl
  // If they required dependencies (like ApiConsumer), they would be passed here.
  injector.registerLazySingleton<__pascal__RemoteDataSource>(
      () => __pascal__RemoteDataSource());
  injector.registerLazySingleton<__pascal__LocalDataSource>(
      () => __pascal__LocalDataSource());
}
''',

  // ===========================
  // 📂 DATA LAYER
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

  'data/datasources/remote/__snake___remote_data_source.dart': '''
import '../models/__snake__model.dart';

// You would typically extend an abstract class:
// abstract class __pascal__RemoteDataSource {
//   Future<__pascal__Model> fetch();
// }

class __pascal__RemoteDataSource {
  // final ApiConsumer apiConsumer;
  // __pascal__RemoteDataSource({required this.apiConsumer});

  Future<__pascal__Model> fetch() async {
    // final response = await apiConsumer.get('/__kebab__');
    // return __pascal__Model.fromJson(response);
    await Future.delayed(const Duration(milliseconds: 300));
    return __pascal__Model.fake();
  }
}
''',

  'data/datasources/local/__snake___local_data_source.dart': '''
import '../models/__snake__model.dart';

// abstract class __pascal__LocalDataSource {
//   Future<void> save(__pascal__Model model);
//   Future<__pascal__Model?> load();
// }

class __pascal__LocalDataSource {
  // final FlutterSecureStorage storage;
  // __pascal__LocalDataSource({required this.storage});
  
  __pascal__Model? _cache;

  Future<void> save(__pascal__Model model) async {
    _cache = model;
  }

  Future<__pascal__Model?> load() async {
    return _cache;
  }
}
''',

  'data/repositories/__snake___repository_impl.dart': '''
import '../../domain/repositories/__snake___repository.dart';
import '../datasources/remote/__snake___remote_data_source.dart';
import '../datasources/local/__snake___local_data_source.dart';
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
    // In a real app, you'd use dartz Either for error handling:
    // Future<Either<Failure, __pascal__Model>> get__pascal__() async {
    // try {
    //   final cached = await local.load();
    //   if (cached != null) return Right(cached);
    //
    //   final data = await remote.fetch();
    //   await local.save(data);
    //   return Right(data);
    // } on ServerException catch (e) {
    //   return Left(ServerFailure(e.message));
    // } on CacheException catch (e) {
    //   return Left(CacheFailure(e.message));
    // }
    // }
    
    final cached = await local.load();
    if (cached != null) return cached;

    final data = await remote.fetch();
    await local.save(data);
    return data;
  }
}
''',

  // ===========================
  // 📂 DOMAIN LAYER
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

  // Future<Either<Failure, __pascal__Entity>> call() async {
  //   // You would map from Model to Entity here
  //   return await repository.get__pascal__();
  // }
  
  Future call() => repository.get__pascal__();
}
''',

  // ===========================
  // 📂 PRESENTATION LAYER
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
      // final result = await get__pascal__();
      // result.fold(
      //   (failure) => emit(state.copyWith(
      //       status: __pascal__Status.error, message: failure.message)),
      //   (entity) => emit(state.copyWith(
      //       status: __pascal__Status.loaded, entity: entity)),
      // );
      
      await get__pascal__(); // simple version
      emit(state.copyWith(status: __pascal__Status.loaded));
    } catch (e) {
      emit(state.copyWith(status: __pascal__Status.error, message: e.toString()));
    }
  }
}
''',

  'presentation/pages/__snake___page.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../di/__snake___injector.dart';
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
  // 📂 WIDGETS
  // ===========================

  'presentation/widgets/__snake___widget.dart': '''
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
