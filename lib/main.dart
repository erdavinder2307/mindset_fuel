import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mindset_fuel/screens/home.dart';
import 'package:mindset_fuel/services/mindset_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:wallpaper/wallpaper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  runApp(const MindsetFuel());
}

Future<void> _requestPermissions() async {
  var result =await [
    Permission.photos,
    Permission.videos,
    Permission.audio,
    Permission.manageExternalStorage,

  ].request();
}

class MindsetFuel extends StatelessWidget {
  const MindsetFuel({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoApp(
            builder: (context, child) {
              return ScaffoldMessenger(
                child: child!,
              );
            },
            home: const HomeScreen(),
          )
        : const MaterialApp(
            home: HomeScreen(),
          );
  }
}

