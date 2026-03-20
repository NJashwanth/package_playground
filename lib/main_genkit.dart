import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_playground/genkit/genkit_app.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const GenkitApp());
}
