import 'package:get/get.dart';
import 'package:sadean/src/view/product/add_product.dart';
import 'package:sadean/src/view/product/detail_product.dart';
import 'package:sadean/src/view/transaction/transaction_detail.dart';
import 'package:sadean/src/view/transaction/transaction_index.dart';
import 'package:sadean/src/view/transaction/transaction_view.dart';
import '../view/login/login.dart';
import '../view/main_page.dart';
import '../view/splash_Screen.dart';
import 'constant.dart';

final List<GetPage<dynamic>> routes = [
  GetPage(
    name: rootRoute,
    page: () => const SplashScreen(),
  ),
  GetPage(
    name: loginRoute,
    page: () => LoginView(),
  ),
  GetPage(
    name: mainRoute,
    page: () => MainPage(),
  ),
  GetPage(
    name: productsAddRoute,
    page: () => AddProductView(),
  ),
  GetPage(
    name: transactionRoute,
    page: () => TransactionView(),
  ),
  GetPage(
    name: transactionIndexRoute,
    page: () => TransactionIndex(),
  ),
  GetPage(
    name: transactionDetailRoute,
    page: () => TransactionDetail(),
  ),
];
