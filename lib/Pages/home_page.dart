import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPlatformChannel {
  static Future<String> add(String value) async {
    print("Executing c++ Code");
    const MethodChannel channel = MethodChannel('calc_channel');
    try {
      var result = await channel.invokeMethod('add', {
        'a': value,
      });
      return (result);
    } catch (e) {
      return (e.toString());
    }
  }
}

class MyHomePage extends StatefulWidget {
  final String FLUTTER_GIT_URL =
      "https://github.com//flutter/flutter/archive/refs/heads/master.zip";
  final String FLUTTER_DEFAULT_INSTALLATION_LOCATION = "c:\\flutter";
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _flutterLocation = TextEditingController();
  late String _localPath;
  // late TargetPlatform? platform;
  bool _isLoading = false;
  bool _downloadLoader = false;
  double _downloadCount = 0.00;
  double _downloadTotal = 0.00;
  late SharedPreferences prefs;
  bool _pathVariable = true;
  bool _installed = false;

  Future<void> getData() async {
    setState(() {
      _isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();
    final String? _installPath = prefs.getString('installPath');
    _flutterLocation = TextEditingController(
      text: _installPath ?? widget.FLUTTER_DEFAULT_INSTALLATION_LOCATION,
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    getData();
    super.initState();
  }

  Future<void> _prepareSaveDir() async {
    _localPath = (await _findLocalPath())!;

    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  Future<String?> _findLocalPath() async {
    var directory = await Directory(_flutterLocation.value.text);
    return directory.path + Platform.pathSeparator;
  }

  Future<void> download() async {
    try {
      print("Downloading");
      setState(() {
        _downloadLoader = true;
        _downloadCount = 0.00;
        _downloadTotal = 0.00;
        _installed = false;
      });
      await _prepareSaveDir();

      await Dio().download(
        widget.FLUTTER_GIT_URL,
        _localPath + "/" + "flutter.zip",
        lengthHeader: Headers.contentLengthHeader,
        onReceiveProgress: (count, total) {
          setState(() {
            _downloadCount = double.parse(count.toString());
            _downloadTotal = double.parse(total.toString());
          });
        },
      );
      // Use an InputFileStream to access the zip file without storing it in memory.
      final inputStream =
          InputFileStream("${_flutterLocation.value.text}/flutter.zip");

      final archive = ZipDecoder().decodeBuffer(inputStream);
      extractArchiveToDisk(
        archive,
        _flutterLocation.value.text,
        asyncWrite: true,
      );
      if (_pathVariable) {
        await AppPlatformChannel.add(
            _flutterLocation.value.text.replaceAll("\\", "\\\\"));
      }

      setState(() {
        _installed = true;
        _downloadLoader = false;
      });
      print("Download Completed.");
    } catch (e) {
      print("Download Failed.\n\n" + e.toString());
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() {
        _installed = false;
        _isLoading = false;
      });
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
            : SingleChildScrollView(
                child: Column(
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
                      textAlign: TextAlign.center,
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
                        margin: const EdgeInsets.symmetric(vertical: 15),
                        width: size.width * 0.45,
                        child: TextFormField(
                          enabled: false,
                          controller: _flutterLocation,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            label: Text(
                              "Installation location(choose a location that does not require administrator permissions)",
                              style: TextStyle(color: Colors.white),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2, color: Colors.blueAccent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2, color: Colors.blueAccent),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2, color: Colors.blueAccent),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  width: 2, color: Colors.blueAccent),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: size.width * 0.45,
                      child: CheckboxListTile(
                        onChanged: (value) {
                          setState(() {
                            _pathVariable = value ?? false;
                          });
                        },
                        value: _pathVariable,
                        enabled: _installed || _downloadLoader ? false : true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          "Do you want to write flutter in your path environment variable? (recommended)",
                          style: TextStyle(
                            color: _installed || _downloadLoader
                                ? Colors.white70
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    _installed
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                            ),
                            margin: const EdgeInsets.symmetric(
                              vertical: 5,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Lottie.asset(
                                  "assets/animations/check.json",
                                  repeat: false,
                                  width: size.width * 0.08,
                                ),
                                Text(
                                  "Installation successful!",
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (_pathVariable)
                                  const Text(
                                    "Run flutter doctor in any terminal to verify the installation.",
                                    textAlign: TextAlign.center,
                                  ),
                                const Text(
                                  "Remember to install the extensions for android studio or visual studio code for a complete development experience.",
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : Container(
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
                              onPressed:
                                  _downloadLoader ? null : () => download(),
                              icon: const Icon(
                                Icons.install_desktop,
                              ),
                              label: Text(
                                _downloadLoader ? "DOWNLOADING..." : "INSTALL",
                              ),
                            ),
                          ),
                    Container(
                      margin: EdgeInsets.only(
                        bottom: 15,
                        top: _installed ? 15 : 0,
                      ),
                      child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 15,
                            ),
                          ),
                          onPressed: () {
                            exit(0);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text("CLOSE")),
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
                                        child:
                                            CircularProgressIndicator.adaptive(
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
      ),
    );
  }
}
