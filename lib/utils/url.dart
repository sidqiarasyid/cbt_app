class Url {
  // ========================================
  // UBAH INI UNTUK SWITCH ANTARA EMULATOR/DEVICE
  // true  = Emulator (10.0.2.2)
  // false = Device Fisik (IP lokal)
  // ========================================
  static const bool useEmulator = true;

  // IP untuk device fisik (sesuaikan dengan IP komputer Anda)
  // Cara cek: ipconfig -> IPv4 Address (Ethernet/WiFi)
  static const String _localIP = "192.168.36.198";

  // Port backend
  static const String _port = "3000";

  // ========================================
  // JANGAN UBAH BAGIAN DI BAWAH INI
  // ========================================
  static const String _emuHost = "10.0.2.2";

  static String get baseUrl {
    final host = useEmulator ? _emuHost : _localIP;
    return "http://$host:$_port/api";
  }

  // Backward compatibility - gunakan baseUrl
  static String get emuUrl => baseUrl;
}
