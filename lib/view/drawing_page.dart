import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_drawing_board/main.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/drawing_canvas.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/drawing_mode.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/ruler_type.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/sketch.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/widgets/canvas_bottom_bar.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/widgets/menu_popup.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/widgets/ruler.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/widgets/search.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DrawingPage extends HookWidget {
  const DrawingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedColor = useState(Colors.white);
    final strokeSize = useState<double>(2);
    final eraserSize = useState<double>(30);
    final drawingMode = useState(DrawingMode.pencil);
    final filled = useState<bool>(false);
    final polygonSides = useState<int>(3);
    final backgroundImage = useState<Image?>(null);
    final search = useState<SearchState?>(null);
    final popupMenu = useState<PopupMenuState?>(null);
    final rulerType = useState<RulerType?>(null);

    final canvasGlobalKey = GlobalKey();

    ValueNotifier<Sketch?> currentSketch = useState(null);
    ValueNotifier<List<Sketch>> allSketches = useState([]);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      initialValue: 0,
    );
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: kCanvasColor,
            width: double.maxFinite,
            height: double.maxFinite,
            child: DrawingCanvas(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                drawingMode: drawingMode,
                selectedColor: selectedColor,
                strokeSize: strokeSize,
                eraserSize: eraserSize,
                sideBarController: animationController,
                currentSketch: currentSketch,
                allSketches: allSketches,
                canvasGlobalKey: canvasGlobalKey,
                filled: filled,
                polygonSides: polygonSides,
                backgroundImage: backgroundImage,
                search: search),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            // left: -5,
            child: Center(
              child: CanvasBottomBar(
                drawingMode: drawingMode,
                popupMenu: popupMenu,
                allSketches: allSketches,
                currentSketch: currentSketch,
                selectedColor: selectedColor,
                eraserSize: eraserSize,
                strokeSize: strokeSize,
                polygonSides: polygonSides,
                rulerType: rulerType,
              ),
            ),
          ),
          _CustomAppBar(animationController: animationController),
          if (search.value != null) Search(search, canvasGlobalKey),
          if (popupMenu.value != null) PopupMenu(popupMenu),
          if (rulerType.value != null) Ruler(rulerType),
        ],
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  final AnimationController animationController;

  const _CustomAppBar({Key? key, required this.animationController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: kToolbarHeight,
      width: double.maxFinite,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 40,
              height: 40,
            ),
            widgets.Image(
              image: AssetImage('assets/logic.png'),
              height: 20,
            ),
            SizedBox(
              width: 40,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
