import 'package:anoter/utils/local_repository.dart';
import 'package:get_it/get_it.dart';

GetIt sl = GetIt.instance;

Future<void> initializeServices() async {
  sl.registerSingleton<LocalRepository>(LocalRepository());
  await sl.get<LocalRepository>().initialize();
}
