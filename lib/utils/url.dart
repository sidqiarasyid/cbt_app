import 'package:flutter/foundation.dart';

class Url {
  // ========================================
  // KONFIGURASI KONEKSI
  // useEmulator = true  -> Emulator (10.0.2.2)
  // useEmulator = false -> Device Fisik (IP lokal)
  // useHttps    = true  -> Gunakan HTTPS (production)
  // useHttps    = false -> Gunakan HTTP (development)
  // ========================================
  static const bool useEmulator = false;
  // SECURITY: Automatically use HTTPS in release builds
  static bool get useHttps => !kDebugMode;

  // IP untuk device fisik (sesuaikan dengan IP komputer Anda)
  // Cara cek: ipconfig -> IPv4 Address (Ethernet/WiFi)
  static const String _localIP = "192.168.18.8";

  // Port backend
  static const String _port = "3000";

  // ========================================
  // JANGAN UBAH BAGIAN DI BAWAH INI
  // ========================================
  static const String _emuHost = "10.0.2.2";

  static String get _protocol => useHttps ? "https" : "http";

  static String get baseUrl {
    final host = useEmulator ? _emuHost : _localIP;
    return "$_protocol://$host:$_port/api";
  }

  // Backward compatibility - gunakan baseUrl
  static String get emuUrl => baseUrl;
}
