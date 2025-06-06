import 'package:get/get.dart';
import 'package:sadean/src/view/product/add_product.dart';
import 'package:sadean/src/view/product/detail_product.dart';
import 'package:sadean/src/view/setting/contact.dart';
import 'package:sadean/src/view/setting/faq.dart';
import 'package:sadean/src/view/setting/privacy.dart';
import 'package:sadean/src/view/transaction/transaction_detail.dart';
import 'package:sadean/src/view/transaction/transaction_index.dart';
import 'package:sadean/src/view/transaction/transaction_view.dart';
import '../view/history/history_detail.dart';
import '../view/history/receipt_view.dart';
import '../view/login/login.dart';
import '../view/main_page.dart';
import '../view/splash_Screen.dart';
import 'constant.dart';

final List<GetPage<dynamic>> routes = [
  GetPage(name: rootRoute, page: () => const SplashScreen()),
  GetPage(name: loginRoute, page: () => LoginView()),
  GetPage(name: mainRoute, page: () => MainPage()),
  GetPage(name: productsAddRoute, page: () => AddProductView()),
  GetPage(name: transactionRoute, page: () => TransactionView()),
  GetPage(name: transactionIndexRoute, page: () => TransactionIndex()),
  GetPage(
    name: transactionDetailViewRoute,
    page: () => TransactionDetailView(),
  ),
  GetPage(name: faqRoute, page: () => FAQPage()),
  GetPage(name: privasiRoute, page: () => PrivacyPolicyPage()),
  GetPage(name: contactRoute, page: () => ContactUsPage()),
  GetPage(
    name: receiptRoute,
    page:
        () => ReceiptView(
          transaction: Get.arguments['transaction'],
          customerName: Get.arguments['customerName'] ?? 'SADEAN',
          phoneNumber: Get.arguments['phoneNumber'] ?? '08573671088',
        ),
  ),
];
