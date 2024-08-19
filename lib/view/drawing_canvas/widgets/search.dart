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
    final url = useState<String?>(null);

    useEffect(
      () {
        HttpServer? localServer;
        startServer().then((ls) {
          localServer = ls;
        }).then((a) {
          return getQuery(context).then((query) {
            if (localServer == null || query == null || query.isEmpty) {
              throw Exception('Unable to get url');
            }
            url.value =
                'http://${localServer!.address.address}:${localServer!.port}#gsc.q=${Uri.encodeQueryComponent(query)}';
          });
        }).catchError((e) {
          searchState.value = null;
        });
        return () {
          localServer!.close();
        };
      },
      [],
    );

    final position = useState<Offset>(Offset(
        searchState.value?.point2.dx ?? 0, searchState.value?.point2.dy ?? 0));

    return Positioned(
        left: position.value.dx,
        top: position.value.dy,
        child: url.value == null
            ? Container()
            : Column(
                children: [
                  GestureDetector(
                    onPanUpdate: (details) {
                      position.value = position.value + details.delta;
                    },
                    child: Container(
                      width: 300,
                      height: 40,
                      padding: const EdgeInsets.only(left: 5),
                      decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 207, 207, 207)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Search'),
                          IconButton(
                              onPressed: () {
                                searchState.value = null;
                              },
                              icon: const Icon(Icons.close))
                        ],
                      ),
                    ),
                  ),
                  PopUpContent(url: url.value ?? 'https://google.com'),
                ],
              )

        /*
            Draggable(
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
                )*/
        );
  }

  Future<HttpServer> startServer() async {
    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

    Future.delayed(Duration(milliseconds: 1), () async {
      await for (var request in server) {
        request.response
          ..headers.contentType = ContentType('text', 'html', charset: 'utf-8')
          ..write(
              '<html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><script async src="https://cse.google.com/cse.js?cx=5233e46533c0e467e"></script></head><body><div class="gcse-searchresults-only"></div></body></html>')
          ..close();
      }
    });
    print('Server running on IP : ${server.address} On Port : ${server.port}');
    return server;
  }

  Future<String?> getQuery(BuildContext context) async {
    // try with digital ink
    String? searchText = await getFromDigitalInk(context);
    if (searchText!.isEmpty) {
      searchText = await getFromImage();
    }

    return searchText;
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
        if (sketch.type != SketchType.scribble) {
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

class PopUpContent extends StatefulWidget {
  final String url;

  const PopUpContent({required this.url, super.key});
 
  @override
  State<PopUpContent> createState() => _PopUpContent();
}

class _PopUpContent extends State<PopUpContent> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
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
      ..loadRequest(Uri.parse(widget.url));
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
      child: WebViewWidget(controller: controller),
    );
  }
}
