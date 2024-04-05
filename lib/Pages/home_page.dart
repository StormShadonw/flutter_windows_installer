import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _flutterLocation = TextEditingController();
  late String _localPath;
  late bool _permissionReady;
  late TargetPlatform? platform;
  bool _isLoading = false;
  bool _downloadLoader = false;
  double _downloadCount = 0.00;
  double _downloadTotal = 0.00;
  late SharedPreferences prefs;

  Future<void> getData() async {
    setState(() {
      _isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();
    final String? _installPath = prefs.getString('installPath');
    _flutterLocation =
        TextEditingController(text: _installPath ?? "c:\\flutter");

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    getData();
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
        child: _isLoading
            ? const CircularProgressIndicator.adaptive()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: FlutterLogo(
                      size: size.height * 0.25,
                    ),
                  ),
                  const Text(
                    'FLUTTER WINDOWS INSTALLER',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = file.getDirectory();
                      if (result != null) {
                        await prefs.setString('installPath', result.path);
                        setState(() {
                          _flutterLocation =
                              TextEditingController(text: result.path);
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
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
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
                      onPressed: _downloadLoader
                          ? null
                          : () async {
                              _permissionReady = await _checkPermission();
                              if (_permissionReady) {
                                await _prepareSaveDir();
                                print("Downloading");
                                try {
                                  setState(() {
                                    _downloadLoader = true;
                                    _downloadCount = 0.00;
                                    _downloadTotal = 0.00;
                                  });
                                  await Dio().download(
                                    "https://github.com//flutter/flutter/archive/refs/heads/master.zip",
                                    _localPath + "/" + "flutter.zip",
                                    lengthHeader: Headers.contentLengthHeader,
                                    onReceiveProgress: (count, total) {
                                      setState(() {
                                        _downloadCount =
                                            double.parse(count.toString());
                                        _downloadTotal =
                                            double.parse(total.toString());
                                      });
                                    },
                                  );
                                  // Use an InputFileStream to access the zip file without storing it in memory.
                                  final inputStream = InputFileStream(
                                      "${_flutterLocation.value.text}/flutter.zip");
// Decode the zip from the InputFileStream. The archive will have the contents of the
// zip, without having stored the data in memory.
                                  final archive =
                                      ZipDecoder().decodeBuffer(inputStream);
                                  extractArchiveToDisk(
                                    archive,
                                    _flutterLocation.value.text,
                                    asyncWrite: true,
                                  );
                                  setState(() {
                                    _downloadLoader = false;
                                  });
                                  print("Download Completed.");
                                } catch (e) {
                                  print("Download Failed.\n\n" + e.toString());
                                }
                              }
                            },
                      icon: const Icon(
                        Icons.install_desktop,
                      ),
                      label: Text(
                        _downloadLoader ? "DOWNLOADING..." : "INSTALL",
                      ),
                    ),
                  ),
                  // if (_downloadLoader)
                  Container(
                    // color: Colors.red,
                    width: 65,
                    height: 65,
                    child: !_downloadLoader
                        ? const SizedBox.expand()
                        : _downloadTotal == -1
                            ? const CircularProgressIndicator.adaptive(
                                strokeWidth: 8,
                                backgroundColor: Colors.black87,
                              )
                            : Stack(
                                children: [
                                  Center(
                                    child: Text(
                                      "${_downloadTotal == 0 ? 0 : ((_downloadCount / _downloadTotal) * 100).toStringAsFixed(0)}%",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: SizedBox(
                                      height: 65,
                                      width: 65,
                                      child: CircularProgressIndicator.adaptive(
                                        backgroundColor: Colors.black87,
                                        strokeWidth: 8,
                                        value: _downloadTotal <= 0
                                            ? null
                                            : _downloadCount / _downloadTotal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
      ),
    );
  }
}
