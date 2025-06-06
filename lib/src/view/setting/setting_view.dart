import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/config/theme.dart';
import 'package:sadean/src/controllers/setting_controller.dart';

class SettingView extends StatelessWidget {
  final SettingsController controller = Get.put(SettingsController());

  SettingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context),
              SizedBox(height: 20),
              _buildMenuList(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor, secondaryColor],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Column(
          children: [
            CircleAvatar(
              radius: isTablet ? 60 : 50,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: isTablet ? 60 : 50,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 16),
            Text(
              controller.userName.value,
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              controller.userEmail.value,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 4),
            Text(
              controller.userPhone.value,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showEditProfileDialog(context),
              icon: Icon(Icons.edit, size: isTablet ? 20 : 16),
              label: Text(
                "Edit Profil",
                style: TextStyle(fontSize: isTablet ? 16 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: isTablet ? 12 : 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;
    double maxWidth = isTablet ? 800 : double.infinity;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 20 : 0),
      child: Column(
        children: [
          _buildMenuSection(
            context,
            "Pengaturan",
            [
              _buildMenuTile(
                context,
                Icons.settings,
                "Pengaturan Umum",
                "Atur preferensi aplikasi",
                    () => _showSettingsDialog(context),
              ),
              _buildMenuTile(
                context,
                Icons.currency_exchange,
                "Satuan",
                "Pilih mata uang: ${controller.selectedCurrency.value}",
                    () => _showCurrencyDialog(context),
              ),
              _buildMenuTile(
                context,
                Icons.payment,
                "Jenis Pembayaran",
                "Metode: ${controller.selectedPaymentMethod.value}",
                    () => _showPaymentMethodDialog(context),
              ),
              _buildMenuTile(
                context,
                Icons.print,
                "Printer",
                "Terpilih: ${controller.selectedPrinter.value}",
                    () => _showPrinterDialog(context),
              ),
            ],
          ),
          _buildMenuSection(
            context,
            "Bantuan & Info",
            [
              _buildMenuTile(
                context,
                Icons.help_outline,
                "FAQ",
                "Pertanyaan yang sering ditanyakan",
                controller.showFAQ,
              ),
              _buildMenuTile(
                context,
                Icons.privacy_tip_outlined,
                "Kebijakan Privasi",
                "Baca kebijakan privasi kami",
                controller.showPrivacyPolicy,
              ),
              _buildMenuTile(
                context,
                Icons.contact_support_outlined,
                "Hubungi Kami",
                "Butuh bantuan? Hubungi support",
                controller.contactUs,
              ),
            ],
          ),
          _buildMenuSection(
            context,
            "Akun",
            [
              _buildMenuTile(
                context,
                Icons.logout,
                "Logout",
                "Keluar dari aplikasi",
                controller.logout,
                textColor: Colors.red,
                iconColor: Colors.red,
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String title, List<Widget> items) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 8 : 16,
            vertical: 8,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 16),
          elevation: 2,
          child: Column(children: items),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMenuTile(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap, {
        Color? textColor,
        Color? iconColor,
      }) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.blue,
        size: isTablet ? 28 : 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTablet ? 18 : 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: isTablet ? 14 : 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: isTablet ? 24 : 20,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 8 : 4,
      ),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: controller.userName.value);
    final emailController = TextEditingController(text: controller.userEmail.value);
    final phoneController = TextEditingController(text: controller.userPhone.value);

    Get.dialog(
      AlertDialog(
        title: Text("Edit Profil"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nama",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: "No. Telepon",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateProfile(
                name: nameController.text,
                email: emailController.text,
                phone: phoneController.text,
              );
              Get.back();
            },
            child: Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text("Pengaturan Umum"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => SwitchListTile(
              title: Text("Mode Gelap"),
              subtitle: Text("Aktifkan tema gelap"),
              value: controller.isDarkMode.value,
              onChanged: (value) => controller.toggleDarkMode(),
            )),
            Obx(() => SwitchListTile(
              title: Text("Notifikasi"),
              subtitle: Text("Terima notifikasi push"),
              value: controller.isNotificationEnabled.value,
              onChanged: (value) => controller.toggleNotification(),
            )),
            ListTile(
              title: Text("Bahasa"),
              subtitle: Obx(() => Text(controller.selectedLanguage.value)),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => _showLanguageDialog(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text("Pilih Bahasa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.languages.map((language) {
            return Obx(() => RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: controller.selectedLanguage.value,
              onChanged: (value) {
                controller.updateLanguage(value!);
                Get.back();
              },
            ));
          }).toList(),
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text("Pilih Mata Uang"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.currencies.map((currency) {
            return Obx(() => RadioListTile<String>(
              title: Text(currency),
              value: currency,
              groupValue: controller.selectedCurrency.value,
              onChanged: (value) {
                controller.updateCurrency(value!);
                Get.back();
              },
            ));
          }).toList(),
        ),
      ),
    );
  }

  void _showPaymentMethodDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text("Pilih Metode Pembayaran"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.paymentMethods.map((method) {
            return Obx(() => RadioListTile<String>(
              title: Text(method),
              value: method,
              groupValue: controller.selectedPaymentMethod.value,
              onChanged: (value) {
                controller.updatePaymentMethod(value!);
                Get.back();
              },
            ));
          }).toList(),
        ),
      ),
    );
  }

  void _showPrinterDialog(BuildContext context) {
    // Scan ulang printer saat dialog dibuka supaya daftar up to date
    controller.scanPrinters();

    Get.dialog(
      AlertDialog(
        title: Text("Pilih Printer"),
        content: Obx(() {
          if (controller.printers.isEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Sedang mencari printer..."),
                SizedBox(height: 16),
                CircularProgressIndicator(),
              ],
            );
          }

          return Obx(()=>SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: controller.printers.length,
              itemBuilder: (context, index) {
                final device = controller.printers[index];
                return RadioListTile<String>(
                  title: Text(device.name ?? 'Unknown'),
                  value: device.name ?? 'Unknown',
                  groupValue: controller.selectedPrinter.value,
                  onChanged: (value) {
                    controller.updatePrinter(value!);
                    Get.back();
                  },
                );
              },
            ),
          ));
        }),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Tutup"),
          ),
        ],
      ),
    );
  }
}