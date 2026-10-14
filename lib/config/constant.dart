class AppConstant {
  static String baseUrl = 'https://api.homzyapp.in/api/';
  static String appName = 'Homzy';
  static String packageName = 'com.homzy.customer';
  // Supplied at build time: --dart-define-from-file=env/prod.json
  static const String unRestrictedPlacesAPIKey = String.fromEnvironment('PLACES_API_KEY');
  static String serverClientId = '852443873605-vuiobiab07ffjcici1jd125hv25ue6sc.apps.googleusercontent.com';
  static String systemVersion = '3.0.0';
  static const Duration apiTimeout = Duration(seconds: 30);
}
