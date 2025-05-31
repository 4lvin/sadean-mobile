import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/assets.dart';
import '../config/theme.dart';
import '../routers/constant.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Timer(const Duration(milliseconds: 700), () {
      Get.offAllNamed(loginRoute);
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
