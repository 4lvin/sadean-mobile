import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text("Kebijakan Privasi"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        constraints: BoxConstraints(maxWidth: isTablet ? 800 : double.infinity),
        margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 0),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kebijakan Privasi",
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Terakhir diperbarui: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),

              _buildSection(
                "1. Informasi yang Kami Kumpulkan",
                "Kami mengumpulkan informasi yang Anda berikan secara langsung kepada kami, seperti ketika Anda membuat akun, menggunakan layanan kami, atau menghubungi kami untuk mendapatkan dukungan.",
                isTablet,
              ),

              _buildSection(
                "2. Bagaimana Kami Menggunakan Informasi",
                "Kami menggunakan informasi yang kami kumpulkan untuk menyediakan, memelihara, dan meningkatkan layanan kami, memproses transaksi, dan berkomunikasi dengan Anda.",
                isTablet,
              ),

              _buildSection(
                "3. Berbagi Informasi",
                "Kami tidak menjual, memperdagangkan, atau mentransfer informasi pribadi Anda kepada pihak ketiga tanpa persetujuan Anda, kecuali dalam keadaan tertentu yang dijelaskan dalam kebijakan ini.",
                isTablet,
              ),

              _buildSection(
                "4. Keamanan Data",
                "Kami menerapkan berbagai langkah keamanan untuk melindungi informasi pribadi Anda. Data Anda disimpan dalam jaringan yang aman dan hanya dapat diakses oleh sejumlah kecil orang yang memiliki hak akses khusus.",
                isTablet,
              ),

              _buildSection(
                "5. Hak Anda",
                "Anda memiliki hak untuk mengakses, memperbarui, atau menghapus informasi pribadi Anda. Anda juga dapat meminta kami untuk membatasi pemrosesan data Anda dalam keadaan tertentu.",
                isTablet,
              ),

              _buildSection(
                "6. Perubahan Kebijakan",
                "Kami dapat memperbarui kebijakan privasi ini dari waktu ke waktu. Kami akan memberi tahu Anda tentang perubahan dengan memposting kebijakan privasi yang baru di halaman ini.",
                isTablet,
              ),

              _buildSection(
                "7. Hubungi Kami",
                "Jika Anda memiliki pertanyaan tentang kebijakan privasi ini, silakan hubungi kami di privacy@example.com atau melalui formulir kontak di aplikasi.",
                isTablet,
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            height: 1.6,
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}