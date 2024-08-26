import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libreotp/widgets/dashboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:otp/otp.dart';
import 'package:faker/faker.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path + '/LibreOTP';
}

Future<File> get _localFile async {
  final path = await _localPath;
  debugPrint('Path = ' + path);
  return File('$path/data.json');
}

Future<Map<String, dynamic>> readJsonFile() async {
  try {
    final file = await _localFile;
    if (await file.exists()) {
      String contents = await file.readAsString();
      return jsonDecode(contents);
    } else {
      // Handle the case where the file does not exist
      return {'services': [], 'groups': []};
    }
  } catch (e) {
    // Handle errors
    return {'services': [], 'groups': []};
  }
}

Future<void> writeJsonFile(Map<String, dynamic> jsonData) async {
  final file = await _localFile;
  await file.writeAsString(jsonEncode(jsonData));
}
