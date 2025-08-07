import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Network connectivity information and monitoring
/// 
/// Provides utilities to check network connectivity status
/// and monitor connectivity changes throughout the app lifecycle.
class NetworkInfo {
  static NetworkInfo? _instance;
  static NetworkInfo get instance => _instance ??= NetworkInfo._();
  
  final Connectivity _connectivity = Connectivity();
  
  NetworkInfo._();
  
  /// Check if the device is currently connected to the internet
  Future<bool> get isConnected async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return _isConnectedType(connectivityResult);
    } catch (e) {
      return false;
    }
  }
  
  /// Get current connectivity type
  Future<ConnectivityResult> get connectivityType async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      return ConnectivityResult.none;
    }
  }
  
  /// Check if connected via WiFi
  Future<bool> get isConnectedViaWiFi async {
    final result = await connectivityType;
    return result == ConnectivityResult.wifi;
  }
  
  /// Check if connected via mobile data
  Future<bool> get isConnectedViaMobile async {
    final result = await connectivityType;
    return result == ConnectivityResult.mobile;
  }
  
  /// Check if connected via ethernet
  Future<bool> get isConnectedViaEthernet async {
    final result = await connectivityType;
    return result == ConnectivityResult.ethernet;
  }
  
  /// Get connectivity status as a human-readable string
  Future<String> get connectivityStatus async {
    final result = await connectivityType;
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
    }
  }
  
  /// Listen to connectivity changes
  Stream<ConnectivityResult> get connectivityStream => 
      _connectivity.onConnectivityChanged;
  
  /// Listen to connection status changes (connected/disconnected)
  Stream<bool> get connectionStatusStream => 
      connectivityStream.map(_isConnectedType);
  
  /// Check if a connectivity result indicates a connection
  bool _isConnectedType(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }
  
  /// Wait for internet connection to be available
  /// 
  /// Returns when connection is established or timeout is reached
  Future<bool> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (await isConnected) return true;
    
    final completer = Completer<bool>();
    late StreamSubscription subscription;
    Timer? timer;
    
    subscription = connectionStatusStream.listen((connected) {
      if (connected) {
        timer?.cancel();
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });
    
    timer = Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    
    return completer.future;
  }
  
  /// Check if the device has a metered connection
  /// 
  /// Returns true for mobile data connections, false for WiFi/Ethernet
  Future<bool> get isMeteredConnection async {
    final result = await connectivityType;
    return result == ConnectivityResult.mobile;
  }
  
  /// Get network quality estimation based on connectivity type
  /// 
  /// Returns a value from 0 (no connection) to 4 (excellent connection)
  Future<int> get networkQuality async {
    final result = await connectivityType;
    switch (result) {
      case ConnectivityResult.ethernet:
        return 4; // Excellent
      case ConnectivityResult.wifi:
        return 3; // Good
      case ConnectivityResult.mobile:
        return 2; // Fair (depends on signal strength)
      case ConnectivityResult.vpn:
        return 2; // Fair (depends on underlying connection)
      case ConnectivityResult.bluetooth:
        return 1; // Poor
      case ConnectivityResult.other:
        return 1; // Poor
      case ConnectivityResult.none:
        return 0; // No connection
    }
  }
}
