import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

import '../models/jenis_sampah_model.dart';
import '../models/setoran_model.dart';

class PetugasPage<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const PetugasPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static String? _authToken;
  static String? _sessionCookie;

  // ==========================================================
  // HEADER DAN SESSION
  // ==========================================================

  static Map<String, String> _headers({bool json = false}) {
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
      if (_sessionCookie != null && _sessionCookie!.isNotEmpty)
        'Cookie': _sessionCookie!,
    };
  }

  static void clearSession() {
    _authToken = null;
    _sessionCookie = null;
  }

  // ==========================================================
  // HELPER RESPONSE
  // ==========================================================

  static Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  static String _errorMessage(Map<String, dynamic> data, String fallback) {
    final errors = data['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }

    return data['message']?.toString() ?? fallback;
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      clearSession();

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('LOGIN STATUS: ${response.statusCode}');
      print('LOGIN RESPONSE: ${response.body}');

      final data = _decodeMap(response.body);

      if (response.statusCode == 200) {
        final nestedData = data['data'];

        final token =
            data['token'] ??
            data['access_token'] ??
            (nestedData is Map
                ? nestedData['token'] ?? nestedData['access_token']
                : null);

        _authToken = token?.toString();

        final setCookie = response.headers['set-cookie'];

        if (setCookie != null && setCookie.isNotEmpty) {
          final cookies = RegExp(r'(?:^|,\s*)([A-Za-z0-9_%-]+=[^;,]+)')
              .allMatches(setCookie)
              .map((match) => match.group(1)!)
              .toList();

          _sessionCookie = cookies.join('; ');
        }

        return {
          'success': true,
          'message': data['message'],
          'user':
              data['user'] ?? (nestedData is Map ? nestedData['user'] : null),
          'token': _authToken,
        };
      }

      clearSession();

      return {'success': false, 'message': data['message'] ?? 'Login gagal'};
    } catch (e) {
      clearSession();
      print('LOGIN ERROR: $e');

      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  // ==========================================================
  // LOGIN GOOGLE
  // ==========================================================

  static Future<Map<String, dynamic>> loginGoogle(
    String idToken,
  ) async {
    try {
      clearSession();

      final response = await http.post(
        Uri.parse('$baseUrl/login/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
        }),
      );

      print('GOOGLE LOGIN STATUS: ${response.statusCode}');
      print('GOOGLE LOGIN RESPONSE: ${response.body}');

      final data = _decodeMap(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _authToken = data['token']?.toString();

        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
          'token': _authToken,
        };
      }

      clearSession();

      return {
        'success': false,
        'message': data['message'] ?? 'Login Google gagal',
      };
    } catch (e) {
      clearSession();

      print('GOOGLE LOGIN ERROR: $e');

      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server',
      };
    }
  }


  // ==========================================================
  // DASHBOARD ADMIN
  // ==========================================================

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: _headers(),
    );

    final data = _decodeMap(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    }

    throw Exception(data['message'] ?? 'Gagal mengambil dashboard admin');
  }

  // ==========================================================
  // JENIS SAMPAH
  // ==========================================================

  static Future<List<JenisSampah>> getJenisSampah() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/jenis-sampah?t=${DateTime.now().millisecondsSinceEpoch}',
      ),
      headers: {
        ..._headers(),
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((item) => JenisSampah.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    throw Exception('Gagal mengambil data jenis sampah');
  }

  static Future<bool> tambahJenisSampah({
    required String namaSampah,
    required int hargaPerKg,
    required bool status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jenis-sampah-dengan-harga'),
      headers: _headers(json: true),
      body: jsonEncode({
        'nama_sampah': namaSampah,
        'harga_per_kg': hargaPerKg,
        'status': status,
      }),
    );

    if (response.statusCode == 201) return true;

    throw Exception(
      _errorMessage(
        _decodeMap(response.body),
        'Gagal menambahkan jenis sampah',
      ),
    );
  }

  static Future<bool> updateJenisSampah({
    required int id,
    required String namaSampah,
    required int hargaPerKg,
    required bool status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/jenis-sampah/$id'),
      headers: _headers(json: true),
      body: jsonEncode({
        'nama_sampah': namaSampah,
        'harga_per_kg': hargaPerKg,
        'status': status,
      }),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(
        _decodeMap(response.body),
        'Gagal memperbarui jenis sampah',
      ),
    );
  }

  static Future<bool> deleteJenisSampah({
    required int idJenisSampah,
    int? idHarga,
  }) async {
    final url = idHarga != null
        ? '$baseUrl/harga-sampah/$idHarga'
        : '$baseUrl/jenis-sampah/$idJenisSampah';

    final response = await http.delete(Uri.parse(url), headers: _headers());

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(_decodeMap(response.body), 'Gagal menghapus jenis sampah'),
    );
  }

  // ==========================================================
  // HARGA SAMPAH
  // ==========================================================

  static Future<List<dynamic>> getHargaSampah() async {
    final response = await http.get(
      Uri.parse('$baseUrl/harga-sampah'),
      headers: _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil harga sampah');
    }

    return jsonDecode(response.body);
  }

  static Future<bool> tambahHargaSampah(
    int idJenisSampah,
    int hargaPerKg,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/harga-sampah'),
      headers: _headers(json: true),
      body: jsonEncode({
        'id_jenis_sampah': idJenisSampah,
        'harga_per_kg': hargaPerKg,
      }),
    );

    if (response.statusCode == 201) return true;

    throw Exception(
      _errorMessage(
        _decodeMap(response.body),
        'Gagal menambahkan harga sampah',
      ),
    );
  }

  static Future<bool> updateHargaSampah(int idHarga, int hargaPerKg) async {
    final response = await http.put(
      Uri.parse('$baseUrl/harga-sampah/$idHarga'),
      headers: _headers(json: true),
      body: jsonEncode({'harga_per_kg': hargaPerKg}),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(
        _decodeMap(response.body),
        'Gagal memperbarui harga sampah',
      ),
    );
  }

  static Future<bool> deleteHargaSampah(int idHarga) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/harga-sampah/$idHarga'),
      headers: _headers(),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(_decodeMap(response.body), 'Gagal menghapus harga sampah'),
    );
  }

  // ==========================================================
  // MANAJEMEN PENGGUNA
  // ==========================================================

  static Future<List<Map<String, dynamic>>> getPengguna() async {
    final response = await http.get(
      Uri.parse('$baseUrl/pengguna?t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: {
        ..._headers(),
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data pengguna');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map<Map<String, dynamic>>((item) {
      final map = Map<String, dynamic>.from(item);

      return {
        'id': int.parse(map['id'].toString()),
        'nama': map['nama']?.toString() ?? '',
        'email': map['email']?.toString() ?? '',
        'telepon': map['telepon']?.toString() ?? '-',
        'role': _formatRole(map['role']?.toString() ?? ''),
        'status': map['status'] == true || map['status'].toString() == '1',
        'protected':
            map['protected'] == true || map['protected'].toString() == '1',
      };
    }).toList();
  }

  static String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Admin';
      case 'petugas':
        return 'Petugas';
      case 'nasabah':
        return 'Nasabah';
      default:
        return role;
    }
  }

  static Future<bool> tambahPengguna({
    required String nama,
    required String telepon,
    required String email,
    required String password,
    required String role,
    required bool status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pengguna'),
      headers: _headers(json: true),
      body: jsonEncode({
        'name': nama,
        'no_telepon': telepon,
        'email': email,
        'password': password,
        'role': role.toLowerCase(),
        'status': status,
      }),
    );

    if (response.statusCode == 201) return true;

    throw Exception(
      _errorMessage(_decodeMap(response.body), 'Gagal menambahkan pengguna'),
    );
  }

  static Future<bool> updatePengguna({
    required int id,
    required String nama,
    required String role,
    required bool status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/pengguna/$id'),
      headers: _headers(json: true),
      body: jsonEncode({
        'name': nama,
        'role': role.toLowerCase(),
        'status': status,
      }),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(_decodeMap(response.body), 'Gagal memperbarui pengguna'),
    );
  }

  static Future<bool> deletePengguna(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/pengguna/$id'),
      headers: _headers(),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(_decodeMap(response.body), 'Gagal menghapus pengguna'),
    );
  }

  // ==========================================================
  // NOTIFIKASI ADMIN
  // ==========================================================

  static Future<Map<String, dynamic>> getNotifikasiAdmin() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/admin/notifikasi'
        '?t=${DateTime.now().millisecondsSinceEpoch}',
      ),
      headers: {..._headers(), 'Cache-Control': 'no-cache'},
    );

    final decoded = _decodeMap(response.body);

    if (response.statusCode == 200) return decoded;

    throw Exception(decoded['message'] ?? 'Gagal mengambil notifikasi admin.');
  }

  static Future<bool> tandaiNotifikasiAdminDibaca(int idNotifikasi) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/notifikasi/$idNotifikasi/dibaca'),
      headers: _headers(json: true),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(_decodeMap(response.body), 'Gagal menandai notifikasi'),
    );
  }

  static Future<bool> tandaiSemuaNotifikasiAdminDibaca() async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/notifikasi/dibaca-semua'),
      headers: _headers(json: true),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(
        _decodeMap(response.body),
        'Gagal memperbarui notifikasi admin.',
      ),
    );
  }

  // ==========================================================
  // DASHBOARD PETUGAS
  // ==========================================================

  static Future<Map<String, dynamic>> getPetugasDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/petugas/dashboard'),
      headers: _headers(),
    );

    final data = _decodeMap(response.body);

    debugPrint('PETUGAS DASHBOARD STATUS: ${response.statusCode}');
    debugPrint('PETUGAS DASHBOARD RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    }

    throw Exception(data['message'] ?? 'Gagal mengambil dashboard petugas');
  }

  // ==========================================================
  // DATA LAPORAN SETORAN ADMIN
  // ==========================================================

  static Future<List<SetoranModel>> getSetoran({int? bulan, int? tahun}) async {
    final uri = Uri.parse('$baseUrl/admin/laporan/setoran').replace(
      queryParameters: {
        if (bulan != null) 'bulan': '$bulan',
        if (tahun != null) 'tahun': '$tahun',
      },
    );

    final response = await http.get(uri, headers: _headers());

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded is Map
            ? decoded['message'] ?? 'Gagal mengambil laporan setoran'
            : 'Gagal mengambil laporan setoran',
      );
    }

    final dynamic items = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['data']
        : null;

    if (items is! List) {
      throw Exception('Format respons data laporan tidak sesuai.');
    }

    return items
        .map((item) => SetoranModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<PetugasPage<SetoranModel>> getPetugasSetoranPage({
    int? bulan,
    int? tahun,
    int? idNasabah,
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/petugas/setoran').replace(
      queryParameters: {
        if (bulan != null) 'bulan': '$bulan',
        if (tahun != null) 'tahun': '$tahun',
        if (idNasabah != null) 'id_nasabah': '$idNasabah',
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    final response = await http.get(uri, headers: _headers());

    return _parsePetugasPage<SetoranModel>(
      response,
      endpoint: 'setoran',
      mapItem: (item) => SetoranModel.fromJson(item),
    );
  }

  static Future<Map<String, dynamic>> tambahSetoran({
    required int idNasabah,
    required int idPetugas,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = {
      'id_pengguna_nasabah': idNasabah,
      'id_pengguna_petugas': idPetugas,
      'items': items.map((item) {
        return {
          'id_jenis_sampah': item['id_jenis_sampah'],
          'total_berat': item['total_berat'],
        };
      }).toList(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/petugas/setoran'),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );

    final data = _decodeMap(response.body);

    if (response.statusCode == 201) {
      return {
        'success': true,
        'message': data['message'] ?? 'Setoran berhasil disimpan',
        'data': data['data'],
      };
    }

    throw Exception(_errorMessage(data, 'Gagal menyimpan setoran'));
  }

  // ==========================================================
  // DATA NASABAH PETUGAS
  // ==========================================================

  static Future<List<Map<String, dynamic>>> getNasabah() async {
    final response = await http.get(
      Uri.parse('$baseUrl/petugas/nasabah'),
      headers: {..._headers(), 'Cache-Control': 'no-cache'},
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded is Map
            ? decoded['message'] ?? 'Gagal mengambil data nasabah'
            : 'Gagal mengambil data nasabah',
      );
    }

    final dynamic items = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['data']
        : null;

    if (items is! List) {
      throw Exception('Format respons data nasabah tidak sesuai.');
    }

    return items
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  static Future<PetugasPage<Map<String, dynamic>>> getPetugasNasabahPage({
    String keyword = '',
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/petugas/nasabah').replace(
      queryParameters: {
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    final response = await http.get(
      uri,
      headers: {..._headers(), 'Cache-Control': 'no-cache'},
    );

    return _parsePetugasPage<Map<String, dynamic>>(
      response,
      endpoint: 'nasabah',
      mapItem: (item) => item,
    );
  }

  static Future<Map<String, dynamic>> getPetugasNasabahDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/petugas/nasabah/$id'),
      headers: _headers(),
    );

    final decoded = _decodeMap(response.body);

    if (response.statusCode != 200 || decoded['data'] is! Map) {
      throw Exception(decoded['message'] ?? 'Gagal mengambil detail nasabah');
    }

    return Map<String, dynamic>.from(decoded['data']);
  }

  // ==========================================================
  // PENARIKAN NASABAH
  // ==========================================================

  // AJUKAN PENARIKAN
  static Future<Map<String, dynamic>> ajukanPenarikan({
    required int idNasabah,
    required double nominal,
  }) async {
    try {
      if (_authToken == null || _authToken!.isEmpty) {
        throw Exception('Sesi login berakhir. Silakan login kembali.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/nasabah/penarikan'),
        headers: _headers(json: true),
        body: jsonEncode({'nominal': nominal}),
      );

      print('AJUKAN PENARIKAN STATUS: ${response.statusCode}');
      print('AJUKAN PENARIKAN RESPONSE: ${response.body}');

      final data = _decodeMap(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pengajuan penarikan berhasil dibuat.',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': _errorMessage(data, 'Gagal mengajukan penarikan'),
      };
    } catch (e) {
      print('AJUKAN PENARIKAN ERROR: $e');
      rethrow;
    }
  }

  // RIWAYAT PENARIKAN NASABAH
  static Future<List<Map<String, dynamic>>> getRiwayatPenarikanNasabah(
    int idNasabah,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/nasabah/$idNasabah/penarikan'),
      headers: {..._headers(), 'Cache-Control': 'no-cache'},
    );

    print('RIWAYAT PENARIKAN STATUS: ${response.statusCode}');
    print('RIWAYAT PENARIKAN RESPONSE: ${response.body}');

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded is Map
            ? decoded['message'] ?? 'Gagal mengambil riwayat penarikan'
            : 'Gagal mengambil riwayat penarikan',
      );
    }

    final dynamic items = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['data']
        : null;

    if (items is! List) {
      throw Exception('Format respons riwayat penarikan tidak sesuai.');
    }

    return items
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  // BATALKAN PENARIKAN NASABAH
  static Future<bool> batalkanPenarikanNasabah({
    required int idNasabah,
    required int idPenarikan,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/nasabah/$idNasabah/penarikan/$idPenarikan/batalkan'),
      headers: _headers(json: true),
    );

    print('BATALKAN PENARIKAN STATUS: ${response.statusCode}');
    print('BATALKAN PENARIKAN RESPONSE: ${response.body}');

    final data = _decodeMap(response.body);

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(_errorMessage(data, 'Gagal membatalkan penarikan'));
  }

  // ==========================================================
  // RIWAYAT SETORAN NASABAH
  // ==========================================================

  static Future<List<SetoranModel>> getRiwayatSetoranNasabah(
    int idNasabah,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/nasabah/$idNasabah/setoran'),
      headers: {..._headers(), 'Cache-Control': 'no-cache'},
    );

    print('RIWAYAT SETORAN NASABAH STATUS: ${response.statusCode}');
    print('RIWAYAT SETORAN NASABAH RESPONSE: ${response.body}');

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200 || decoded is! Map) {
      throw Exception(
        decoded is Map
            ? decoded['message'] ?? 'Gagal mengambil riwayat setoran'
            : 'Gagal mengambil riwayat setoran',
      );
    }

    final items = decoded['data'];

    if (items is! List) {
      throw Exception('Format riwayat setoran tidak sesuai.');
    }

    return items
        .map((item) => SetoranModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // ==========================================================
  // PENARIKAN PETUGAS
  // ==========================================================

  static Future<List<Map<String, dynamic>>> getPenarikanPetugas({
    int? bulan,
    int? tahun,
  }) async {
    final uri = Uri.parse('$baseUrl/petugas/penarikan').replace(
      queryParameters: {
        if (bulan != null) 'bulan': '$bulan',
        if (tahun != null) 'tahun': '$tahun',
      },
    );

    final response = await http.get(uri, headers: _headers());

    print('GET PENARIKAN STATUS: ${response.statusCode}');
    print('GET PENARIKAN RESPONSE: ${response.body}');

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded is Map
            ? decoded['message'] ?? 'Gagal mengambil daftar penarikan'
            : 'Gagal mengambil daftar penarikan',
      );
    }

    final dynamic items = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['data']
        : null;

    if (items is! List) {
      throw Exception('Format daftar penarikan tidak sesuai.');
    }

    return items
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  static Future<PetugasPage<Map<String, dynamic>>> getPetugasPenarikanPage({
    int? bulan,
    int? tahun,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/petugas/penarikan').replace(
      queryParameters: {
        if (bulan != null) 'bulan': '$bulan',
        if (tahun != null) 'tahun': '$tahun',
        if (status != null && status != 'Semua') 'status': status,
        'page': '$page',
        'per_page': '$perPage',
      },
    );

    final response = await http.get(uri, headers: _headers());

    return _parsePetugasPage<Map<String, dynamic>>(
      response,
      endpoint: 'penarikan',
      mapItem: (item) => item,
    );
  }

  // CARI PENARIKAN DENGAN KODE VERIFIKASI
  static Future<Map<String, dynamic>> cariPenarikanPetugas(
    String kodeVerifikasi,
  ) async {
    final uri = Uri.parse('$baseUrl/petugas/penarikan/cari').replace(
      queryParameters: {'kode_verifikasi': kodeVerifikasi.trim().toUpperCase()},
    );

    final response = await http.get(uri, headers: _headers());

    print('CARI PENARIKAN STATUS: ${response.statusCode}');
    print('CARI PENARIKAN RESPONSE: ${response.body}');

    final data = _decodeMap(response.body);

    if (response.statusCode == 200) {
      final detail = data['data'];

      if (detail is! Map) {
        throw Exception('Detail pengajuan tidak ditemukan.');
      }

      return Map<String, dynamic>.from(detail);
    }

    throw Exception(data['message'] ?? 'Pengajuan penarikan tidak ditemukan.');
  }

  // PROSES PENARIKAN PETUGAS
  static Future<Map<String, dynamic>> prosesPenarikanPetugas({
    required int idPenarikan,
    required int idPetugas,
    required String status,
  }) async {
    if (status != 'Disetujui' && status != 'Ditolak') {
      throw ArgumentError('Status penarikan tidak valid.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/petugas/penarikan/$idPenarikan/proses'),
      headers: _headers(json: true),
      body: jsonEncode({'status': status}),
    );

    print('PROSES PENARIKAN STATUS: ${response.statusCode}');
    print('PROSES PENARIKAN RESPONSE: ${response.body}');

    final data = _decodeMap(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'] ?? 'Penarikan berhasil diproses.',
        'data': data['data'],
      };
    }

    throw Exception(_errorMessage(data, 'Gagal memproses penarikan.'));
  }

  // ==========================================================
  // HELPER PAGINATION PETUGAS
  // ==========================================================

  static PetugasPage<T> _parsePetugasPage<T>(
    http.Response response, {
    required String endpoint,
    required T Function(Map<String, dynamic>) mapItem,
  }) {
    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200 || decoded is! Map) {
      throw Exception(
        decoded is Map
            ? decoded['message'] ?? 'Gagal mengambil data $endpoint'
            : 'Gagal mengambil data $endpoint',
      );
    }

    final data = decoded['data'];

    if (data is! List) {
      throw Exception('Format response pagination $endpoint tidak sesuai');
    }

    final meta = decoded['meta'] is Map
        ? Map<String, dynamic>.from(decoded['meta'])
        : <String, dynamic>{};

    int number(String key, int fallback) {
      return int.tryParse(meta[key]?.toString() ?? '') ?? fallback;
    }

    return PetugasPage<T>(
      items: data
          .map((item) => mapItem(Map<String, dynamic>.from(item as Map)))
          .toList(),
      currentPage: number('current_page', 1),
      lastPage: number('last_page', 1),
      total: number('total', data.length),
    );
  }

  // ==========================================================
  // PROFIL NASABAH
  // ==========================================================

  static Future<Map<String, dynamic>> getProfilNasabah(
    int idNasabah,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/nasabah/$idNasabah/profil'),
      headers: {..._headers(), 'Cache-Control': 'no-cache'},
    );

    print('========== PROFIL NASABAH ==========');
    print('ID NASABAH: $idNasabah');
    print('TOKEN TERSEDIA: ${_authToken != null && _authToken!.isNotEmpty}');
    print('PROFIL STATUS: ${response.statusCode}');
    print('PROFIL RESPONSE: ${response.body}');
    print('====================================');

    final decoded = _decodeMap(response.body);

    if (response.statusCode == 200 && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data']);
    }

    throw Exception(
      decoded['message'] ?? 'Gagal mengambil profil nasabah.',
    );
  }

  // UPLOAD FOTO PROFIL NASABAH
  static Future<Map<String, dynamic>> uploadFotoProfilNasabah({
    required int idNasabah,
    required File foto,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/nasabah/$idNasabah/foto-profil'),
    );

    request.headers.addAll(_headers());

    final namaFile = foto.path.split('/').last.toLowerCase();

    String? mimeSubtype;

    if (namaFile.endsWith('.jpg') || namaFile.endsWith('.jpeg')) {
      mimeSubtype = 'jpeg';
    } else if (namaFile.endsWith('.png')) {
      mimeSubtype = 'png';
    } else if (namaFile.endsWith('.webp')) {
      mimeSubtype = 'webp';
    }

    if (mimeSubtype == null) {
      throw Exception('Format foto harus JPG, JPEG, PNG, atau WEBP');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'foto_profil',
        foto.path,
        contentType: MediaType('image', mimeSubtype),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('UPLOAD FOTO STATUS: ${response.statusCode}');
    print('UPLOAD FOTO RESPONSE: ${response.body}');

    final decoded = _decodeMap(response.body);

    if (response.statusCode == 200 && decoded['data'] is Map) {
      return Map<String, dynamic>.from(decoded['data']);
    }

    throw Exception(decoded['message'] ?? 'Gagal mengunggah foto profil.');
  }

  // HAPUS FOTO PROFIL NASABAH
  static Future<bool> hapusFotoProfilNasabah({required int idNasabah}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/nasabah/$idNasabah/foto-profil'),
      headers: _headers(),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(_decodeMap(response.body), 'Gagal menghapus foto profil.'),
    );
  }

  // UPDATE PROFIL NASABAH
  static Future<bool> updateProfilNasabah({
    required int idNasabah,
    required String namaLengkap,
    required String email,
    required String noTelepon,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/nasabah/$idNasabah/profil'),
      headers: _headers(json: true),
      body: jsonEncode({
        'nama_lengkap': namaLengkap,
        'email': email,
        'no_telepon': noTelepon,
      }),
    );

    final decoded = _decodeMap(response.body);

    if (response.statusCode == 200) return true;

    throw Exception(decoded['message'] ?? 'Gagal memperbarui profil.');
  }

  // UBAH PASSWORD NASABAH
  static Future<bool> ubahPasswordNasabah({
    required int idNasabah,
    required String passwordLama,
    required String passwordBaru,
    required String konfirmasiPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/nasabah/$idNasabah/password'),
      headers: _headers(json: true),
      body: jsonEncode({
        'password_lama': passwordLama,
        'password_baru': passwordBaru,
        'konfirmasi_password': konfirmasiPassword,
      }),
    );

    final decoded = _decodeMap(response.body);

    if (response.statusCode == 200) return true;

    throw Exception(decoded['message'] ?? 'Gagal mengubah password.');
  }

  // ==========================================================
  // NOTIFIKASI NASABAH
  // ==========================================================

  static Future<Map<String, dynamic>> getNotifikasiNasabah(
    int idNasabah,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/nasabah/$idNasabah/notifikasi'
        '?t=${DateTime.now().millisecondsSinceEpoch}',
      ),
      headers: {..._headers(), 'Cache-Control': 'no-cache'},
    );

    final decoded = _decodeMap(response.body);

    if (response.statusCode == 200) return decoded;

    throw Exception(decoded['message'] ?? 'Gagal mengambil notifikasi.');
  }

  static Future<bool> tandaiNotifikasiDibaca({
    required int idNasabah,
    required int idNotifikasi,
  }) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/nasabah/$idNasabah/notifikasi/'
        '$idNotifikasi/dibaca',
      ),
      headers: _headers(json: true),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(_decodeMap(response.body), 'Gagal menandai notifikasi.'),
    );
  }

  static Future<bool> tandaiSemuaNotifikasiDibaca(int idNasabah) async {
    final response = await http.put(
      Uri.parse('$baseUrl/nasabah/$idNasabah/notifikasi/dibaca-semua'),
      headers: _headers(json: true),
    );

    if (response.statusCode == 200) return true;

    throw Exception(
      _errorMessage(_decodeMap(response.body), 'Gagal memperbarui notifikasi.'),
    );
  }
}
