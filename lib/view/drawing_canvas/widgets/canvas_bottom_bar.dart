import 'package:flutter/material.dart' hide Image;
import 'package:flutter_drawing_board/view/drawing_canvas/models/drawing_mode.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CanvasBottomBar extends HookWidget {
  final ValueNotifier<DrawingMode> drawingMode;

  const CanvasBottomBar({
    Key? key,
    required this.drawingMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    return Container(
      height: MediaQuery.of(context).size.height < 680 ? 40 : 50,
      /*decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 3,
            offset: const Offset(3, 3),
          ),
        ],
      ),*/
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
              iconData: FontAwesomeIcons.pencil,
              selected: drawingMode.value == DrawingMode.pencil,
              onTap: () => drawingMode.value = DrawingMode.pencil,
              tooltip: 'Pencil',
            ),
            _IconBox(
              selected: drawingMode.value == DrawingMode.line,
              onTap: () => drawingMode.value = DrawingMode.line,
              tooltip: 'Line',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22,
                    height: 2,
                    color: drawingMode.value == DrawingMode.line
                        ? const Color.fromARGB(255, 0, 238, 255)
                        : Colors.grey,
                  ),
                ],
              ),
            ),
            _IconBox(
              iconData: Icons.arrow_right_alt,
              selected: drawingMode.value == DrawingMode.arrow,
              onTap: () => drawingMode.value = DrawingMode.arrow,
              tooltip: 'Arrow',
            ),
            _IconBox(
              iconData: Icons.hexagon_outlined,
              selected: drawingMode.value == DrawingMode.polygon,
              onTap: () => drawingMode.value = DrawingMode.polygon,
              tooltip: 'Polygon',
            ),
            _IconBox(
              iconData: FontAwesomeIcons.eraser,
              selected: drawingMode.value == DrawingMode.eraser,
              onTap: () => drawingMode.value = DrawingMode.eraser,
              tooltip: 'Eraser',
            ),
            _IconBox(
              iconData: FontAwesomeIcons.square,
              selected: drawingMode.value == DrawingMode.square,
              onTap: () => drawingMode.value = DrawingMode.square,
              tooltip: 'Square',
            ),
            _IconBox(
              iconData: FontAwesomeIcons.circle,
              selected: drawingMode.value == DrawingMode.circle,
              onTap: () => drawingMode.value = DrawingMode.circle,
              tooltip: 'Circle',
            ),
            _IconBox(
              iconData: Icons.search,
              selected: drawingMode.value == DrawingMode.search,
              onTap: () => drawingMode.value = DrawingMode.search,
              tooltip: 'Circle',
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconBox({
    Key? key,
    this.iconData,
    this.child,
    this.tooltip,
    required this.selected,
    required this.onTap,
  })  : assert(child != null || iconData != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ?const Color.fromARGB(255, 0, 238, 255)! : Colors.grey,
              width: 1.5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Tooltip(
            message: tooltip,
            preferBelow: false,
            child: child ??
                Icon(
                  iconData,
                  color: selected ? const Color.fromARGB(255, 0, 238, 255) : Colors.grey,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}
