import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:flutter/material.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
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

  @override
  void initState() {
    _flutterLocation = TextEditingController(text: "c:\\flutter");
    super.initState();
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
          ],
        ),
      ),
    );
  }
}
