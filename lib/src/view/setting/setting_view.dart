import 'dart:io';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart' hide Alignment;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/config/theme.dart';
import 'package:sadean/src/controllers/setting_controller.dart';
import 'package:sadean/src/view/customer/customer_view.dart';

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
              radius: isTablet ? 40 : 30,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: isTablet ? 50 : 40,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 12),
            Text(
              controller.userName.value,
              style: TextStyle(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            Text(
              controller.userEmail.value,
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                color: Colors.white70,
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
          _buildMenuSection(context, "Pengaturan Printer", [
            _buildPrinterStatusCard(context),
            // _buildMenuTile(
            //   context,
            //   Icons.bluetooth_searching,
            //   "Scan Printer",
            //   "Cari printer Bluetooth tersedia",
            //   () => controller.scanPrinters(),
            //   trailing: Obx(
            //     () =>
            //         controller.printService.isScanning.value
            //             ? SizedBox(
            //               width: 20,
            //               height: 20,
            //               child: CircularProgressIndicator(strokeWidth: 2),
            //             )
            //             : Icon(Icons.search, color: Colors.blue),
            //   ),
            // ),
            _buildMenuTile(
              context,
              Icons.print,
              "Pilih Printer",
              "Pilih printer dari daftar",
              () => _showPrinterDialog(context),
            ),
            Obx(() {
              if (controller.printService.selectedDevice.value != null) {
                return Column(
                  children: [
                    _buildMenuTile(
                      context,
                      controller.printService.isConnected.value
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      controller.printService.isConnected.value
                          ? "Disconnect Printer"
                          : "Connect Printer",
                      controller.printService.isConnected.value
                          ? "Putuskan koneksi printer"
                          : "Hubungkan ke printer",
                      () => null,
                          // controller.printService.isConnected.value
                          //     ? controller.disconnectPrinter()
                          //     : controller.connectPrinter(),
                      trailing: Obx(
                        () =>
                            controller.printService.isConnecting.value
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Icon(
                                  controller.printService.isConnected.value
                                      ? Icons.bluetooth_connected
                                      : Icons.bluetooth_disabled,
                                  color:
                                      controller.printService.isConnected.value
                                          ? Colors.green
                                          : Colors.red,
                                ),
                      ),
                    ),
                    if (controller.printService.isConnected.value)
                      _buildMenuTile(
                        context,
                        Icons.print_outlined,
                        "Test Print",
                        "Cetak struk percobaan",
                        () => controller.testPrint(),
                        trailing: Obx(
                          () =>
                              controller.printService.isPrinting.value
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(
                                    Icons.print_outlined,
                                    color: Colors.green,
                                  ),
                        ),
                      ),
                    Obx(() {
                      if(controller.printService.selectedDevice.value != null) {
                        return _buildMenuTile(
                            context,
                            Icons.link_off,
                            "Lupakan Printer",
                            "Hapus printer yang tersimpan",
                                () => controller.printService.forgetPrinter(),
                            iconColor: Colors.red
                        );
                      }
                      return SizedBox.shrink();
                    }),
                  ],
                );
              }
              return SizedBox.shrink();
            }),
            // _buildLogoSettingsCard(context),
            _buildMenuTile(
              context,
              Icons.receipt_long,
              "Pengaturan Struk",
              "Atur nama toko, alamat, dan info struk",
                  () => controller.showReceiptSettingsDialog(),
            ),
          ]),
          _buildMenuSection(
            context,
            "Master Data",
            [
              _buildMenuTile(
                context,
                Icons.supervised_user_circle,
                "Data Pelanggan",
                "Pengaturan data pelanggan",
                    () => Get.to(CustomerView()), // <-- Panggil metode baru di sini
              ),
            ],
          ),
          _buildMenuSection(
            context,
            "Manajemen Data",
            [
              _buildMenuTile(
                context,
                Icons.cloud_upload_outlined,
                "Backup Data",
                "Backup data ke cloud",
                    () => controller.uploadDatabaseData(),
              ),
              _buildMenuTile(
                context,
                Icons.cloud_download_outlined,
                "Import Data",
                "Ambil data dari server & ganti data lokal",
                    () => controller.importDatabaseFromApi(), // <-- Panggil metode baru di sini
              ),
            ],
          ),
          _buildMenuSection(context, "Bantuan & Info", [
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
          ]),
          Center(child: Text('V.1.1.4',style: TextStyle(color: Colors.blueGrey),)),
          _buildMenuSection(context, "Akun", [
            _buildMenuTile(
              context,
              Icons.logout,
              "Logout",
              "Keluar dari aplikasi",
              controller.logout,
              textColor: Colors.red,
              iconColor: Colors.red,
            ),
          ]),
          SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildPrinterStatusCard(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Obx(
      () => Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 8 : 16,
          vertical: 8,
        ),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getPrinterStatusColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getPrinterStatusColor()),
        ),
        child: InkWell(
          onTap: () {
            if (controller.printService.selectedDevice.value != null &&
                !controller.printService.isConnected.value) {
              // If printer is selected but not connected, try to connect
              // controller.connectPrinter();
            } else if (controller.printService.selectedDevice.value == null) {
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
                  if (controller.printService.isConnecting.value)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getPrinterStatusColor(),
                        ),
                      ),
                    ),
                ],
              ),
              if (controller.printService.selectedDevice.value != null) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.print, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.printService.selectedDevice.value!.name ??
                            "Unknown",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.bluetooth, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MAC: ${controller.printService.selectedDevice.value!.address ?? "Unknown"}',
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
        ),
      ),
    );
  }

  Color _getPrinterStatusColor() {
    if (controller.printService.isConnecting.value) return Colors.orange;
    if (controller.printService.isConnected.value &&
        controller.printService.selectedDevice.value != null)
      return Colors.green;
    if (controller.printService.selectedDevice.value != null &&
        !controller.printService.isConnected.value)
      return Colors.red;
    return Colors.grey;
  }

  IconData _getPrinterStatusIcon() {
    if (controller.printService.isConnecting.value)
      return Icons.bluetooth_searching;
    if (controller.printService.isConnected.value &&
        controller.printService.selectedDevice.value != null)
      return Icons.bluetooth_connected;
    if (controller.printService.selectedDevice.value != null &&
        !controller.printService.isConnected.value)
      return Icons.bluetooth_disabled;
    return Icons.bluetooth;
  }

  String _getPrinterStatusTitle() {
    if (controller.printService.isConnecting.value) return "Menghubungkan...";
    if (controller.printService.isConnected.value &&
        controller.printService.selectedDevice.value != null)
      return "Printer Terhubung";
    if (controller.printService.selectedDevice.value != null &&
        !controller.printService.isConnected.value)
      return "Printer Terputus";
    return "Belum Ada Printer";
  }

  String _getPrinterStatusSubtitle() {
    if (controller.printService.isConnecting.value)
      return "Sedang menghubungkan ke printer";
    if (controller.printService.isConnected.value &&
        controller.printService.selectedDevice.value != null)
      return "Siap untuk mencetak";
    if (controller.printService.selectedDevice.value != null &&
        !controller.printService.isConnected.value)
      return "Tap untuk menyambungkan";
    return "Silakan pilih printer Bluetooth";
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
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
        style: TextStyle(fontSize: isTablet ? 14 : 12, color: Colors.grey[600]),
      ),
      trailing:
          trailing ??
          Icon(
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
    // Start scanning when dialog opens
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
          height: 400,
          child: Column(
            children: [
              // Scanning indicator
              Obx(() {
                if (controller.printService.isScanning.value) {
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Mencari printer...",
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.shrink();
              }),

              SizedBox(height: 8),

              // Device list
              Expanded(
                child: Obx(() {
                  if (controller.printService.devices.isEmpty &&
                      !controller.printService.isScanning.value) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text("Tidak ditemukan printer"),
                        SizedBox(height: 8),
                        Text(
                          "Pastikan printer Bluetooth aktif dan dalam mode pairing",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
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
                    itemCount: controller.printService.devices.length,
                    itemBuilder: (context, index) {
                      final device = controller.printService.devices[index];
                      final isSelected =
                          controller
                              .printService
                              .selectedDevice
                              .value
                              ?.address ==
                          device.address;

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
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                  : null,
                          onTap: () {
                            controller.selectPrinter(index);
                            Get.back();
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Tutup")),
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

  Widget _buildPrinterStatusTile() {
    return Obx(() {
      final service = controller.printService;
      IconData icon;
      String title;
      String subtitle;
      Color color;

      if (service.isConnecting.value) {
        icon = Icons.bluetooth_searching;
        title = "Menyambungkan...";
        subtitle = service.selectedDevice.value?.name ?? "Mencari...";
        color = Colors.orange;
      } else if (service.isConnected.value) {
        icon = Icons.bluetooth_connected;
        title = "Terhubung";
        subtitle = service.selectedDevice.value?.name ?? "Printer";
        color = Colors.green;
      } else if (service.selectedDevice.value != null) {
        icon = Icons.bluetooth_disabled;
        title = "Tersimpan, Tidak Terhubung";
        subtitle = service.selectedDevice.value?.name ?? "Printer";
        color = Colors.grey;
      } else {
        icon = Icons.phonelink_erase;
        title = "Tidak Ada Printer";
        subtitle = "Pilih printer untuk memulai";
        color = Colors.red;
      }

      return ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(subtitle),
        trailing: service.isConnected.value
            ? OutlinedButton(onPressed: () => service.disconnect(), child: Text("Putus"))
            : service.selectedDevice.value != null
            ? ElevatedButton(onPressed: () => service.connect(service.selectedDevice.value!), child: Text("Sambung"))
            : null,
      );
    });
  }

  void _showPrinterSelectionDialog(BuildContext context) {
    controller.printService.startScan(); // Mulai scan saat dialog dibuka
    Get.dialog(
      AlertDialog(
        title: Text("Pilih Printer"),
        content: Obx(() {
          if (controller.printService.isScanning.value) {
            return Column(
                mainAxisSize: MainAxisSize.min,
                children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Mencari...")]);
          }
          if (controller.printService.devices.isEmpty) {
            return Text("Tidak ada perangkat ditemukan.");
          }
          return Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: controller.printService.devices.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = controller.printService.devices[index];
                return ListTile(
                  title: Text(device.name ?? "Unknown Device"),
                  subtitle: Text(device.address ?? ""),
                  onTap: () {
                    // Langsung sambungkan saat dipilih
                    controller.printService.connect(device);
                    Get.back();
                  },
                );
              },
            ),
          );
        }),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Tutup")),
          TextButton(onPressed: () => controller.printService.startScan(), child: Text("Scan Ulang")),
        ],
      ),
    );
  }

  Widget _buildLogoSettingsCard(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 16,
        vertical: 8,
      ),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: Colors.blue.shade700, size: isTablet ? 24 : 20),
              SizedBox(width: 12),
              Text(
                'Logo Toko',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Logo preview section
          Obx(() => Row(
            children: [
              // Logo preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: controller.storeLogo.value.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(controller.storeLogo.value),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.broken_image, color: Colors.grey, size: 30),
                  ),
                )
                    : Icon(Icons.image, color: Colors.grey, size: 30),
              ),

              SizedBox(width: 16),

              // Logo info and controls
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.storeLogo.value.isNotEmpty
                          ? 'Logo tersimpan'
                          : 'Belum ada logo',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: controller.storeLogo.value.isNotEmpty
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      controller.storeLogo.value.isNotEmpty
                          ? 'Akan dicetak di struk thermal'
                          : 'Pilih logo untuk struk',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Action buttons
                    Row(
                      children: [
                        // Select/Change logo button
                        ElevatedButton.icon(
                          onPressed: () => controller.selectStoreLogo(),
                          icon: Icon(
                            controller.storeLogo.value.isNotEmpty
                                ? Icons.edit
                                : Icons.add_photo_alternate,
                            size: 16,
                          ),
                          label: Text(
                            controller.storeLogo.value.isNotEmpty
                                ? 'Ubah'
                                : 'Pilih',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size(0, 32),
                          ),
                        ),

                        // Remove logo button (only show if logo exists)
                        if (controller.storeLogo.value.isNotEmpty) ...[
                          SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _confirmRemoveLogo(),
                            icon: Icon(Icons.delete, size: 16, color: Colors.red),
                            label: Text(
                              'Hapus',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red),
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size(0, 32),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )),

          SizedBox(height: 12),

          // Print logo toggle
          Obx(() => Row(
            children: [
              Switch(
                value: controller.printLogoEnabled.value && controller.storeLogo.value.isNotEmpty,
                onChanged: controller.storeLogo.value.isNotEmpty
                    ? (value) {
                  controller.printLogoEnabled.value = value;
                  controller.saveSettings();
                }
                    : null,
                activeColor: Colors.blue,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cetak Logo di Struk',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: controller.storeLogo.value.isNotEmpty
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      controller.storeLogo.value.isNotEmpty
                          ? (controller.printLogoEnabled.value
                          ? 'Logo akan dicetak di struk thermal'
                          : 'Logo tidak akan dicetak')
                          : 'Pilih logo terlebih dahulu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

// Method untuk konfirmasi hapus logo
  void _confirmRemoveLogo() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Hapus Logo'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus logo toko?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeStoreLogo();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
