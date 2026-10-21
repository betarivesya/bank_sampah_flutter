import 'package:flutter/material.dart';

import '../../services/api_service.dart';

// ============================================================
// HALAMAN MANAJEMEN PENGGUNA
// ============================================================

class ManajemenPenggunaScreen extends StatefulWidget {
  const ManajemenPenggunaScreen({super.key});

  @override
  State<ManajemenPenggunaScreen> createState() =>
      _ManajemenPenggunaScreenState();
}

class _ManajemenPenggunaScreenState extends State<ManajemenPenggunaScreen> {
  // ============================================================
  // WARNA
  // ============================================================

  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color background = Color(0xFFF5F8F7);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF6B7280);

  // ============================================================
  // CONTROLLER SEARCH
  // ============================================================

  final TextEditingController searchController = TextEditingController();

  // ============================================================
  // FILTER
  // ============================================================

  String selectedRoleFilter = 'Semua';
  String selectedStatusFilter = 'Semua';

  // ============================================================
  // DATA PENGGUNA
  // ============================================================

  List<Map<String, dynamic>> users = [];

  bool isLoading = true;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {});
    });

    _loadUsers();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // MENGAMBIL DATA PENGGUNA DARI API
  // ============================================================

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await ApiService.getPengguna();

      if (!mounted) return;

      setState(() {
        users = data.map((user) {
          return {
            'id': user['id'],
            'nama': user['nama'] ?? '',
            'email': user['email'] ?? '',
            'telepon': user['telepon'] ?? '-',
            'role': user['role'] ?? '',
            'status': user['status'] == true ? 'Aktif' : 'Nonaktif',
            'protected': user['protected'] == true,
          };
        }).toList();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data pengguna: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // FILTER PENCARIAN
  // ============================================================

  List<Map<String, dynamic>> get filteredUsers {
    final keyword = searchController.text.trim().toLowerCase();

    return users.where((user) {
      final nama = user['nama']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final role = user['role']?.toString().toLowerCase() ?? '';
      final status = user['status']?.toString() ?? '';

      final cocokSearch =
          keyword.isEmpty ||
          nama.contains(keyword) ||
          email.contains(keyword) ||
          role.contains(keyword);

      final cocokRole =
          selectedRoleFilter == 'Semua' ||
          role == selectedRoleFilter.toLowerCase();

      final cocokStatus =
          selectedStatusFilter == 'Semua' || status == selectedStatusFilter;

      return cocokSearch && cocokRole && cocokStatus;
    }).toList();
  }

  // ============================================================
  // STATISTIK
  // ============================================================

  int get totalUsers => users.length;

  int get totalAdmin {
    return users
        .where((user) => user['role'].toString().toLowerCase() == 'admin')
        .length;
  }

  int get totalPetugas {
    return users
        .where((user) => user['role'].toString().toLowerCase() == 'petugas')
        .length;
  }

  int get totalNasabah {
    return users
        .where((user) => user['role'].toString().toLowerCase() == 'nasabah')
        .length;
  }

  // ============================================================
  // TAMBAH PENGGUNA
  // ============================================================

  void showAddUserDialog() {
    final namaController = TextEditingController();
    final teleponController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    String selectedRole = 'Nasabah';
    String selectedStatus = 'Aktif';

    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Tambah Pengguna',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // NAMA LENGKAP
                    // ==================================================

                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // NOMOR TELEPON
                    // ==================================================
                    TextField(
                      controller: teleponController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // EMAIL
                    // ==================================================
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // PASSWORD
                    // ==================================================
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // ROLE
                    // ==================================================
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Kategori Pengguna',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                        DropdownMenuItem(
                          value: 'Petugas',
                          child: Text('Petugas'),
                        ),
                        DropdownMenuItem(
                          value: 'Nasabah',
                          child: Text('Nasabah'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedRole = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // STATUS AKUN
                    // ==================================================
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status Akun',
                        prefixIcon: Icon(Icons.toggle_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                        DropdownMenuItem(
                          value: 'Nonaktif',
                          child: Text('Nonaktif'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedStatus = value;
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                // ==================================================
                // TOMBOL BATAL
                // ==================================================

                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Batal'),
                ),

                // ==================================================
                // TOMBOL SIMPAN
                // ==================================================
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (namaController.text.trim().isEmpty ||
                              teleponController.text.trim().isEmpty ||
                              emailController.text.trim().isEmpty ||
                              passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Semua data harus diisi.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password minimal 6 karakter.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await ApiService.tambahPengguna(
                              nama: namaController.text.trim(),
                              telepon: teleponController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text,
                              role: selectedRole,
                              status: selectedStatus == 'Aktif',
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await _loadUsers();

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pengguna berhasil ditambahkan.'),
                                backgroundColor: primaryGreen,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal menambahkan pengguna: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // EDIT PENGGUNA
  // ============================================================

  void showEditUserDialog(Map<String, dynamic> user) {
    final namaController = TextEditingController(
      text: user['nama']?.toString() ?? '',
    );

    String selectedRole = user['role']?.toString() ?? 'Nasabah';
    String selectedStatus = user['status']?.toString() ?? 'Aktif';

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Pengguna',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // NAMA
                    // ==================================================

                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // ROLE
                    // ==================================================
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Kategori Pengguna',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                        DropdownMenuItem(
                          value: 'Petugas',
                          child: Text('Petugas'),
                        ),
                        DropdownMenuItem(
                          value: 'Nasabah',
                          child: Text('Nasabah'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedRole = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // STATUS
                    // ==================================================
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status Akun',
                        prefixIcon: Icon(Icons.toggle_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                        DropdownMenuItem(
                          value: 'Nonaktif',
                          child: Text('Nonaktif'),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedStatus = value;
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                // ==================================================
                // TOMBOL BATAL
                // ==================================================

                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Batal'),
                ),

                // ==================================================
                // TOMBOL SIMPAN
                // ==================================================
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (namaController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama pengguna tidak boleh kosong.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await ApiService.updatePengguna(
                              id: int.parse(user['id'].toString()),
                              nama: namaController.text.trim(),
                              role: selectedRole,
                              status: selectedStatus == 'Aktif',
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await _loadUsers();

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Data pengguna berhasil diperbarui.',
                                ),
                                backgroundColor: primaryGreen,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal memperbarui pengguna: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // HAPUS PENGGUNA
  // ============================================================

  void showDeleteUserDialog(Map<String, dynamic> user) {
    if (user['protected'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin utama tidak dapat dihapus.'),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Hapus Pengguna',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Apakah kamu yakin ingin menghapus ${user['nama']}?'),
          actions: [
            // ==================================================
            // BATAL
            // ==================================================

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),

            // ==================================================
            // HAPUS
            // ==================================================
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await ApiService.deletePengguna(
                    int.parse(user['id'].toString()),
                  );

                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  await _loadUsers();

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengguna berhasil dihapus.'),
                      backgroundColor: primaryGreen,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus pengguna: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUsers,
          color: primaryGreen,

          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),

            padding: const EdgeInsets.only(bottom: 100),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER =====

                _buildHeader(),

                // ===== STATISTIK =====
                _buildStatistics(),

                // ===== SEARCH + FILTER =====
                _buildSearchBar(),

                // ===== DAFTAR PENGGUNA =====
                _buildUserList(),
              ],
            ),
          ),
        ),
      ),

      // ==========================================================
      // TOMBOL TAMBAH
      // ==========================================================
      floatingActionButton: FloatingActionButton(
        onPressed: showAddUserDialog,
        backgroundColor: darkGreen,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen Pengguna',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Kelola data admin, petugas, dan nasabah',
                  style: TextStyle(fontSize: 13, color: textGrey),
                ),
              ],
            ),
          ),

          // ==================================================
          // REFRESH
          // ==================================================
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh, color: darkGreen),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTIK
  // ============================================================

  Widget _buildStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Total',
              value: totalUsers.toString(),
              icon: Icons.people_outline,
              color: darkGreen,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildStatCard(
              title: 'Admin',
              value: totalAdmin.toString(),
              icon: Icons.admin_panel_settings_outlined,
              color: Colors.blue,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildStatCard(
              title: 'Petugas',
              value: totalPetugas.toString(),
              icon: Icons.badge_outlined,
              color: Colors.orange,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _buildStatCard(
              title: 'Nasabah',
              value: totalNasabah.toString(),
              icon: Icons.person_outline,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU STATISTIK
  // ============================================================

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),

          const SizedBox(height: 5),

          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 2),

          Text(title, style: const TextStyle(fontSize: 10, color: textGrey)),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH + FILTER
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // ==================================================
          // SEARCH
          // ==================================================

          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama, email, atau role...',
              prefixIcon: const Icon(Icons.search, color: textGrey),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ==================================================
          // FILTER
          // ==================================================
          Row(
            children: [
              // ==================================================
              // FILTER ROLE
              // ==================================================

              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedRoleFilter,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                      size: 20,
                      color: darkGreen,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Petugas', child: Text('Petugas')),
                    DropdownMenuItem(value: 'Nasabah', child: Text('Nasabah')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedRoleFilter = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // FILTER STATUS
              // ==================================================
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedStatusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status Akun',
                    prefixIcon: const Icon(
                      Icons.toggle_on_outlined,
                      size: 20,
                      color: darkGreen,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'Nonaktif',
                      child: Text('Nonaktif'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedStatusFilter = value;
                    });
                  },
                ),
              ),
            ],
          ),

          // ==================================================
          // RESET FILTER
          // ==================================================
          if (selectedRoleFilter != 'Semua' ||
              selectedStatusFilter != 'Semua' ||
              searchController.text.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    selectedRoleFilter = 'Semua';
                    selectedStatusFilter = 'Semua';
                    searchController.clear();
                  });
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Reset Filter'),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // DAFTAR PENGGUNA
  // ============================================================

  Widget _buildUserList() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    if (filteredUsers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: textGrey),

            SizedBox(height: 16),

            Center(
              child: Text(
                'Data pengguna tidak ditemukan.',
                style: TextStyle(color: textGrey, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // PERBAIKAN SCROLL
    // ListView.builder dihapus karena sudah berada di dalam
    // SingleChildScrollView pada build().
    // ==========================================================

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: filteredUsers.map((user) {
          return _buildUserCard(user);
        }).toList(),
      ),
    );
  }

  // ============================================================
  // CARD PENGGUNA
  // ============================================================

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role']?.toString() ?? '';
    final status = user['status']?.toString() ?? 'Nonaktif';

    final isActive = status == 'Aktif';

    Color roleColor;
    IconData roleIcon;

    switch (role.toLowerCase()) {
      case 'admin':
        roleColor = Colors.blue;
        roleIcon = Icons.admin_panel_settings_outlined;
        break;

      case 'petugas':
        roleColor = Colors.orange;
        roleIcon = Icons.badge_outlined;
        break;

      default:
        roleColor = primaryGreen;
        roleIcon = Icons.person_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // ICON ROLE
            // ==================================================

            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(roleIcon, color: roleColor),
            ),

            const SizedBox(width: 12),

            // ==================================================
            // INFORMASI PENGGUNA
            // ==================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nama']?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    user['email']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 12, color: textGrey),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    user['telepon']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 12, color: textGrey),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // ==================================================
                      // ROLE
                      // ==================================================

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),

                      // ==================================================
                      // STATUS
                      // ==================================================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ==================================================
            // MENU AKSI
            // ==================================================
            if (user['protected'] == true)
              IconButton(
                tooltip: 'Edit Admin Utama',
                onPressed: () => showEditUserDialog(user),
                icon: const Icon(Icons.edit_outlined, color: darkGreen),
              )
            else
              PopupMenuButton<String>(
                tooltip: 'Aksi Pengguna',
                onSelected: (value) {
                  if (value == 'edit') {
                    showEditUserDialog(user);
                  } else if (value == 'delete') {
                    showDeleteUserDialog(user);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert, color: textGrey),
              ),
          ],
        ),
      ),
    );
  }
}
