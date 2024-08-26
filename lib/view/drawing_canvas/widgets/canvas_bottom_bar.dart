import 'package:flutter/material.dart' hide Image;
import 'package:flutter_drawing_board/view/drawing_canvas/models/drawing_mode.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/ruler_type.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/sketch.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/widgets/color_palette.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/widgets/menu_popup.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CanvasBottomBar extends HookWidget {
  final ValueNotifier<DrawingMode> drawingMode;
  final ValueNotifier<PopupMenuState?> popupMenu;
  final ValueNotifier<List<Sketch>> allSketches;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<RulerType?> rulerType;


  const CanvasBottomBar({
    Key? key,
    required this.drawingMode,
    required this.popupMenu,
    required this.allSketches,
    required this.currentSketch,
    required this.selectedColor,
    required this.eraserSize,
    required this.strokeSize,
    required this.polygonSides,
    required this.rulerType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final undoRedoStack = useState(
      _UndoRedoStack(
        sketchesNotifier: allSketches,
        currentSketchNotifier: currentSketch,
      ),
    );
    final scrollController = useScrollController();

    return Container(
      height: MediaQuery.of(context).size.height < 680 ? 40 : 50,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.959),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      padding: const EdgeInsets.all(2),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: 5,
          runSpacing: 5,
          children: [
            _IconBox(
              iconData: FontAwesomeIcons.arrowRotateLeft,
              selected: false,
              onTap: (context) {
                undoRedoStack.value.undo();
              },
              tooltip: 'Undo',
              iconColor: const Color.fromARGB(255, 26, 26, 26),
            ),
            _IconBox(
              iconData: FontAwesomeIcons.arrowRotateRight,
              selected: false,
              onTap: (context) {
                undoRedoStack.value.redo();
              },
              tooltip: 'Redo',
              iconColor: const Color.fromARGB(255, 26, 26, 26),
            ),
            _IconBox(
              iconData: FontAwesomeIcons.trashCan,
              selected: false,
              onTap: (context) {
                undoRedoStack.value.clear();
              },
              tooltip: 'Clear',
              iconColor: const Color.fromARGB(255, 226, 40, 40),
            ),
            _IconBox(
              iconData: FontAwesomeIcons.eraser,
              selected: drawingMode.value == DrawingMode.eraser,
              onTap: (context) {
                drawingMode.value = DrawingMode.eraser;
                togglePopupMenu(
                  context,
                  ErazerSizeSlider(eraserSize: eraserSize),
                  width: 200,
                  height: 50,
                );
              },
              tooltip: 'Eraser',
              iconColor: const Color.fromARGB(255, 226, 40, 40),
            ),
            _IconBox(
              iconData: FontAwesomeIcons.palette,
              selected: false,
              onTap: (context) {
                togglePopupMenu(
                  context,
                  ColorPalette(
                    selectedColor: selectedColor,
                  ),
                  width: 200,
                  height: 135,
                );
              },
              tooltip: 'Colors',
              iconColor: selectedColor.value == Colors.white
                  ? Colors.black
                  : selectedColor.value,
            ),
            _IconBox(
              iconData: Icons.line_weight,
              selected: false,
              onTap: (context) {
                togglePopupMenu(
                  context,
                  StrokeSizeSlider(strokeSize: strokeSize),
                  width: 200,
                  height: 50,
                );
              },
              tooltip: 'Line Weight',
              iconColor: const Color.fromARGB(255, 26, 26, 26),
            ),
            _IconBox(
              iconData: FontAwesomeIcons.pencil,
              selected: drawingMode.value == DrawingMode.pencil,
              onTap: (context) => drawingMode.value = DrawingMode.pencil,
              tooltip: 'Pencil',
            ),
            _IconBox(
              iconData: FontAwesomeIcons.slash,
              selected: drawingMode.value == DrawingMode.line,
              onTap: (context) => drawingMode.value = DrawingMode.line,
              tooltip: 'Line',
            ),
            _IconBox(
              iconData: Icons.arrow_right_alt,
              selected: drawingMode.value == DrawingMode.arrow,
              onTap: (context) => drawingMode.value = DrawingMode.arrow,
              tooltip: 'Arrow',
            ),
            _IconBox(
              iconData: Icons.hexagon_outlined,
              selected: drawingMode.value == DrawingMode.polygon,
              onTap: (context) {
                drawingMode.value = DrawingMode.polygon;
                togglePopupMenu(
                  context,
                  PolygonSidesSlider(polygonSides: polygonSides),
                  width: 200,
                  height: 50,
                );
              },
              tooltip: 'Polygon',
            ),
            _IconBox(
              iconData: FontAwesomeIcons.square,
              selected: drawingMode.value == DrawingMode.square,
              onTap: (context) => drawingMode.value = DrawingMode.square,
              tooltip: 'Square',
            ),
            _IconBox(
              iconData: FontAwesomeIcons.circle,
              selected: drawingMode.value == DrawingMode.circle,
              onTap: (context) => drawingMode.value = DrawingMode.circle,
              tooltip: 'Circle',
            ),
            _IconBox(
              iconData: FontAwesomeIcons.ruler,
              selected: false,
              onTap: (context) {
                togglePopupMenu(context, RulerChooser(rulerType),
                    width: 110, height: 110);
              },
              tooltip: 'Ruler',
            ),
            _IconBox(
              iconData: Icons.search,
              selected: drawingMode.value == DrawingMode.search,
              onTap: (context) => drawingMode.value = DrawingMode.search,
              tooltip: 'Search',
              iconColor: const Color.fromARGB(255, 0, 196, 0),
            ),
          ],
        ),
      ),
    );
  }

  void togglePopupMenu(
    BuildContext context,
    Widget child, {
    double width = 100,
    double height = 100,
  }) {
    if (popupMenu.value == null) {
      RenderBox box = context.findRenderObject() as RenderBox;
      Offset position = box.localToGlobal(Offset.zero);
      popupMenu.value = PopupMenuState(
        position.translate(box.size.width / 2, 0),
        child,
        width: width,
        height: height,
      );
    } else {
      popupMenu.value = null;
    }
  }
}

class _IconBox extends StatelessWidget {
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final void Function(BuildContext context) onTap;
  final String? tooltip;
  final Color? iconColor;

  const _IconBox({
    Key? key,
    this.iconData,
    this.child,
    this.tooltip,
    required this.selected,
    required this.onTap,
    this.iconColor = const Color.fromARGB(255, 0, 81, 230),
  })  : assert(child != null || iconData != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onTap(context),
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            color: selected ? const Color.fromARGB(255, 144, 239, 252) : null,
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Tooltip(
            message: tooltip,
            preferBelow: false,
            child: child ??
                Icon(
                  iconData,
                  color: iconColor,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}

///A data structure for undoing and redoing sketches.
class _UndoRedoStack {
  _UndoRedoStack({
    required this.sketchesNotifier,
    required this.currentSketchNotifier,
  }) {
    _sketchCount = sketchesNotifier.value.length;
    sketchesNotifier.addListener(_sketchesCountListener);
  }

  final ValueNotifier<List<Sketch>> sketchesNotifier;
  final ValueNotifier<Sketch?> currentSketchNotifier;

  ///Collection of sketches that can be redone.
  late final List<Sketch> _redoStack = [];

  ///Whether redo operation is possible.
  ValueNotifier<bool> get canRedo => _canRedo;
  late final ValueNotifier<bool> _canRedo = ValueNotifier(false);

  late int _sketchCount;

  void _sketchesCountListener() {
    if (sketchesNotifier.value.length > _sketchCount) {
      //if a new sketch is drawn,
      //history is invalidated so clear redo stack
      _redoStack.clear();
      _canRedo.value = false;
      _sketchCount = sketchesNotifier.value.length;
    }
  }

  void clear() {
    _sketchCount = 0;
    sketchesNotifier.value = [];
    _canRedo.value = false;
    currentSketchNotifier.value = null;
  }

  void undo() {
    final sketches = List<Sketch>.from(sketchesNotifier.value);
    if (sketches.isNotEmpty) {
      _sketchCount--;
      _redoStack.add(sketches.removeLast());
      sketchesNotifier.value = sketches;
      _canRedo.value = true;
      currentSketchNotifier.value = null;
    }
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final sketch = _redoStack.removeLast();
    _canRedo.value = _redoStack.isNotEmpty;
    _sketchCount++;
    sketchesNotifier.value = [...sketchesNotifier.value, sketch];
  }

  void dispose() {
    sketchesNotifier.removeListener(_sketchesCountListener);
  }
}

class ErazerSizeSlider extends HookWidget {
  final ValueNotifier<double> eraserSize;

  const ErazerSizeSlider({super.key, required this.eraserSize});

  @override
  Widget build(BuildContext context) {
    final internalEraserSize = useState(eraserSize.value);

    useEffect(
      () {
        Future.delayed(const Duration(milliseconds: 1)).then((value) {
          eraserSize.value = internalEraserSize.value;
        });
        return null;
      },
      [internalEraserSize.value],
    );

    return Slider(
      value: internalEraserSize.value,
      min: 0,
      max: 80,
      onChanged: (val) {
        internalEraserSize.value = val;
      },
    );
  }
}

class StrokeSizeSlider extends HookWidget {
  final ValueNotifier<double> strokeSize;

  const StrokeSizeSlider({super.key, required this.strokeSize});

  @override
  Widget build(BuildContext context) {
    final internalStrokeSize = useState(strokeSize.value);

    useEffect(
      () {
        Future.delayed(const Duration(milliseconds: 1)).then((value) {
          strokeSize.value = internalStrokeSize.value;
        });
        return null;
      },
      [internalStrokeSize.value],
    );

    return Slider(
      value: internalStrokeSize.value,
      min: 0,
      max: 50,
      onChanged: (val) {
        internalStrokeSize.value = val;
      },
    );
  }
}

class PolygonSidesSlider extends HookWidget {
  final ValueNotifier<int> polygonSides;

  const PolygonSidesSlider({super.key, required this.polygonSides});

  @override
  Widget build(BuildContext context) {
    final internalPolygonSides = useState(polygonSides.value);

    useEffect(
      () {
        Future.delayed(const Duration(milliseconds: 1)).then((value) {
          polygonSides.value = internalPolygonSides.value;
        });
        return null;
      },
      [internalPolygonSides.value],
    );

    return Slider(
      value: internalPolygonSides.value.toDouble(),
      min: 3,
      max: 8,
      onChanged: (val) {
        internalPolygonSides.value = val.toInt();
      },
      label: '${internalPolygonSides.value}',
      divisions: 5,
    );
  }
}

class RulerChooser extends HookWidget {
  final ValueNotifier<RulerType?> rulerType;

  const RulerChooser(this.rulerType, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                rulerType.value = RulerType.ruler;
              },
              icon: SvgPicture.asset(
                'assets/svgs/ruler_ruler.svg',
                width: 30,
                height: 30,
              ),
            ),
            IconButton(
              onPressed: () {
                rulerType.value = RulerType.triangle;
              },
              icon: SvgPicture.asset(
                'assets/svgs/ruler_triangle.svg',
                width: 26,
                height: 26,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                rulerType.value = RulerType.protractor;
              },
              icon: SvgPicture.asset(
                'assets/svgs/ruler_protractor.svg',
                width: 30,
                height: 30,
              ),
            ),
            IconButton(
              onPressed: () {
                rulerType.value = null;
              },
              color: const Color.fromARGB(255, 226, 68, 68),
              icon: const Icon(Icons.clear),
            ),
          ],
        ),
      ],
    );
  }
}
