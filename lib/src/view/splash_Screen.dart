import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sadean/src/service/auth_service.dart';

import '../config/assets.dart';
import '../config/theme.dart';
import '../routers/constant.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthService authService = Get.put(AuthService());

  @override
  void initState() {
    Timer(const Duration(milliseconds: 700), () async {
      if (await authService.isLoggedIn()) {
        Get.offAllNamed(mainRoute);
      } else {
        Get.offAllNamed(loginRoute);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Image.asset(
            logoAtas,
            scale: 1.5,
          )),
    );
  }
}
