import 'package:flutter/material.dart';
import 'api_service.dart';
import 'jenis_sampah_model.dart';

class JenisSampahScreen extends StatefulWidget {
  const JenisSampahScreen({Key? key}) : super(key: key);

  @override
  State<JenisSampahScreen> createState() => _JenisSampahScreenState();
}

class _JenisSampahScreenState extends State<JenisSampahScreen> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<JenisSampah>> _futureData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _futureData = ApiService.getJenisSampah();
    });
  }

  void _simpanData() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama sampah tidak boleh kosong!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool sukses = await ApiService.tambahJenisSampah(text);

    setState(() {
      _isLoading = false;
    });

    if (sukses) {
      _controller.clear();
      _refreshData(); // Refresh list otomatis setelah berhasil tambah
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menambahkan data!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data ke server.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Jenis Sampah'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nama Jenis Sampah',
                      hintText: 'Misal: Botol Plastik',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? const CircularProgressIndicator()
                    : IconButton.filled(
                        onPressed: _simpanData,
                        icon: const Icon(Icons.add),
                      ),
              ],
            ),
            const SizedBox(height: 20),

            // Daftar Data
            Expanded(
              child: FutureBuilder<List<JenisSampah>>(
                future: _futureData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Terjadi error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Belum ada data.'));
                  }

                  final listData = snapshot.data!;
                  return ListView.builder(
                    itemCount: listData.length,
                    itemBuilder: (context, index) {
                      final item = listData[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${item.idJenisSampah}'),
                          ),
                          title: Text(item.namaSampah),
                          subtitle: Text('Status: ${item.status}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}