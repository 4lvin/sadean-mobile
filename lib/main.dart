import 'package:flutter/material.dart';
import 'package:sadean/src/app.dart';
import 'package:sadean/src/service/app_init_service.dart';

void main() async {
  await AppInitializationService.initialize();
  runApp(const MyApp());
}

