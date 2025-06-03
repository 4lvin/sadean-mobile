import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text("Hubungi Kami"),
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
                "Hubungi Kami",
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Kami siap membantu Anda. Silakan hubungi kami melalui informasi di bawah ini atau kirim pesan.",
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),

              // Contact Information
              _buildContactInfo(isTablet),

              SizedBox(height: 32),

              // Contact Form
              Text(
                "Kirim Pesan",
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: "Pesan",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.message),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pesan tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Kirim Pesan",
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(bool isTablet) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildContactItem(
              Icons.phone,
              "Telepon",
              "+62 21 1234 5678",
                  () => _launchPhone("+6221234567"),
              isTablet,
            ),
            Divider(),
            _buildContactItem(
              Icons.email,
              "Email",
              "support@example.com",
                  () => _launchEmail("support@example.com"),
              isTablet,
            ),
            Divider(),
            _buildContactItem(
              Icons.location_on,
              "Alamat",
              "Jl. Contoh No. 123, Jakarta Pusat, DKI Jakarta 10110",
                  () => _launchMaps(),
              isTablet,
            ),
            Divider(),
            _buildContactItem(
              Icons.access_time,
              "Jam Operasional",
              "Senin - Jumat: 09:00 - 18:00\nSabtu: 09:00 - 15:00",
              null,
              isTablet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
      IconData icon,
      String title,
      String content,
      VoidCallback? onTap,
      bool isTablet,
      ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue,
        size: isTablet ? 28 : 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isTablet ? 16 : 14,
        ),
      ),
      subtitle: Text(
        content,
        style: TextStyle(fontSize: isTablet ? 14 : 12),
      ),
      trailing: onTap != null
          ? Icon(Icons.launch, color: Colors.blue)
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _sendMessage() {
    if (_formKey.currentState!.validate()) {
      // Simulate sending message
      Get.dialog(
        AlertDialog(
          title: Text("Pesan Terkirim"),
          content: Text("Terima kasih! Pesan Anda telah terkirim. Tim kami akan segera menghubungi Anda."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Get.back();
                _clearForm();
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
  }

  void _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      Get.snackbar("Error", "Tidak dapat membuka aplikasi telepon");
    }
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Dukungan Aplikasi',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      Get.snackbar("Error", "Tidak dapat membuka aplikasi email");
    }
  }

  void _launchMaps() async {
    const String address = "Jl. Contoh No. 123, Jakarta Pusat, DKI Jakarta";
    final Uri mapsUri = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}"
    );
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "Tidak dapat membuka Google Maps");
    }
  }
}