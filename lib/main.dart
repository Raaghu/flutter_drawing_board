import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/view/drawing_page.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

void main() {
  runApp(MyApp());
}

const Color kCanvasColor = Color.fromARGB(255, 0, 63, 50);
const String kGithubRepo = 'https://github.com/JideGuru/flutter_drawing_board';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Your initialization code here
    initializeApp();
  }

  Future<void> initializeApp() async {
    final googleMLKitDigitalInkModelManager =
        DigitalInkRecognizerModelManager();
    if (await googleMLKitDigitalInkModelManager.isModelDownloaded('en') ==
        false) {
      await googleMLKitDigitalInkModelManager.downloadModel('en');
      print('googleMLKitDigitalInkModel Downloaded from main');
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logic\'s Interactive Display',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      debugShowCheckedModeBanner: false,
      home: const DrawingPage(),
    );
  }
}
