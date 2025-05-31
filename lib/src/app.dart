import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sadean/src/routers/constant.dart';
import 'package:sadean/src/routers/routes.dart';

import 'config/theme.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/history_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/setting_controller.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: false,
      splitScreenMode: true,
      enableScaleText: () => true,
      builder: (_, child) {
        return GetMaterialApp(
          builder: (context, widget) {
            return MediaQuery(
              ///Setting font does not change with system font size
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: widget!,
            );
          },
          title: 'POS Sadean',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xff5eaaa8),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff5eaaa8),
              secondary: const Color(0xfff48452),
            ),
            fontFamily: 'Poppins',
            useMaterial3: true,
          ),
          initialRoute: rootRoute,
          getPages: routes,
          initialBinding: BindingsBuilder(() {
            Get.put(DashboardController());
            Get.put(ProductController());
            Get.put(HistoryController());
            Get.put(SettingsController());
          }),
        );
      },
    );
  }
}
