import 'dart:io';

import 'package:dio/dio.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Windows Installer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(1, 1, 87, 155),
        ),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _flutterLocation = TextEditingController();
  late String _localPath;
  late bool _permissionReady;
  late TargetPlatform? platform;

  @override
  void initState() {
    _flutterLocation = TextEditingController(text: "c:\\flutter");
    if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else if (Platform.isIOS) {
      platform = TargetPlatform.iOS;
    } else if (Platform.isWindows) {
      platform = TargetPlatform.windows;
    }
    super.initState();
  }

  Future<bool> _checkPermission() async {
    if (platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

  Future<void> _prepareSaveDir() async {
    _localPath = (await _findLocalPath())!;

    print(_localPath);
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  Future<String?> _findLocalPath() async {
    if (platform == TargetPlatform.android) {
      return "/sdcard/download/";
    } else {
      var directory = await Directory(_flutterLocation.value.text);
      print("Directory: ${directory}");
      return directory.path + Platform.pathSeparator;
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final file = DirectoryPicker()
      ..title = 'Select a target location for the installation.';
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 22, 22),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: FlutterLogo(size: 122)),
            const Text(
              'FLUTTER WINDOWS INSTALLER',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            GestureDetector(
              onTap: () {
                final result = file.getDirectory();
                if (result != null) {
                  setState(() {
                    _flutterLocation = TextEditingController(text: result.path);
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  // color: Colors.white,
                  // border: Border.all(color: Colors.blueAccent, width: 2),
                  borderRadius: BorderRadius.circular(5),
                ),
                margin: const EdgeInsets.symmetric(vertical: 5),
                width: size.width * 0.45,
                child: TextFormField(
                  enabled: false,
                  controller: _flutterLocation,
                  style: TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    label: Text(
                      "Target Location",
                      style: TextStyle(color: Colors.white),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 2, color: Colors.blueAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 2, color: Colors.blueAccent),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 2, color: Colors.blueAccent),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(width: 2, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                vertical: 15,
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 15,
                  ),
                ),
                onPressed: () async {
                  _permissionReady = await _checkPermission();
                  if (_permissionReady) {
                    await _prepareSaveDir();
                    print("Downloading");
                    try {
                      // await Dio().download("https://******/image.jpg",
                      //     _localPath + "/" + "filename.jpg");
                      print("Download Completed.");
                    } catch (e) {
                      print("Download Failed.\n\n" + e.toString());
                    }
                  }
                },
                icon: Icon(
                  Icons.install_desktop,
                ),
                label: Text(
                  "INSTALL",
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
