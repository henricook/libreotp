import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libreotp/utils/json.dart';
import 'package:libreotp/widgets/dashboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:otp/otp.dart';
import 'package:faker/faker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> jsonData = await readJsonFile();
  runApp(LibreOTPApp(jsonData));
}

class LibreOTPApp extends StatelessWidget {
  final Map<String, dynamic> jsonData;

  LibreOTPApp(this.jsonData);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LibreOTP v0.1',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Dashboard(jsonData: jsonData),
    );
  }
}
