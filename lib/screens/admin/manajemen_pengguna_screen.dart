import 'package:flutter/material.dart';

class ManajemenPenggunaScreen extends StatefulWidget {
  const ManajemenPenggunaScreen({super.key});

  @override
  State<ManajemenPenggunaScreen> createState() =>
      _ManajemenPenggunaScreenState();
}

class _ManajemenPenggunaScreenState extends State<ManajemenPenggunaScreen> {
  // =========================================================
  // WARNA
  // =========================================================

  static const Color darkGreen = Color(0xFF075B4F);
  static const Color primaryGreen = Color(0xFF2E8B72);
  static const Color background = Color(0xFFF5F8F7);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF6B7280);

  // =========================================================
  // CONTROLLER
  // =========================================================

  final TextEditingController searchController = TextEditingController();

  // =========================================================
  // DATA DUMMY
  // =========================================================

  List<Map<String, dynamic>> users = [
    {
      'id': 1,
      'nama': 'Admin',
      'email': 'admin@banksampah.com',
      'telepon': '-',
      'password': '11111111',
      'role': 'Admin',
      'status': 'Aktif',
      'protected': true,
    },
    {
      'id': 2,
      'nama': 'Petugas',
      'email': 'pecel@gmail.com',
      'telepon': '-',
      'password': '11111111',
      'role': 'Petugas',
      'status': 'Aktif',
      'protected': false,
    },
    {
      'id': 3,
      'nama': 'Nasabah',
      'email': 'nasi@gmail.com',
      'telepon': '081234567890',
      'password': '11111111',
      'role': 'Nasabah',
      'status': 'Aktif',
      'protected': false,
    },
  ];

  // =========================================================
  // FILTER
  // =========================================================

  List<Map<String, dynamic>> get filteredUsers {
    final keyword = searchController.text.trim().toLowerCase();

    if (keyword.isEmpty) {
      return users;
    }

    return users.where((user) {
      return user['nama'].toString().toLowerCase().contains(keyword) ||
          user['email'].toString().toLowerCase().contains(keyword) ||
          user['telepon'].toString().toLowerCase().contains(keyword) ||
          user['role'].toString().toLowerCase().contains(keyword);
    }).toList();
  }

  // =========================================================
  // STATISTIK
  // =========================================================

  int get totalPengguna => users.length;

  int get totalAdmin => users.where((user) => user['role'] == 'Admin').length;

  int get totalPetugas =>
      users.where((user) => user['role'] == 'Petugas').length;

  int get totalNasabah =>
      users.where((user) => user['role'] == 'Nasabah').length;

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // TAMBAH PENGGUNA
  // =========================================================

  void showAddUserDialog() {
    final namaController = TextEditingController();
    final teleponController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    String selectedRole = 'Pilih Role';
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Tambah Pengguna Baru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Nama Lengkap'),
                      const SizedBox(height: 7),
                      _textField(
                        controller: namaController,
                        hint: 'Masukkan nama lengkap',
                        icon: Icons.person_outline,
                      ),

                      const SizedBox(height: 16),

                      _label('Nomor Telepon'),
                      const SizedBox(height: 7),
                      _textField(
                        controller: teleponController,
                        hint: 'Masukkan nomor telepon',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      _label('Email'),
                      const SizedBox(height: 7),
                      _textField(
                        controller: emailController,
                        hint: 'Masukkan email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 16),

                      _label('Password'),
                      const SizedBox(height: 7),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration:
                            _inputDecoration(
                              hint: 'Masukkan password',
                              icon: Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                      ),

                      const SizedBox(height: 16),

                      _label('Role'),
                      const SizedBox(height: 7),

                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: _inputDecoration(
                          hint: 'Pilih Role',
                          icon: Icons.admin_panel_settings_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Pilih Role',
                            child: Text('Pilih Role'),
                          ),
                          DropdownMenuItem(
                            value: 'Admin',
                            child: Text('Admin'),
                          ),
                          DropdownMenuItem(
                            value: 'Petugas',
                            child: Text('Petugas'),
                          ),
                          DropdownMenuItem(
                            value: 'Nasabah',
                            child: Text('Nasabah'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedRole = value ?? 'Pilih Role';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final nama = namaController.text.trim();
                    final telepon = teleponController.text.trim();
                    final email = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (nama.isEmpty ||
                        telepon.isEmpty ||
                        email.isEmpty ||
                        password.isEmpty ||
                        selectedRole == 'Pilih Role') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Semua data pengguna wajib diisi.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      users.add({
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'nama': nama,
                        'email': email,
                        'telepon': telepon,
                        'password': password,
                        'role': selectedRole,
                        'status': 'Aktif',
                        'protected': false,
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$nama berhasil ditambahkan.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // EDIT PENGGUNA
  // =========================================================

  void showEditUserDialog(Map<String, dynamic> user) {
    final namaController = TextEditingController(text: user['nama'].toString());

    String selectedRole = user['role'].toString();
    String selectedStatus = user['status'].toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Edit Pengguna',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nama Lengkap'),
                    const SizedBox(height: 7),
                    _textField(
                      controller: namaController,
                      hint: 'Masukkan nama lengkap',
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: 16),

                    _label('Role'),
                    const SizedBox(height: 7),

                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: _inputDecoration(
                        hint: 'Pilih Role',
                        icon: Icons.admin_panel_settings_outlined,
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
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRole = value ?? selectedRole;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    _label('Status'),
                    const SizedBox(height: 7),

                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: _inputDecoration(
                        hint: 'Pilih Status',
                        icon: Icons.toggle_on_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                        DropdownMenuItem(
                          value: 'Nonaktif',
                          child: Text('Nonaktif'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStatus = value ?? selectedStatus;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: textGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final nama = namaController.text.trim();

                    if (nama.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nama lengkap wajib diisi.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      user['nama'] = nama;
                      user['role'] = selectedRole;
                      user['status'] = selectedStatus;
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$nama berhasil diperbarui.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // HAPUS PENGGUNA
  // =========================================================

  void showDeleteUserDialog(Map<String, dynamic> user) {
    if (user['protected'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin utama tidak dapat dihapus.')),
      );
      return;
    }

    final nama = user['nama'].toString();
    final role = user['role'].toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ICON PERINGATAN
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Hapus Pengguna',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),

              const SizedBox(height: 10),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Apakah Anda yakin ingin menghapus '),
                    TextSpan(
                      text: '$role ($nama)',
                      style: const TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: '? Tindakan ini tidak dapat dibatalkan.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: textGrey, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  users.remove(user);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$nama berhasil dihapus.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'Ya, Lanjutkan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // INPUT
  // =========================================================

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
      filled: true,
      fillColor: const Color(0xFFF8FAFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9E1DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9E1DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }

  // =========================================================
  // STAT CARD
  // =========================================================

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBE9)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F5EF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: primaryGreen,
              size: 22,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: textGrey, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ROLE BADGE
  // =========================================================

  Widget _roleBadge(String role) {
    Color background;
    Color foreground;

    if (role == 'Admin') {
      background = const Color(0xFFF0E2FF);
      foreground = const Color(0xFF7C3AED);
    } else if (role == 'Petugas') {
      background = const Color(0xFFE0ECFF);
      foreground = const Color(0xFF2563EB);
    } else {
      background = const Color(0xFFD7F7E9);
      foreground = const Color(0xFF059669);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _statusBadge(String status) {
    final active = status == 'Aktif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD7F7E9) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: active ? const Color(0xFF059669) : const Color(0xFFDC2626),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // USER CARD
  // =========================================================

  Widget _userCard(Map<String, dynamic> user) {
    final nama = user['nama'].toString();
    final email = user['email'].toString();
    final telepon = user['telepon'].toString();
    final role = user['role'].toString();
    final status = user['status'].toString();
    final protected = user['protected'] == true;

    final initial = nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5EBE9)),
      ),
      child: Column(
        children: [
          // =================================================
          // BAGIAN ATAS
          // =================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFD7F7E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textGrey, fontSize: 12),
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          telepon,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _roleBadge(role),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(height: 1, color: Color(0xFFEDF1F0)),

          const SizedBox(height: 12),

          // =================================================
          // BAGIAN BAWAH
          // =================================================
          Row(
            children: [
              const Text(
                'Status',
                style: TextStyle(color: textGrey, fontSize: 11),
              ),

              const SizedBox(width: 8),

              _statusBadge(status),

              const Spacer(),

              // EDIT
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  showEditUserDialog(user);
                },
                child: Container(
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
              ),

              const SizedBox(width: 7),

              // HAPUS / LOCK
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (protected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Admin utama tidak dapat dihapus.'),
                      ),
                    );
                  } else {
                    showDeleteUserDialog(user);
                  }
                },
                child: Container(
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: protected
                        ? const Color(0xFFF3F4F6)
                        : const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    protected ? Icons.lock_outline : Icons.delete_outline,
                    color: protected ? const Color(0xFF9CA3AF) : Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: RefreshIndicator(
        color: primaryGreen,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // HEADER
              // =================================================

              const Text(
                'Kelola Pengguna',
                style: TextStyle(
                  color: textDark,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Manajemen data pengguna sistem bank sampah',
                style: TextStyle(color: textGrey, fontSize: 12),
              ),

              const SizedBox(height: 20),

              // =================================================
              // STATISTIK
              // =================================================
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      title: 'Total Pengguna',
                      value: '$totalPengguna',
                      subtitle: 'Semua role',
                      icon: Icons.people_outline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      title: 'Admin',
                      value: '$totalAdmin',
                      subtitle: 'Pengelola',
                      icon: Icons.admin_panel_settings_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      title: 'Petugas',
                      value: '$totalPetugas',
                      subtitle: 'Lapangan',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      title: 'Nasabah',
                      value: '$totalNasabah',
                      subtitle: 'Terdaftar',
                      icon: Icons.person_outline,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =================================================
              // TAMBAH PENGGUNA
              // =================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: showAddUserDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text(
                    'Tambah Pengguna',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // SEARCH
              // =================================================
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Cari pengguna...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF7B8794),
                    size: 20,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                          },
                          icon: const Icon(Icons.close, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: Color(0xFFDDE5E2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: Color(0xFFDDE5E2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: primaryGreen,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // JUDUL DAFTAR
              // =================================================
              Row(
                children: [
                  const Text(
                    'Daftar Pengguna',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${filteredUsers.length} pengguna',
                    style: const TextStyle(color: textGrey, fontSize: 11),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // =================================================
              // LIST USER
              // =================================================
              if (filteredUsers.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 45),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE5EBE9)),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.person_search_outlined,
                        size: 45,
                        color: Color(0xFF9CA3AF),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Pengguna tidak ditemukan',
                        style: TextStyle(color: textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...filteredUsers.map((user) => _userCard(user)),
            ],
          ),
        ),
      ),
    );
  }
}
