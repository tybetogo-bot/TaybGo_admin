import 'core/config/env_config.dart';
import 'main.dart' as app;

void main() {
  EnvConfig.init(env: Environment.dev);
  app.main();
}
