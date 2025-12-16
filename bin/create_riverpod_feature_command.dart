import 'dart:io';
import 'package:recase/recase.dart';

void runCreateFeatureRiverpod(List<String> rest) {
  if (rest.length < 2 || rest[0] != 'feature_riverpod') {
    print('Usage: feature_cli create feature_riverpod <feature_name>');
    exit(0);
  }

  final name = rest[1];
  final r = ReCase(name);
  final baseDir = Directory('lib/features/${r.snakeCase}');

  if (baseDir.existsSync()) {
    stdout.writeln('⚠️  Feature already exists at ${baseDir.path}');
    exit(1);
  }

  for (final entry in riverpodTemplates.entries) {
    final relPath = entry.key;
    final tpl = entry.value;

    final finalPath = relPath.replaceAll('__snake__', r.snakeCase);
    final file = File('${baseDir.path}/$finalPath');

    file.createSync(recursive: true);
    file.writeAsStringSync(_renderRiverpod(tpl, r));

    stdout.writeln('✅ Created: ${file.path}');
  }

  stdout.writeln(
      '\n🎉 Riverpod Feature "${r.pascalCase}" created successfully at: ${baseDir.path}');
}

/// Template renderer
String _renderRiverpod(String tpl, ReCase r) {
  return tpl
      .replaceAll('__pascal__', r.pascalCase)
      .replaceAll('__snake__', r.snakeCase)
      .replaceAll('__camel__', r.camelCase)
      .replaceAll('__kebab__', r.paramCase);
}
const Map<String, String> riverpodTemplates = {
  // ===========================================
  // DATA LAYER
  // ===========================================

  'data/models/__snake__model.dart': '''
class __pascal__Model {
  final String id;
  final String title;

  __pascal__Model({required this.id, required this.title});

  factory __pascal__Model.fake() =>
      __pascal__Model(id: '1', title: 'Fake __pascal__');
}
''',

  'data/repositories/__snake___repository_impl.dart': '''
import '../models/__snake__model.dart';
import '../../domain/repositories/__snake___repository.dart';
import '../datasources/remote/__snake___remote_data_source.dart';
import '../datasources/local/__snake___local_data_source.dart';

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

  'data/datasources/remote/__snake___remote_data_source.dart': '''
import '../../models/__snake__model.dart';

class __pascal__RemoteDataSource {
  Future<__pascal__Model> fetch() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return __pascal__Model.fake();
  }
}
''',

  'data/datasources/local/__snake___local_data_source.dart': '''
import '../../models/__snake__model.dart';

class __pascal__LocalDataSource {
  __pascal__Model? _cache;

  Future<void> save(__pascal__Model model) async {
    _cache = model;
  }

  Future<__pascal__Model?> load() async => _cache;
}
''',

  // ===========================================
  // DOMAIN LAYER
  // ===========================================

  'domain/entities/__snake__.dart': '''
class __pascal__Entity {
  final String id;
  final String title;

  const __pascal__Entity({required this.id, required this.title});
}
''',

  'domain/repositories/__snake___repository.dart': '''
import '../../data/models/__snake__model.dart';

abstract class __pascal__Repository {
  Future<__pascal__Model> get__pascal__();
}
''',

  'domain/usecases/get___snake__.dart': '''
import '../repositories/__snake___repository.dart';

class Get__pascal__UseCase {
  final __pascal__Repository repository;

  Get__pascal__UseCase(this.repository);

  Future call() => repository.get__pascal__();
}
''',

  // ===========================================
  // PRESENTATION: RIVERPOD CONTROLLER
  // ===========================================

  'presentation/controllers/__snake___controller.dart': '''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../features/__snake__/domain/usecases/get___snake__.dart';

part '__snake___controller.g.dart';

@riverpod
class __pascal__Controller extends _\$__pascal__Controller {
  late final Get__pascal__UseCase _useCase;

  @override
  FutureOr<void> build() async {
    _useCase = ref.watch(get__camel__UseCaseProvider);
  }

  Future<void> load() async {
    state = const AsyncLoading();

    try {
      await _useCase();
      state = const AsyncData('loaded');
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

// Providers
final get__camel__UseCaseProvider = Provider<Get__pascal__UseCase>((ref) {
  final repo = ref.watch(__camel__RepositoryProvider);
  return Get__pascal__UseCase(repo);
});

final __camel__RepositoryProvider = Provider((ref) {
  final remote = ref.watch(__camel__RemoteProvider);
  final local = ref.watch(__camel__LocalProvider);
  return __pascal__RepositoryImpl(remote: remote, local: local);
});

final __camel__RemoteProvider = Provider((ref) => __pascal__RemoteDataSource());
final __camel__LocalProvider = Provider((ref) => __pascal__LocalDataSource());
''',

  // ===========================================
  // PRESENTATION PAGE
  // ===========================================

  'presentation/pages/__snake___page.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/__snake___controller.dart';

class __pascal__Page extends ConsumerWidget {
  const __pascal__Page({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(__camel__ControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('__pascal__')),
      body: Center(
        child: state.when(
          data: (_) => const Text('Data Loaded'),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Error: \$e'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            ref.read(__camel__ControllerProvider.notifier).load(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
''',

  // ===========================================
  // WIDGETS
  // ===========================================

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
