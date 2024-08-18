import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/sketch.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as image;
import 'package:flutter/material.dart' hide Ink;
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';

class SearchState {
  final Offset point1;
  final Offset point2;
  final List<Sketch> allSketches;
  const SearchState(this.point1, this.point2, this.allSketches);
}

class Search extends HookWidget {
  final ValueNotifier<SearchState?> searchState;
  final GlobalKey canvasGlobalKey;
  final googleMLKitDigitalInkModelManager = DigitalInkRecognizerModelManager();

  Search(this.searchState, this.canvasGlobalKey, {super.key});

  @override
  Widget build(BuildContext context) {
    final urlFuture = useState<Future<String>?>(null);
    final url = useState<String?>(null);

    if (urlFuture.value == null) {
      urlFuture.value = getUrl(context);
      urlFuture.value!.then((generatedUrl) {
        url.value = generatedUrl;
      }).catchError((e){
        searchState.value = null;
      });
    }

    final dx = useState<double>(searchState.value?.point2.dx ?? 0);
    final dy = useState<double>(searchState.value?.point2.dy ?? 0);

    return Positioned(
        left: dx.value,
        top: dy.value,
        child: url.value == null
            ? Container()
            : Draggable(
                feedback: PopUpContent(url.value ?? 'https://google.com', () {
                  searchState.value = null;
                }),
                childWhenDragging: Container(),
                onDraggableCanceled: (Velocity velocity, Offset offset) {
                  dx.value = offset.dx;
                  dy.value = offset.dy;
                },
                child: PopUpContent(url.value ?? 'https://google.com', () {
                  searchState.value = null;
                }),
              ));
  }

  Future<String> getUrl(BuildContext context) async {
    // try with digital ink
    String? searchText = await getFromDigitalInk(context);
    if (searchText!.isEmpty) {
      searchText = await getFromImage();
    }

    return 'https://www.google.com/search?safe=true&q=${Uri.encodeComponent(searchText ?? "")}';
  }

  Future<String?> getFromImage() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      RenderRepaintBoundary boundary = canvasGlobalKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;
      ui.Image canvasUiImage = await boundary.toImage();
      ByteData? canvasByteData =
          await canvasUiImage.toByteData(format: ui.ImageByteFormat.png);

      final Directory tempDir = await getTemporaryDirectory();
      final canvasUIImageFile = File('${tempDir.path}/canvasUiImage.png');
      await canvasUIImageFile
          .writeAsBytes(canvasByteData!.buffer.asUint8List());

      Rect rect =
          Rect.fromPoints(searchState.value!.point1, searchState.value!.point2);

      print(rect);

      await (image.Command()
            ..decodePngFile('${tempDir.path}/canvasUiImage.png')
            ..copyCrop(
              x: rect.left.floor(),
              y: rect.top.floor(),
              width: rect.width.floor(),
              height: rect.height.floor(),
            )
            ..encodePngFile('${tempDir.path}/selectedImageFile.png'))
          .executeThread();

      final inputImage =
          InputImage.fromFile(File('${tempDir.path}/selectedImageFile.png'));

      print('INPUT IMAGE ${inputImage.filePath}');

      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      print('RECOGNIZED TEXT ${recognizedText.text}');

      return recognizedText.text;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getFromDigitalInk(BuildContext context) async {
    if (await googleMLKitDigitalInkModelManager.isModelDownloaded('en') ==
        false) {
      await googleMLKitDigitalInkModelManager.downloadModel('en');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: const Text(
                  'Waiting for recognition model to be downloaded, please try again later'),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        throw Exception('Waiting for Digital Ink Model');
      }
    }
    final recognizer = DigitalInkRecognizer(languageCode: 'en');
    try {
      final Ink ink = Ink();

      Rect selectedArea =
          Rect.fromPoints(searchState.value!.point1, searchState.value!.point2);

      for (final sketch in searchState.value!.allSketches) {
        if(sketch.type != SketchType.scribble){
          continue;
        }
        final Stroke stroke = Stroke();
        var selected = true;
        for (final (i, point) in sketch.points.indexed) {
          if (selectedArea.left <= point.dx &&
              point.dx <= selectedArea.right &&
              selectedArea.top <= point.dy &&
              point.dy <= selectedArea.bottom) {
            stroke.points.add(
              StrokePoint(
                x: point.dx,
                y: point.dy,
                t: sketch.pointStrokeTimes[i],
              ),
            );
          } else {
            selected = false;
            break;
          }
        }
        if (selected) {
          ink.strokes.add(stroke);
        }
      }

      final candidates =
          await DigitalInkRecognizer(languageCode: 'en').recognize(ink);
      String recognizedText = candidates.first.text;

      print('DIGITAL INK : recognizedText $recognizedText');
      return recognizedText.trim();
    } catch (e) {
      print(e.toString());
      return null;
    } finally {
      recognizer.close();
    }
  }
}

class PopUpContent extends HookWidget {
  final String url;
  final VoidCallback onClose;
  late final WebViewController controller;

  PopUpContent(this.url, this.onClose, {super.key}) {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onHttpError: (HttpResponseError error) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
          border: Border.all(
              width: 1, color: const Color.fromARGB(255, 207, 207, 207)),
          color: const Color.fromARGB(255, 255, 255, 255)),
      child: Column(children: [
        Container(
          width: 300,
          height: 40,
          padding: const EdgeInsets.only(left: 5),
          decoration:
              const BoxDecoration(color: Color.fromARGB(255, 207, 207, 207)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Google'),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close))
            ],
          ),
        ),
        SizedBox(
          width: 300,
          height: 350,
          child: WebViewWidget(controller: controller),
        )
      ]),
    );
  }
}
