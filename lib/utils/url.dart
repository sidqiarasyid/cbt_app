import 'package:flutter/foundation.dart';

class Url {
  // ========================================
  // KONFIGURASI KONEKSI
  // useNgrok    = true  -> Backend lewat ngrok (HTTPS, tanpa port) -> dipakai
  //                        untuk build APK release / Firebase App Distribution
  // useNgrok    = false -> Backend lokal (emulator / IP fisik) untuk dev
  // useEmulator = true  -> Emulator (10.0.2.2)   [diabaikan bila useNgrok=true]
  // useEmulator = false -> Device Fisik (IP lokal)
  // useHttps    = true  -> Gunakan HTTPS (production)
  // useHttps    = false -> Gunakan HTTP (development)
  // ========================================
  static const bool useNgrok = true;
  static const bool useEmulator = false;
  // SECURITY: Automatically use HTTPS in release builds
  static bool get useHttps => !kDebugMode;

  // IP untuk device fisik (sesuaikan dengan IP komputer Anda)
  // Cara cek: ipconfig -> IPv4 Address (Ethernet/WiFi)
  static const String _localIP = "192.168.18.8";

  // Domain ngrok statis untuk backend (samakan dengan ngrok.yml).
  // ngrok memakai HTTPS di port 443 -> tidak perlu menulis port.
  static const String _ngrokHost = "crouton-boxlike-dove.ngrok-free.dev";

  // Port backend
  static const String _port = "3000";

  // ========================================
  // JANGAN UBAH BAGIAN DI BAWAH INI
  // ========================================
  static const String _emuHost = "10.0.2.2";

  static String get _protocol => useHttps ? "https" : "http";

  static String get baseUrl {
    // ngrok: selalu HTTPS dan tanpa port (di-handle oleh edge ngrok).
    if (useNgrok) {
      return "https://$_ngrokHost/api";
    }
    final host = useEmulator ? _emuHost : _localIP;
    return "$_protocol://$host:$_port/api";
  }

  // Backward compatibility - gunakan baseUrl
  static String get emuUrl => baseUrl;
}
