import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bank_sampah_flutter/models/jenis_sampah_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // --- JENIS SAMPAH ---
  static Future<List<JenisSampah>> getJenisSampah() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/jenis-sampah'));
    
    // INTI PENGECEKAN: Mencetak respon asli dari server ke console
    print('STATUS CODE API: ${response.statusCode}');
    print('RESPON BODY API: ${response.body}');

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => JenisSampah.fromJson(e)).toList();
    } else {
      return [];
    }
  } catch (e) {
    print('ERROR FETCH DATA: $e');
    return [];
  }
}

  static Future<bool> tambahJenisSampah(String nama) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jenis-sampah'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'nama_sampah': nama}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateJenisSampah(int id, String nama) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/jenis-sampah/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'nama_sampah': nama}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteJenisSampah(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/jenis-sampah/$id'),
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- HARGA SAMPAH (Endpoint: HargaSampahController) ---
  static Future<bool> tambahHargaSampah(int idJenisSampah, int hargaPerKg) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/harga-sampah'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_jenis_sampah': idJenisSampah,
          'harga_per_kg': hargaPerKg,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateHargaSampah(int idHarga, int hargaPerKg) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/harga-sampah/$idHarga'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'harga_per_kg': hargaPerKg}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteHargaSampah(int idHarga) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/harga-sampah/$idHarga'),
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}