import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/drawing_mode.dart';

class Sketch {
  final List<Offset> points;
  final List<int> pointStrokeTimes;
  final Color color;
  final double size;
  final SketchType type;
  final bool filled;
  final int sides;
  final bool current;

  Sketch({
    required this.points,
    required this.pointStrokeTimes,
    this.color = Colors.black,
    this.type = SketchType.scribble,
    this.filled = true,
    this.sides = 3,
    required this.size,
    this.current = true,
  });

  factory Sketch.fromDrawingMode(
    Sketch sketch,
    DrawingMode drawingMode,
    bool filled,
  ) {
    return Sketch(
      points: sketch.points,
      pointStrokeTimes: sketch.pointStrokeTimes,
      color: sketch.color,
      size: sketch.size,
      filled: drawingMode == DrawingMode.line ||
              drawingMode == DrawingMode.arrow ||
              drawingMode == DrawingMode.pencil ||
              drawingMode == DrawingMode.eraser
          ? false
          : filled,
      sides: sketch.sides,
      current: sketch.current,
      type: () {
        switch (drawingMode) {
          case DrawingMode.eraser:
          case DrawingMode.pencil:
            return SketchType.scribble;
          case DrawingMode.line:
            return SketchType.line;
          case DrawingMode.arrow:
            return SketchType.arrow;
          case DrawingMode.square:
            return SketchType.square;
          case DrawingMode.circle:
            return SketchType.circle;
          case DrawingMode.polygon:
            return SketchType.polygon;
          case DrawingMode.search:
            return SketchType.search;
          default:
            return SketchType.scribble;
        }
      }(),
    );
  }

  factory Sketch.save(
    Sketch sketch,
  ) {
    return Sketch(
      points: sketch.points,
      pointStrokeTimes: sketch.pointStrokeTimes,
      size: sketch.size,
      color: sketch.color,
      filled: sketch.filled,
      sides: sketch.sides,
      type: sketch.type,
      current: false,
    );
  }

  Map<String, dynamic> toJson() {
    List<Map> pointsMap = points.map((e) => {'dx': e.dx, 'dy': e.dy}).toList();
    return {
      'points': pointsMap,
      'pointStrokeTimes': pointStrokeTimes,
      'color': color.toHex(),
      'size': size,
      'filled': filled,
      'type': type.toRegularString(),
      'sides': sides,
    };
  }

  factory Sketch.fromJson(Map<String, dynamic> json) {
    List<Offset> points =
        (json['points'] as List).map((e) => Offset(e['dx'], e['dy'])).toList();
    return Sketch(
      points: points,
      pointStrokeTimes: json['pointStrokeTimes'],
      color: (json['color'] as String).toColor(),
      size: json['size'],
      filled: json['filled'],
      type: (json['type'] as String).toSketchTypeEnum(),
      sides: json['sides'],
    );
  }
}

enum SketchType { scribble, line, square, circle, polygon, arrow, search }

extension SketchTypeX on SketchType {
  String toRegularString() => toString().split('.')[1];
}

extension SketchTypeExtension on String {
  SketchType toSketchTypeEnum() =>
      SketchType.values.firstWhere((e) => e.toString() == 'SketchType.$this');
}

extension ColorExtension on String {
  Color toColor() {
    var hexColor = replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    } else {
      return Colors.black;
    }
  }
}

extension ColorExtensionX on Color {
  String toHex() => '#${value.toRadixString(16).substring(2, 8)}';
}
