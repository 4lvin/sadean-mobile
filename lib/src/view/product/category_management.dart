import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/category_model.dart';

class CategoryManagementView extends StatelessWidget {
  final ProductController controller = Get.find<ProductController>();
  final TextEditingController categoryNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Kategori'),
      ),
      body: Column(
        children: [
          // Add category form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: categoryNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    if (categoryNameController.text.isNotEmpty) {
                      final newCategory = Category(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: categoryNameController.text,
                      );
                      controller.categories.add(newCategory);
                      categoryNameController.clear();
                      Get.snackbar('Sukses', 'Kategori berhasil ditambahkan');
                    }
                  },
                  child: Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(100, 56),
                  ),
                ),
              ],
            ),
          ),

          // Category list
          Expanded(
            child: Obx(() => ListView.builder(
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.category,
                      color: Colors.blue[800],
                    ),
                  ),
                  title: Text(category.name),
                  subtitle: Text('${category.productCount} produk'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      // Check if category has products before deletion
                      final hasProducts = controller.products.any((p) => p.categoryId == category.id);

                      if (hasProducts) {
                        Get.snackbar(
                          'Gagal Menghapus',
                          'Kategori ini masih memiliki produk',
                          backgroundColor: Colors.red[100],
                        );
                        return;
                      }

                      Get.defaultDialog(
                        title: 'Konfirmasi Hapus',
                        middleText: 'Hapus kategori ${category.name}?',
                        textConfirm: 'Hapus',
                        textCancel: 'Batal',
                        confirmTextColor: Colors.white,
                        onConfirm: () {
                          controller.categories.removeWhere((c) => c.id == category.id);
                          Get.back();
                          Get.snackbar('Sukses', 'Kategori berhasil dihapus');
                        },
                      );
                    },
                  ),
                );
              },
            )),
          ),
        ],
      ),
    );
  }
}