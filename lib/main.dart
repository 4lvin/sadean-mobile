import 'package:flutter/material.dart';
import 'package:sadean/src/app.dart';
import 'package:sadean/src/service/app_init_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    // Initialize app services and database
    await AppInitializationService.initialize();
    print('App initialization completed successfully');
  } catch (e) {
    print('Error during app initialization: $e');
    // You might want to show an error screen or retry mechanism here
  }
  runApp(const MyApp());
}

