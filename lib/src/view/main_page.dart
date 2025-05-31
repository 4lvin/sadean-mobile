import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/routers/constant.dart';
import 'package:sadean/src/view/history/history_view.dart';
import 'package:sadean/src/view/product/product_view.dart';
import 'package:sadean/src/view/setting/setting_view.dart';

import '../config/theme.dart';
import 'dashboard/dashboard_view.dart';

class MainPage extends StatelessWidget {
  final RxInt currentIndex = 0.obs;

  final pages = [
    DashboardView(),
    ProductsView(),
    HistoryView(),
    SettingView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          // <= Change BeveledRectangleBorder to RoundedRectangularBorder
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
            bottomLeft: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
          ),
        ),
        onPressed: () async {
          Get.toNamed(transactionIndexRoute);
        },
        child: Container(
          margin: EdgeInsets.all(5),
          padding: EdgeInsets.all(5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: primaryColor),
          child: Center(
            child:  Icon(Icons.calculate_sharp,color: secondaryColor,),),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: pages[currentIndex.value],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex.value,
        onTap: (index) => currentIndex.value = index,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'Lainnya',
          ),
        ],
      ),
    ));
  }
}