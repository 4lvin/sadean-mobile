import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/theme.dart';
import '../../controllers/product_controller.dart';
import '../../models/category_model.dart';
import '../../service/category_service.dart';

class CategoryManagementView extends StatelessWidget {
  final TextEditingController categoryNameController = TextEditingController();
  final CategoryService _service = Get.find<CategoryService>();
  final ProductController _productController = Get.find<ProductController>();

  final RxBool isLoading = false.obs;

  CategoryManagementView({super.key}) {
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
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
                    decoration: const InputDecoration(
                      labelText: 'Nama Kategori',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    onFieldSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 16),
                Obx(() => ElevatedButton(
                  onPressed: isLoading.value ? null : _addCategory,
                  child: isLoading.value
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 56),
                  ),
                )),
              ],
            ),
          ),

          // Category list
          Expanded(
            child: Obx(() {
              if (isLoading.value && _productController.categories.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_productController.categories.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada kategori.\nTambahkan kategori pertama Anda!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                itemCount: _productController.categories.length,
                itemBuilder: (context, index) {
                  final category = _productController.categories[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.category,
                          color: primaryColor,
                        ),
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${category.productCount} produk'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editCategory(category),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(category),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCategories() async {
    isLoading.value = true;
    try {
      final categoryList = await _service.getAllCategories();
      _productController.categories.assignAll(categoryList);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat kategori: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _addCategory() async {
    if (categoryNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Nama kategori tidak boleh kosong');
      return;
    }

    try {
      isLoading.value = true;
      await _service.addCategory(categoryNameController.text.trim());
      categoryNameController.clear();
      await _loadCategories();
      Get.snackbar('Sukses', 'Kategori berhasil ditambahkan');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menambah kategori: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _editCategory(Category category) {
    final controller = TextEditingController(text: category.name);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Kategori'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Get.back();
                try {
                  await _service.updateCategory(category.id, controller.text.trim());
                  await _loadCategories();
                  Get.snackbar('Sukses', 'Kategori berhasil diupdate');
                } catch (e) {
                  Get.snackbar('Error', 'Gagal update kategori: $e');
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Category category) {
    Get.defaultDialog(
      title: 'Konfirmasi Hapus',
      middleText: category.productCount > 0
          ? 'Kategori "${category.name}" memiliki ${category.productCount} produk.\nHapus atau pindahkan produk terlebih dahulu.'
          : 'Hapus kategori "${category.name}"?',
      textConfirm: category.productCount > 0 ? 'OK' : 'Hapus',
      textCancel: category.productCount > 0 ? null : 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: category.productCount > 0 ? Colors.blue : Colors.red,
      onConfirm: () async {
        Get.back();
        if (category.productCount > 0) return;

        try {
          final success = await _service.deleteCategory(category.id);
          if (success) {
            await _loadCategories();
            Get.snackbar('Sukses', 'Kategori berhasil dihapus');
          } else {
            Get.snackbar('Error', 'Tidak dapat menghapus kategori yang memiliki produk');
          }
        } catch (e) {
          Get.snackbar('Error', 'Gagal menghapus kategori: $e');
        }
      },
    );
  }
}
