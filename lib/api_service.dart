import 'dart:convert';
import 'package:http/http.dart' as http;
import 'jenis_sampah_model.dart';

class ApiService {
  // (sesuai ipconfig)
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  // 1. Ambil Semua Data Jenis Sampah
  static Future<List<JenisSampah>> getJenisSampah() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jenis-sampah'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((e) => JenisSampah.fromJson(e)).toList();
      } else {
        throw Exception('Gagal memuat data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getJenisSampah: $e');
      rethrow;
    }
  }

  // 2. Tambah Data Jenis Sampah Baru
  static Future<bool> tambahJenisSampah(String nama) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jenis-sampah'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'nama_sampah': nama,
        }),
      );

      print('Response status post: ${response.statusCode}');
      print('Response body post: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error tambahJenisSampah: $e');
      return false;
    }
  }
}