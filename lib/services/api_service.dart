import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;

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
  static const String baseUrl = 'http://10.10.186.237:8000/api';
  static String? _authToken;
  static String? _sessionCookie;

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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token =
            data['token'] ??
            data['access_token'] ??
            (data['data'] is Map
                ? data['data']['token'] ?? data['data']['access_token']
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
          'user': data['user'],
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
  // DASHBOARD ADMIN
  // ==========================================================
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard'),
        headers: {'Accept': 'application/json'},
      );

      print('GET ADMIN DASHBOARD STATUS: ${response.statusCode}');
      print('GET ADMIN DASHBOARD RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return Map<String, dynamic>.from(data['data']);
      }

      final data = jsonDecode(response.body);

      throw Exception(data['message'] ?? 'Gagal mengambil dashboard admin');
    } catch (e) {
      print('GET ADMIN DASHBOARD ERROR: $e');
      rethrow;
    }
  }

  // ==========================================================
  // JENIS SAMPAH
  // ==========================================================

  static Future<List<JenisSampah>> getJenisSampah() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/jenis-sampah?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      print('GET JENIS SAMPAH STATUS: ${response.statusCode}');
      print('GET JENIS SAMPAH RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data
            .map((item) => JenisSampah.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw Exception(
        'Gagal mengambil data jenis sampah. '
        'Status: ${response.statusCode}',
      );
    } catch (e) {
      print('GET JENIS SAMPAH ERROR: $e');
      rethrow;
    }
  }

  // ==========================================================
  // TAMBAH JENIS SAMPAH + HARGA
  // ==========================================================

  static Future<bool> tambahJenisSampah({
    required String namaSampah,
    required int hargaPerKg,
    required bool status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jenis-sampah-dengan-harga'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_sampah': namaSampah,
        'harga_per_kg': hargaPerKg,
        'status': status,
      }),
    );

    print('TAMBAH JENIS STATUS: ${response.statusCode}');
    print('TAMBAH JENIS RESPONSE: ${response.body}');

    if (response.statusCode == 201) {
      return true;
    }

    final data = jsonDecode(response.body);

    throw Exception(data['message'] ?? 'Gagal menambahkan jenis sampah');
  }

  // ==========================================================
  // UPDATE JENIS SAMPAH + HARGA
  // ==========================================================

  static Future<bool> updateJenisSampah({
    required int id,
    required String namaSampah,
    required int hargaPerKg,
    required bool status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/jenis-sampah/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nama_sampah': namaSampah,
        'harga_per_kg': hargaPerKg,
        'status': status,
      }),
    );

    print('UPDATE JENIS STATUS: ${response.statusCode}');
    print('UPDATE JENIS RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    }

    final data = jsonDecode(response.body);

    throw Exception(data['message'] ?? 'Gagal memperbarui jenis sampah');
  }

  // ==========================================================
  // HAPUS JENIS SAMPAH
  // ==========================================================

  static Future<bool> deleteJenisSampah({
    required int idJenisSampah,
    int? idHarga,
  }) async {
    // Jika memiliki data harga, gunakan endpoint
    // DELETE /harga-sampah/{id}
    //
    // Karena controller Laravel kamu memang menghapus
    // harga + jenis sampah sekaligus.

    if (idHarga != null) {
      final response = await http.delete(
        Uri.parse('$baseUrl/harga-sampah/$idHarga'),
        headers: {'Accept': 'application/json'},
      );

      print('DELETE HARGA STATUS: ${response.statusCode}');
      print('DELETE HARGA RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }

      final data = jsonDecode(response.body);

      throw Exception(data['message'] ?? 'Gagal menghapus jenis sampah');
    }

    // Jika tidak memiliki harga
    final response = await http.delete(
      Uri.parse('$baseUrl/jenis-sampah/$idJenisSampah'),
      headers: {'Accept': 'application/json'},
    );

    print('DELETE JENIS STATUS: ${response.statusCode}');
    print('DELETE JENIS RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    }

    final data = jsonDecode(response.body);

    throw Exception(data['message'] ?? 'Gagal menghapus jenis sampah');
  }

  // ==========================================================
  // HARGA SAMPAH
  // ==========================================================

  static Future<List<dynamic>> getHargaSampah() async {
    final response = await http.get(
      Uri.parse('$baseUrl/harga-sampah'),
      headers: {'Accept': 'application/json'},
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
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id_jenis_sampah': idJenisSampah,
        'harga_per_kg': hargaPerKg,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    }

    final data = jsonDecode(response.body);

    throw Exception(data['message'] ?? 'Gagal menambahkan harga sampah');
  }

  static Future<bool> updateHargaSampah(int idHarga, int hargaPerKg) async {
    final response = await http.put(
      Uri.parse('$baseUrl/harga-sampah/$idHarga'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'harga_per_kg': hargaPerKg}),
    );

    if (response.statusCode == 200) {
      return true;
    }

    final data = jsonDecode(response.body);

    throw Exception(data['message'] ?? 'Gagal memperbarui harga sampah');
  }

  static Future<bool> deleteHargaSampah(int idHarga) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/harga-sampah/$idHarga'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return true;
    }

    final data = jsonDecode(response.body);

    throw Exception(data['message'] ?? 'Gagal menghapus harga sampah');
  }

  // ==========================================================
  // MANAJEMEN PENGGUNA - GET DATA
  // ==========================================================

  static Future<List<Map<String, dynamic>>> getPengguna() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/pengguna?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      print('GET PENGGUNA STATUS: ${response.statusCode}');
      print('GET PENGGUNA RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
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

      throw Exception(
        'Gagal mengambil data pengguna. '
        'Status: ${response.statusCode}',
      );
    } catch (e) {
      print('GET PENGGUNA ERROR: $e');
      rethrow;
    }
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

  // ==========================================================
  // MANAJEMEN PENGGUNA - TAMBAH
  // ==========================================================

  static Future<bool> tambahPengguna({
    required String nama,
    required String telepon,
    required String email,
    required String password,
    required String role,
    required bool status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pengguna'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': nama,
          'no_telepon': telepon,
          'email': email,
          'password': password,
          'role': role.toLowerCase(),
          'status': status,
        }),
      );

      print('TAMBAH PENGGUNA STATUS: ${response.statusCode}');
      print('TAMBAH PENGGUNA RESPONSE: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      }

      final data = jsonDecode(response.body);

      throw Exception(data['message'] ?? 'Gagal menambahkan pengguna');
    } catch (e) {
      print('TAMBAH PENGGUNA ERROR: $e');
      rethrow;
    }
  }

  // ==========================================================
  // MANAJEMEN PENGGUNA - UPDATE
  // ==========================================================

  static Future<bool> updatePengguna({
    required int id,
    required String nama,
    required String role,
    required bool status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pengguna/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': nama,
          'role': role.toLowerCase(),
          'status': status,
        }),
      );

      print('UPDATE PENGGUNA STATUS: ${response.statusCode}');
      print('UPDATE PENGGUNA RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }

      final data = jsonDecode(response.body);

      throw Exception(data['message'] ?? 'Gagal memperbarui pengguna');
    } catch (e) {
      print('UPDATE PENGGUNA ERROR: $e');
      rethrow;
    }
  }

  // ==========================================================
  // MANAJEMEN PENGGUNA - HAPUS
  // ==========================================================

  static Future<bool> deletePengguna(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/pengguna/$id'),
        headers: {'Accept': 'application/json'},
      );

      print('DELETE PENGGUNA STATUS: ${response.statusCode}');
      print('DELETE PENGGUNA RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }

      final data = jsonDecode(response.body);

      throw Exception(data['message'] ?? 'Gagal menghapus pengguna');
    } catch (e) {
      print('DELETE PENGGUNA ERROR: $e');
      rethrow;
    }
  }

  // ============================================================
  // NOTIFIKASI ADMIN
  // ============================================================

  static Future<Map<String, dynamic>> getNotifikasiAdmin() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/admin/notifikasi'
        '?t=${DateTime.now().millisecondsSinceEpoch}',
      ),
      headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
    );

    final dynamic decoded = jsonDecode(response.body);

    if (response.statusCode == 200 && decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    final message = decoded is Map ? decoded['message']?.toString() : null;

    throw Exception(message ?? 'Gagal mengambil notifikasi admin.');
  }

  static Future<bool> tandaiNotifikasiAdminDibaca(int idNotifikasi) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/notifikasi/$idNotifikasi/dibaca'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    final dynamic decoded = jsonDecode(response.body);
    final message = decoded is Map ? decoded['message']?.toString() : null;

    throw Exception(message ?? 'Gagal menandai notifikasi');
  }

  static Future<bool> tandaiSemuaNotifikasiAdminDibaca() async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/notifikasi/dibaca-semua'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return true;
    }

    final dynamic decoded = jsonDecode(response.body);
    final message = decoded is Map ? decoded['message']?.toString() : null;

    throw Exception(message ?? 'Gagal memperbarui notifikasi admin.');
  }

  // ============================================================
  // DASHBOARD PETUGAS
  // ============================================================

  static Future<Map<String, dynamic>> getPetugasDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/petugas/dashboard'),
        headers: _headers(),
      );

      print('GET PETUGAS DASHBOARD STATUS: ${response.statusCode}');
      print('GET PETUGAS DASHBOARD RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return Map<String, dynamic>.from(data['data']);
      }

      final data = jsonDecode(response.body);

      throw Exception(data['message'] ?? 'Gagal mengambil dashboard petugas');
    } catch (e) {
      print('GET PETUGAS DASHBOARD ERROR: $e');
      rethrow;
    }
  }

  // ============================================================
  // DATA SETORAN
  // ============================================================
  static Future<List<SetoranModel>> getSetoran({int? bulan, int? tahun}) async {
    try {
      final uri = Uri.parse('$baseUrl/petugas/setoran').replace(
        queryParameters: {
          if (bulan != null) 'bulan': '$bulan',
          if (tahun != null) 'tahun': '$tahun',
        },
      );
      final response = await http.get(uri, headers: _headers());

      print('GET SETORAN STATUS: ${response.statusCode}');
      print('GET SETORAN RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dynamic items = decoded is List
            ? decoded
            : decoded is Map
            ? decoded['data']
            : null;

        if (items is! List) {
          throw Exception('Format respons data setoran tidak sesuai');
        }

        return items
            .map(
              (item) => SetoranModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      final data = jsonDecode(response.body);

      throw Exception(data['message'] ?? 'Gagal mengambil data setoran');
    } catch (e) {
      print('GET SETORAN ERROR: $e');
      rethrow;
    }
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

  // ============================================================
  // TAMBAH SETORAN
  // ============================================================
  static Future<Map<String, dynamic>> tambahSetoran({
    required int idNasabah,
    required int idPetugas,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/petugas/setoran');

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

      print('========== TAMBAH SETORAN ==========');
      print('URL: $uri');
      print('BODY: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: _headers(json: true),
        body: jsonEncode(body),
      );

      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.body}');
      print('====================================');

      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Setoran berhasil disimpan',
          'data': data['data'],
        };
      }

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first.toString());
        }
      }

      throw Exception(data['message'] ?? 'Gagal menyimpan setoran');
    } catch (e) {
      print('TAMBAH SETORAN ERROR: $e');
      rethrow;
    }
  }

  // ============================================================
  // DATA NASABAH
  // ============================================================
  static Future<List<Map<String, dynamic>>> getNasabah() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/petugas/nasabah'),
        headers: {..._headers(), 'Cache-Control': 'no-cache'},
      );

      print('GET NASABAH STATUS: ${response.statusCode}');
      print('GET NASABAH RESPONSE: ${response.body}');

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Mendukung respons array langsung maupun objek berisi data.
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

      final message = decoded is Map ? decoded['message']?.toString() : null;

      throw Exception(message ?? 'Gagal mengambil data nasabah');
    } catch (e) {
      print('GET NASABAH ERROR: $e');
      rethrow;
    }
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
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200 || decoded is! Map) {
      throw Exception(
        decoded is Map
            ? decoded['message'] ?? 'Gagal mengambil detail nasabah'
            : 'Gagal mengambil detail nasabah',
      );
    }
    return Map<String, dynamic>.from(decoded['data'] as Map);
  }

  // ============================================================
  // DATA PENARIKAN NASABAH
  // ============================================================
  static Future<Map<String, dynamic>> ajukanPenarikan({
    required int idNasabah,
    required double nominal,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/nasabah/penarikan'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_pengguna_nasabah': idNasabah,
          'nominal': nominal,
        }),
      );

      print('AJUKAN PENARIKAN STATUS: ${response.statusCode}');
      print('AJUKAN PENARIKAN RESPONSE: ${response.body}');

      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Pengajuan penarikan berhasil dibuat.',
          'data': data['data'],
        };
      }

      String message =
          data['message']?.toString() ?? 'Gagal mengajukan penarikan';

      final errors = data['errors'];
      if (response.statusCode == 422 && errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List && firstError.isNotEmpty) {
          message = firstError.first.toString();
        }
      }

      return {'success': false, 'message': message};
    } catch (e) {
      print('AJUKAN PENARIKAN ERROR: $e');
      throw Exception('Tidak dapat memproses permintaan ke server: $e');
    }
  }

  // =======================
  // RIWAYAT PENARIKAN
  // =======================
  static Future<List<Map<String, dynamic>>> getRiwayatPenarikanNasabah(
    int idNasabah,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nasabah/$idNasabah/penarikan'),
        headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
      );

      print('RIWAYAT PENARIKAN STATUS: ${response.statusCode}');
      print('RIWAYAT PENARIKAN RESPONSE: ${response.body}');

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
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

      final message = decoded is Map ? decoded['message']?.toString() : null;

      throw Exception(message ?? 'Gagal mengambil riwayat penarikan');
    } catch (e) {
      print('RIWAYAT PENARIKAN ERROR: $e');
      rethrow;
    }
  }

  // ============================================================
  // DATA PENARIKAN PETUGAS
  // ============================================================

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
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Gagal mengambil daftar penarikan');
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
    int number(String key, int fallback) =>
        int.tryParse(meta[key]?.toString() ?? '') ?? fallback;

    return PetugasPage<T>(
      items: data
          .map((item) => mapItem(Map<String, dynamic>.from(item as Map)))
          .toList(),
      currentPage: number('current_page', 1),
      lastPage: number('last_page', 1),
      total: number('total', data.length),
    );
  }

  // ============================================================
  // CARI PENARIKAN BERDASARKAN KODE VERIFIKASI
  // ============================================================

  static Future<Map<String, dynamic>> cariPenarikanPetugas(
    String kodeVerifikasi,
  ) async {
    final uri = Uri.parse('$baseUrl/petugas/penarikan/cari').replace(
      queryParameters: {'kode_verifikasi': kodeVerifikasi.trim().toUpperCase()},
    );

    final response = await http.get(uri, headers: _headers());

    print('CARI PENARIKAN STATUS: ${response.statusCode}');
    print('CARI PENARIKAN RESPONSE: ${response.body}');

    final decoded = jsonDecode(response.body);
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (response.statusCode == 200) {
      final detail = data['data'];

      if (detail is! Map) {
        throw Exception('Detail pengajuan tidak ditemukan.');
      }

      return Map<String, dynamic>.from(detail);
    }

    throw Exception(data['message'] ?? 'Pengajuan penarikan tidak ditemukan.');
  }

  // ============================================================
  // PROSES PENARIKAN PETUGAS
  // ============================================================

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
      body: jsonEncode({'status': status, 'id_petugas': idPetugas}),
    );

    print('PROSES PENARIKAN STATUS: ${response.statusCode}');
    print('PROSES PENARIKAN RESPONSE: ${response.body}');

    final decoded = jsonDecode(response.body);
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'] ?? 'Penarikan berhasil diproses.',
        'data': data['data'],
      };
    }

    throw Exception(data['message'] ?? 'Gagal memproses penarikan.');
  }

  // ============================================================
  // PROFIL NASABAH
  // ============================================================

  static Future<Map<String, dynamic>> getProfilNasabah(int idNasabah) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nasabah/$idNasabah/profil'),
        headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
      );

      print('GET PROFIL NASABAH STATUS: ${response.statusCode}');
      print('GET PROFIL NASABAH RESPONSE: ${response.body}');

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map) {
        final dynamic profil = decoded['data'];

        if (profil is Map) {
          return Map<String, dynamic>.from(profil);
        }

        throw Exception('Format data profil tidak sesuai.');
      }

      final message = decoded is Map ? decoded['message']?.toString() : null;

      throw Exception(message ?? 'Gagal mengambil profil nasabah.');
    } catch (e) {
      print('GET PROFIL NASABAH ERROR: $e');
      rethrow;
    }
  }

  // ==========================================================
  // UPDATE FOTO PROFIL NASABAH
  // ==========================================================

  static Future<Map<String, dynamic>> uploadFotoProfilNasabah({
    required int idNasabah,
    required File foto,
  }) async {
    final uploadUrl = '$baseUrl/nasabah/$idNasabah/foto-profil';

    print('UPLOAD FOTO URL: $uploadUrl');

    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

    request.headers['Accept'] = 'application/json';

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

    final dynamic decoded = jsonDecode(response.body);

    if (response.statusCode == 200 && decoded is Map) {
      final dynamic data = decoded['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception('Respons foto profil tidak sesuai');
    }

    final message = decoded is Map ? decoded['message']?.toString() : null;

    throw Exception(message ?? 'Gagal mengunggah foto profil.');
  }

  // ==========================================================
  // HAPUS FOTO PROFIL NASABAH
  // ==========================================================

  static Future<bool> hapusFotoProfilNasabah({required int idNasabah}) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/nasabah/$idNasabah/foto-profil"),
      headers: {'Accept': 'application/json'},
    );

    print('HAPUS FOTO STATUS: ${response.statusCode}');
    print('HAPUS FOTO RESPONSE: ${response.body}');

    final dynamic decoded = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return true;
    }

    final message = decoded is Map ? decoded['message']?.toString() : null;

    throw Exception(message ?? 'Gagal menghapus foto profil.');
  }

  // ==========================================================
  // UPDATE PROFIL NASABAH
  // ==========================================================

  static Future<bool> updateProfilNasabah({
    required int idNasabah,
    required String namaLengkap,
    required String email,
    required String noTelepon,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/nasabah/$idNasabah/profil');

      final response = await http.put(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama_lengkap': namaLengkap,
          'email': email,
          'no_telepon': noTelepon,
        }),
      );

      print('UPDATE PROFIL URL: $uri');
      print('UPDATE PROFIL STATUS: ${response.statusCode}');
      print('UPDATE PROFIL RESPONSE: ${response.body}');

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return true;
      }

      final message = decoded is Map ? decoded['message']?.toString() : null;

      throw Exception(message ?? 'Gagal memperbarui profil.');
    } catch (e) {
      print('UPDATE PROFIL ERROR: $e');
      rethrow;
    }
  }

  // ==========================================================
  // UBAH PASSWORD NASABAH
  // ==========================================================
  static Future<bool> ubahPasswordNasabah({
    required int idNasabah,
    required String passwordLama,
    required String passwordBaru,
    required String konfirmasiPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/nasabah/$idNasabah/password'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'password_lama': passwordLama,
        'password_baru': passwordBaru,
        'konfirmasi_password': konfirmasiPassword,
      }),
    );

    final dynamic decoded = jsonDecode(response.body);

    if (response.statusCode == 200) return true;

    final message = decoded is Map ? decoded['message']?.toString() : null;

    throw Exception(message ?? 'Gagal mengubah password.');
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
      headers: {'Accept': 'application/json', 'Cache-Control': 'no-cache'},
    );

    print('GET NOTIFIKASI STATUS: ${response.statusCode}');
    print('GET NOTIFIKASI RESPONSE: ${response.body}');

    final dynamic decoded = jsonDecode(response.body);

    if (response.statusCode == 200 && decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    final message = decoded is Map ? decoded['message']?.toString() : null;

    throw Exception(message ?? 'Gagal mengambil notifikasi.');
  }

  // Tandai satu notifikasi sudah dibaca.
  static Future<bool> tandaiNotifikasiDibaca({
    required int idNasabah,
    required int idNotifikasi,
  }) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/nasabah/$idNasabah/notifikasi/'
        '$idNotifikasi/dibaca',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    print('TANDAI NOTIFIKASI STATUS: ${response.statusCode}');
    print('TANDAI NOTIFIKASI RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    }

    final dynamic decoded = jsonDecode(response.body);
    final message = decoded is Map ? decoded['message']?.toString() : null;

    throw Exception(message ?? 'Gagal menandai notifikasi.');
  }

  // Tandai semua notifikasi sudah dibaca.
  static Future<bool> tandaiSemuaNotifikasiDibaca(int idNasabah) async {
    final response = await http.put(
      Uri.parse('$baseUrl/nasabah/$idNasabah/notifikasi/dibaca-semua'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    print('TANDAI SEMUA STATUS: ${response.statusCode}');
    print('TANDAI SEMUA RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    }

    final dynamic decoded = jsonDecode(response.body);
    final message = decoded is Map ? decoded['message']?.toString() : null;

    throw Exception(message ?? 'Gagal memperbarui notifikasi.');
  }
}
