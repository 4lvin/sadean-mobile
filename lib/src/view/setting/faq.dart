import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:url_launcher/url_launcher.dart';

// FAQ Page
class FAQPage extends StatelessWidget {
  final List<Map<String, String>> faqData = [
    {
      'question': 'Bagaimana cara menggunakan aplikasi ini?',
      'answer': 'Anda dapat menggunakan aplikasi ini dengan mendaftar terlebih dahulu, kemudian login menggunakan akun yang telah dibuat. Setelah itu Anda dapat mengakses semua fitur yang tersedia.'
    },
    {
      'question': 'Apakah aplikasi ini gratis?',
      'answer': 'Ya, aplikasi ini gratis untuk digunakan. Namun beberapa fitur premium mungkin memerlukan berlangganan atau pembayaran tertentu.'
    },
    {
      'question': 'Bagaimana cara menghubungi customer service?',
      'answer': 'Anda dapat menghubungi customer service melalui menu "Hubungi Kami" di halaman profil, atau langsung melalui email support@example.com'
    },
    {
      'question': 'Apakah data saya aman?',
      'answer': 'Ya, kami menjamin keamanan data Anda. Semua data dienkripsi dan disimpan dengan standar keamanan tinggi sesuai dengan kebijakan privasi kami.'
    },
    {
      'question': 'Bagaimana cara mengubah password?',
      'answer': 'Untuk mengubah password, masuk ke menu Pengaturan > Keamanan > Ubah Password. Masukkan password lama dan password baru Anda.'
    },
    {
      'question': 'Aplikasi tidak bisa dibuka, apa yang harus dilakukan?',
      'answer': 'Coba restart aplikasi atau restart device Anda. Jika masih bermasalah, pastikan Anda menggunakan versi aplikasi terbaru atau hubungi customer service.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text("FAQ"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        constraints: BoxConstraints(maxWidth: isTablet ? 800 : double.infinity),
        margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 0),
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: faqData.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  faqData[index]['question']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      faqData[index]['answer']!,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}