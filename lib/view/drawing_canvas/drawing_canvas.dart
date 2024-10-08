import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:flutter_drawing_board/main.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/drawing_mode.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/sketch.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/widgets/search.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DrawingCanvas extends HookWidget {
  final double height;
  final double width;
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<Image?> backgroundImage;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingMode> drawingMode;
  final AnimationController sideBarController;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<bool> filled;
  final ValueNotifier<SearchState?> search;

  final GlobalKey _globalKey = GlobalKey();

  DrawingCanvas({
    Key? key,
    required this.height,
    required this.width,
    required this.selectedColor,
    required this.strokeSize,
    required this.eraserSize,
    required this.drawingMode,
    required this.sideBarController,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.polygonSides,
    required this.backgroundImage,
    required this.search
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: Stack(
        children: [
          buildAllSketches(context),
          buildCurrentPath(context),
        ],
      ),
    );
  }

  void onPointerDown(PointerDownEvent details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.position);
    currentSketch.value = Sketch.fromDrawingMode(
      Sketch(
        points: [offset],
        pointStrokeTimes: [DateTime.now().millisecondsSinceEpoch],
        size: drawingMode.value == DrawingMode.eraser
            ? eraserSize.value
            : strokeSize.value,
        color: drawingMode.value == DrawingMode.eraser
            ? kCanvasColor
            : selectedColor.value,
        sides: polygonSides.value,
      ),
      drawingMode.value,
      filled.value,
    );
  }

  void onPointerMove(PointerMoveEvent details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.position);
    var points = List<Offset>.from(currentSketch.value?.points ?? [])
      ..add(offset);

    final currentTimeInMillis = DateTime.now().millisecondsSinceEpoch;
    var pointStrokeTimes = List<int>.from(currentSketch.value?.pointStrokeTimes??[])
      ..add(currentTimeInMillis);

    if(drawingMode.value == DrawingMode.search){
      search.value = null;
    }
    
    if(![DrawingMode.eraser, DrawingMode.pencil].contains(drawingMode.value) && points.length > 1){
      points = [points.first, points.last];
      pointStrokeTimes = [pointStrokeTimes.first, pointStrokeTimes.last];
    }

    currentSketch.value = Sketch.fromDrawingMode(
      Sketch(
        points: points,
        pointStrokeTimes: pointStrokeTimes,
        size: drawingMode.value == DrawingMode.eraser
            ? eraserSize.value
            : strokeSize.value,
        color: drawingMode.value == DrawingMode.eraser
            ? kCanvasColor
            : selectedColor.value,
        sides: polygonSides.value,
      ),
      drawingMode.value,
      filled.value,
    );
  }

  void onPointerUp(PointerUpEvent details) {
    allSketches.value = List<Sketch>.from(allSketches.value)
      ..add(Sketch.save(currentSketch.value!));
    currentSketch.value = Sketch.fromDrawingMode(
      Sketch(
        points: [],
        pointStrokeTimes: [],
        size: drawingMode.value == DrawingMode.eraser
            ? eraserSize.value
            : strokeSize.value,
        color: drawingMode.value == DrawingMode.eraser
            ? kCanvasColor
            : selectedColor.value,
        sides: polygonSides.value,
      ),
      drawingMode.value,
      filled.value,
    );
    if(drawingMode.value == DrawingMode.search){
      _onSearch();
    }
  }

  Widget buildAllSketches(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ValueListenableBuilder<List<Sketch>>(
        valueListenable: allSketches,
        builder: (context, sketches, _) {
          return RepaintBoundary(
            key: canvasGlobalKey,
            child: Container(
              height: height,
              width: width,
              color: kCanvasColor,
              child: CustomPaint(
                painter: SketchPainter(
                  sketches: sketches,
                  backgroundImage: backgroundImage.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildCurrentPath(BuildContext context) {
    return Listener(
      onPointerDown: (details) => onPointerDown(details, context),
      onPointerMove: (details) => onPointerMove(details, context),
      onPointerUp: onPointerUp,
      child: ValueListenableBuilder(
        valueListenable: currentSketch,
        builder: (context, sketch, child) {
          return RepaintBoundary(
            child: SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                painter: SketchPainter(
                  sketches: sketch == null ? [] : [sketch],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onSearch(){
    final selectedArea = allSketches.value.removeLast();
    final firstPoint = selectedArea.points.first;
    final lastPoint = selectedArea.points.last;

    final List<Sketch> copyOfAllSketches = [];
    for(final sketch in allSketches.value){
      copyOfAllSketches.add(Sketch.fromJson(sketch.toJson()));
    }

    search.value = SearchState(firstPoint,lastPoint, copyOfAllSketches);
  }
}

class SketchPainter extends CustomPainter {
  final List<Sketch> sketches;
  final Image? backgroundImage;

  const SketchPainter({
    Key? key,
    this.backgroundImage,
    required this.sketches,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(
          0,
          0,
          backgroundImage!.width.toDouble(),
          backgroundImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }
    for (Sketch sketch in sketches) {
      final points = sketch.points;

      if (points.isEmpty) return;

      final path = Path();

      path.moveTo(points[0].dx, points[0].dy);
      if (points.length < 2) {
        // If the path only has one line, draw a dot.
        path.addOval(
          Rect.fromCircle(
            center: Offset(points[0].dx, points[0].dy),
            radius: 1,
          ),
        );
      }

      for (int i = 1; i < points.length - 1; ++i) {
        final p0 = points[i];
        final p1 = points[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }

      Paint paint = Paint()
        ..color = sketch.color
        ..strokeCap = StrokeCap.round;

      if (!sketch.filled) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = sketch.size;
      }

      // define first and last points for convenience
      Offset firstPoint = sketch.points.first;
      Offset lastPoint = sketch.points.last;

      // create rect to use rectangle and circle
      Rect rect = Rect.fromPoints(firstPoint, lastPoint);

      // Calculate center point from the first and last points
      Offset centerPoint = (firstPoint / 2) + (lastPoint / 2);

      // Calculate path's radius from the first and last points
      double radius = (firstPoint - lastPoint).distance / 2;

      if (sketch.type == SketchType.scribble) {
        canvas.drawPath(path, paint);
      } else if (sketch.type == SketchType.square) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(5)),
          paint,
        );
      } else if (sketch.type == SketchType.line) {
        canvas.drawLine(firstPoint, lastPoint, paint);
      } else if(sketch.type == SketchType.arrow){
        _drawArrow(firstPoint, lastPoint, canvas, paint);
      }else if(sketch.type == SketchType.search){
        final borderPaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        _drawDottedLine(canvas, rect.topLeft, rect.topRight, borderPaint);
        _drawDottedLine(canvas, rect.topRight, rect.bottomRight, borderPaint);
        _drawDottedLine(canvas, rect.bottomRight, rect.bottomLeft, borderPaint);
        _drawDottedLine(canvas, rect.bottomLeft, rect.topLeft, borderPaint);
      }else if (sketch.type == SketchType.circle) {
        canvas.drawOval(rect, paint);
        // Uncomment this line if you need a PERFECT CIRCLE
        // canvas.drawCircle(centerPoint, radius , paint);
      } else if (sketch.type == SketchType.polygon) {
        Path polygonPath = Path();
        int sides = sketch.sides;
        var angle = (math.pi * 2) / sides;

        double radian = 0.0;

        Offset startPoint =
            Offset(radius * math.cos(radian), radius * math.sin(radian));

        polygonPath.moveTo(
          startPoint.dx + centerPoint.dx,
          startPoint.dy + centerPoint.dy,
        );
        for (int i = 1; i <= sides; i++) {
          double x = radius * math.cos(radian + angle * i) + centerPoint.dx;
          double y = radius * math.sin(radian + angle * i) + centerPoint.dy;
          polygonPath.lineTo(x, y);
        }
        polygonPath.close();
        canvas.drawPath(polygonPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return oldDelegate.sketches != sketches;
  }

  void _drawArrow(Offset a, Offset b, Canvas canvas, Paint paint) {
    const arrowSize = 10;
    const arrowAngle = math.pi / 6;

    final dX = b.dx - a.dx;
    final dY = b.dy - a.dy;
    final angle = math.atan2(dY, dX);

    // Recalculate b such that it's the end of the line minus the arrow.
    final Offset subtractedB = Offset(
      b.dx - (arrowSize - 2) * math.cos(angle),
      b.dy - (arrowSize - 2) * math.sin(angle),
    );

    canvas.drawLine(a, subtractedB, paint);
    final path = Path();

    path.moveTo(b.dx - arrowSize * math.cos(angle - arrowAngle),
        b.dy - arrowSize * math.sin(angle - arrowAngle));
    path.lineTo(b.dx, b.dy);
    path.lineTo(b.dx - arrowSize * math.cos(angle + arrowAngle),
        b.dy - arrowSize * math.sin(angle + arrowAngle));
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDottedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dotSize = 1.0;
    const double spaceSize = 2.0;
    final double totalDistance = (end - start).distance;
    final int dotCount = (totalDistance / (dotSize + spaceSize)).floor();

    for (int i = 0; i < dotCount; i++) {
      final double progress = i / dotCount;
      final Offset? currentPoint = Offset.lerp(start, end, progress);
      if (currentPoint != null) {
        canvas.drawCircle(currentPoint, dotSize / 2, paint);
      }
    }
  }
}
