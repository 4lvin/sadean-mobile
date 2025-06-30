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
              radius: isTablet ? 50 : 40,
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
            // SizedBox(height: 4),
            // Text(
            //   controller.userPhone.value,
            //   style: TextStyle(
            //     fontSize: isTablet ? 16 : 14,
            //     color: Colors.white70,
            //   ),
            // ),
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
            "Pengaturan Printer",
            [
              _buildPrinterStatusCard(context),
              // _buildMenuTile(
              //   context,
              //   Icons.bluetooth_searching,
              //   "Cari Printer",
              //   "Scan ulang printer Bluetooth",
              //       () => controller.scanPrinters(),
              //   trailing: Obx(() => controller.isLoading.value
              //       ? SizedBox(
              //     width: 20,
              //     height: 20,
              //     child: CircularProgressIndicator(strokeWidth: 2),
              //   )
              //       : Icon(Icons.search, color: Colors.blue)
              //   ),
              // ),
              _buildMenuTile(
                context,
                Icons.print,
                "Pilih Printer",
                "Terpilih: ${controller.selectedPrinter.value}",
                    () => _showPrinterDialog(context),
              ),
              if (controller.selectedPrinterDevice.value != null)
                _buildMenuTile(
                  context,
                  Icons.print_outlined,
                  "Test Print",
                  "Cetak struk percobaan",
                      () => controller.testPrint(),
                  trailing: Obx(() => controller.isPrinting.value
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(Icons.print_outlined, color: Colors.green)
                  ),
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
          SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildPrinterStatusCard(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Obx(() => Container(
        margin: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getPrinterStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getPrinterStatusColor()),
        ),
        child: InkWell(
          onTap: () {
            if (controller.selectedPrinterDevice.value != null && !controller.isConnected.value) {
              // If printer is selected but not connected, try to connect
              controller.connectSelectedPrinter();
            } else if (controller.selectedPrinterDevice.value == null) {
              // If no printer selected, show selection dialog
              _showPrinterDialog(context);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getPrinterStatusIcon(),
                    color: _getPrinterStatusColor(),
                    size: isTablet ? 28 : 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getPrinterStatusTitle(),
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                            color: _getPrinterStatusColor(),
                          ),
                        ),
                        Text(
                          _getPrinterStatusSubtitle(),
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.isConnecting.value)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_getPrinterStatusColor()),
                      ),
                    ),
                ],
              ),
              if (controller.selectedPrinterDevice.value != null) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.bluetooth, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MAC: ${controller.selectedPrinterDevice.value!.address ?? "Unknown"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )));
    }

  Color _getPrinterStatusColor() {
    if (controller.isConnecting.value) return Colors.orange;
    if (controller.isConnected.value && controller.selectedPrinterDevice.value != null) return Colors.green;
    if (controller.selectedPrinterDevice.value != null && !controller.isConnected.value) return Colors.red;
    return Colors.grey;
  }

  IconData _getPrinterStatusIcon() {
    if (controller.isConnecting.value) return Icons.bluetooth_searching;
    if (controller.isConnected.value && controller.selectedPrinterDevice.value != null) return Icons.bluetooth_connected;
    if (controller.selectedPrinterDevice.value != null && !controller.isConnected.value) return Icons.bluetooth_disabled;
    return Icons.bluetooth;
  }

  String _getPrinterStatusTitle() {
    if (controller.isConnecting.value) return "Menghubungkan...";
    if (controller.isConnected.value && controller.selectedPrinterDevice.value != null) return "Printer Terhubung";
    if (controller.selectedPrinterDevice.value != null && !controller.isConnected.value) return "Printer Terputus";
    return "Belum Ada Printer";
  }

  String _getPrinterStatusSubtitle() {
    if (controller.isConnecting.value) return "Sedang menghubungkan ke printer";
    if (controller.isConnected.value && controller.selectedPrinterDevice.value != null) return "Siap untuk mencetak";
    if (controller.selectedPrinterDevice.value != null && !controller.isConnected.value) return "Tap untuk menyambungkan";
    return "Silakan pilih printer Bluetooth";
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
        Widget? trailing,
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
      trailing: trailing ?? Icon(
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

  void _showPrinterDialog(BuildContext context) {
    // Scan ulang printer saat dialog dibuka supaya daftar up to date
    controller.scanPrinters();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.bluetooth, color: Colors.blue),
            SizedBox(width: 12),
            Text("Pilih Printer Bluetooth"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() {
            if (controller.isLoading.value) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Mencari printer..."),
                  SizedBox(height: 8),
                  Text(
                    "Pastikan printer Bluetooth aktif",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              );
            }

            if (controller.printers.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text("Tidak ditemukan printer"),
                  SizedBox(height: 8),
                  Text(
                    "Pastikan printer Bluetooth aktif dan dalam jangkauan",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => controller.scanPrinters(),
                    icon: Icon(Icons.refresh, size: 20),
                    label: Text("Scan Ulang"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: controller.printers.length,
              itemBuilder: (context, index) {
                final device = controller.printers[index];
                final isSelected = controller.selectedPrinter.value == (device.name ?? 'Unknown');

                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  color: isSelected ? Colors.blue.shade50 : null,
                  child: ListTile(
                    leading: Icon(
                      Icons.print,
                      color: isSelected ? Colors.blue : Colors.grey[600],
                    ),
                    title: Text(
                      device.name ?? 'Unknown Device',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    subtitle: Text(
                      'MAC: ${device.address ?? "Unknown"}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      controller.updatePrinter(device.name ?? 'Unknown');
                      Get.back();
                    },
                  ),
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Tutup"),
          ),
          ElevatedButton.icon(
            onPressed: () => controller.scanPrinters(),
            icon: Icon(Icons.refresh, size: 20),
            label: Text("Scan Ulang"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}