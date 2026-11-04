import 'package:connectivity_plus/connectivity_plus.dart';

class AppConnectionService {
  static bool forceOffline = false;

  final Connectivity _connectivity;

  AppConnectionService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  Future<bool> hasConnection() async {
    if (forceOffline) {
      return false;
    }

    final result = await _connectivity.checkConnectivity();
    return result.any((connection) => connection != ConnectivityResult.none);
  }

  Future<bool> canUseApp() async => hasConnection();
}
