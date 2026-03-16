enum Environment { dev, prod }

class EnvConfig {
  static late Environment environment;
  static late String baseUrl;
  static late String appName;

  static void init({required Environment env}) {
    environment = env;
    switch (env) {
      case Environment.dev:
        baseUrl = 'https://dev.taybgo.com';
        appName = 'Admin Dev';
      case Environment.prod:
        baseUrl = 'https://taybgo.com';
        appName = 'TaybGo Admin';
    }
  }

  static bool get isDev => environment == Environment.dev;
  static bool get isProd => environment == Environment.prod;
}
