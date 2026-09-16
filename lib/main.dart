import 'package:flutter/material.dart';
import 'jenis_sampah_model.dart';
import 'api_service.dart';

void main() {
  runApp(const MaterialApp(home: JenisSampahPage()));
}

class JenisSampahPage extends StatefulWidget {
  const JenisSampahPage({super.key});

  @override
  State<JenisSampahPage> createState() => _JenisSampahPageState();
}

class _JenisSampahPageState extends State<JenisSampahPage> {
  final TextEditingController _controller = TextEditingController();
  late Future<List<JenisSampah>> _listJenisSampah;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _listJenisSampah = ApiService.getJenisSampah();
    });
  }

  void _tambahData() async {
    if (_controller.text.isNotEmpty) {
      bool sukses = await ApiService.tambahJenisSampah(_controller.text);
      if (sukses) {
        _controller.clear();
        _refreshData(); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Jenis Sampah')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Diubah dari style: menjadi child:
          children: [
            // tamnah data
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nama Jenis Sampah',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _tambahData,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // List Data dari API
            Expanded(
              child: FutureBuilder<List<JenisSampah>>(
                future: _listJenisSampah,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Belum ada data.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data![index];
                      return ListTile(
                        title: Text(item.namaJenis),
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