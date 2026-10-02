class AppConfig {
  // Toggle between mock auth (for local testing without backend) and real HTTP auth
  static const bool useMockAuth = true;
  
  static const String apiBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator localhost
}
