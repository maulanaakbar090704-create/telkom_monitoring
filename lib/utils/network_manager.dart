import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Manager status konektivitas jaringan (Data Seluler / Wi-Fi & Internet Nyata)
class NetworkManager {
  NetworkManager._();
  static final NetworkManager instance = NetworkManager._();

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isCheckingNotifier = ValueNotifier<bool>(false);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicTimer;

  bool get isConnected => isConnectedNotifier.value;

  /// Inisialisasi pendengar jaringan
  Future<void> init() async {
    await checkConnection();

    // Dengarkan perubahan koneksi dari perangkat
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      checkConnection();
    });

    // Pengecekan berkala setiap 5 detik untuk memastikan internet aktif
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkConnection(isSilent: true);
    });
  }

  /// Memeriksa ketersediaan koneksi internet riil
  Future<bool> checkConnection({bool isSilent = false}) async {
    if (!isSilent) {
      isCheckingNotifier.value = true;
    }

    bool hasInternet = false;

    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface = !results.contains(ConnectivityResult.none) || results.length > 1;

      if (hasInterface) {
        // Uji coba resolusi DNS / socket ping cepat
        try {
          final lookup = await InternetAddress.lookup('dns.google')
              .timeout(const Duration(seconds: 3));
          hasInternet = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
        } catch (_) {
          // Fallback coba ke host Supabase
          try {
            final lookup2 = await InternetAddress.lookup('jwybjxbwzcweiumokrrd.supabase.co')
                .timeout(const Duration(seconds: 3));
            hasInternet = lookup2.isNotEmpty && lookup2[0].rawAddress.isNotEmpty;
          } catch (_) {
            hasInternet = false;
          }
        }
      } else {
        hasInternet = false;
      }
    } catch (_) {
      hasInternet = false;
    } finally {
      isConnectedNotifier.value = hasInternet;
      if (!isSilent) {
        isCheckingNotifier.value = false;
      }
    }

    return hasInternet;
  }

  void dispose() {
    _subscription?.cancel();
    _periodicTimer?.cancel();
  }
}
