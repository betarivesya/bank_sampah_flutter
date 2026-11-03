import 'package:flutter/material.dart';

import '../../models/setoran_model.dart';
import '../../services/api_service.dart';

class DetailNasabahApiScreen extends StatefulWidget {
  final Map<String, dynamic> nasabah;

  const DetailNasabahApiScreen({super.key, required this.nasabah});

  @override
  State<DetailNasabahApiScreen> createState() => _DetailNasabahApiScreenState();
}

class _DetailNasabahApiScreenState extends State<DetailNasabahApiScreen> {
  List<SetoranModel> setoran = [];
  List<Map<String, dynamic>> penarikan = [];
  bool loading = true;
  String? error;

  int get id =>
      int.tryParse(
        (widget.nasabah['id_pengguna'] ??
                    widget.nasabah['id_nasabah'] ??
                    widget.nasabah['id'])
                ?.toString() ??
            '',
      ) ??
      0;

  String _text(String key, [String fallback = '-']) =>
      widget.nasabah[key]?.toString() ?? fallback;

  double _number(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await ApiService.getPetugasNasabahDetail(id);
      final rawSetoran = detail['setoran'] ?? detail['riwayat_setoran'] ?? [];
      final rawPenarikan =
          detail['penarikan'] ?? detail['riwayat_penarikan'] ?? [];
      if (!mounted) return;
      setState(() {
        setoran = rawSetoran is List
            ? rawSetoran
                  .map(
                    (item) => SetoranModel.fromJson(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  )
                  .toList()
            : [];
        penarikan = rawPenarikan is List
            ? rawPenarikan
                  .map((item) => Map<String, dynamic>.from(item as Map))
                  .toList()
            : [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_text('nama', 'Detail Nasabah'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_text('nama', 'Nasabah')),
              subtitle: Text(_text('no_hp', _text('no_telp'))),
              trailing: Text('Rp ${_number(widget.nasabah['saldo']).round()}'),
            ),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              Text(error!, textAlign: TextAlign.center)
            else ...[
              _section(
                'Riwayat Setoran',
                setoran
                    .map(
                      (item) => ListTile(
                        leading: const Icon(Icons.recycling),
                        title: Text(item.namaSampah),
                        subtitle: Text(
                          '${item.totalBerat} Kg • ${item.tanggal}',
                        ),
                        trailing: Text('Rp ${item.totalNilai.round()}'),
                      ),
                    )
                    .toList(),
              ),
              _section(
                'Riwayat Penarikan',
                penarikan
                    .map(
                      (item) => ListTile(
                        leading: const Icon(Icons.account_balance_wallet),
                        title: Text(
                          item['kode_verifikasi']?.toString() ?? 'Penarikan',
                        ),
                        subtitle: Text(
                          '${item['tgl_pengajuan'] ?? '-'} • ${item['status'] ?? '-'}',
                        ),
                        trailing: Text(
                          'Rp ${_number(item['nominal']).round()}',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (children.isEmpty) const ListTile(title: Text('Belum ada data.')),
        ...children,
      ],
    ),
  );
}
