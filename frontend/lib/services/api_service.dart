import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'https://libby-interpressure-tena.ngrok-free.dev/api';

  /// ================= TOKEN =================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// ================= CLEAR TOKEN =================
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  /// ================= LOGIN =================
  static Future<bool> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Accept': 'application/json'},
        body: {'username': username, 'password': password},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data['access_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['access_token']);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// ================= CEK TOKEN =================
  static Future<bool> cekToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/cek-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) return true;

      if (res.statusCode == 401) {
        await clearToken();
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// ================= GET PESANAN =================
  static Future<List<Map<String, dynamic>>> getPesanan() async {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.get(
      Uri.parse('$baseUrl/pesanan'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    }

    if (response.statusCode == 401) {
      await clearToken();
      throw Exception('Token kadaluarsa');
    }

    throw Exception('Gagal mengambil data');
  }

  /// ================= POST PESANAN =================
  static Future<bool> postPesanan(Map<String, dynamic> draft) async {
    final token = await getToken();
    if (token == null) return false;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posting-pesanan'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.fields['data'] = jsonEncode({
      'kode_transaksi': draft['kode_transaksi'],
      'tanggal': draft['tanggal'],
      'biaya': draft['biaya'],
      'nama_teknisi': draft['nama_teknisi'],
      'nama_pelanggan': draft['nama_pelanggan'],
      'nomor_telp': draft['nomor_telp'],
    });

    for (int i = 1; i <= 3; i++) {
      final path = draft['foto_$i'];
      if (path != null && path.toString().isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_$i',
            path,
            filename: File(path).path.split('/').last,
          ),
        );
      }
    }

    final response = await request.send();
    return response.statusCode == 200;
  }
}
