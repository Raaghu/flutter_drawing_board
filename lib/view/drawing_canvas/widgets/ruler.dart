import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/view/drawing_canvas/models/ruler_type.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Ruler extends HookWidget {
  final ValueNotifier<RulerType?> rulerType;

  const Ruler(this.rulerType, {super.key});

  @override
  Widget build(BuildContext context) {
    final rotationAngle = useState(0.0);
    final previousRotation = useState(0.0);

    final position = useState(const Offset(200, 200));

    final rulerTypeToImageMap = {
      RulerType.ruler: 'assets/pngs/ruler_ruler.png',
      RulerType.triangle: 'assets/pngs/ruler_triangle.png',
      RulerType.protractor: 'assets/pngs/ruler_protractor.png',
    };

    return Positioned(
        left: position.value.dx,
        top: position.value.dy,
        width: 400,
        child: GestureDetector(
          onScaleStart: (details) {
            previousRotation.value = rotationAngle.value;
          },
          onScaleUpdate: (details) {
            rotationAngle.value = previousRotation.value + details.rotation;
            position.value = position.value + details.focalPointDelta;
          },
          child: Transform.rotate(
            angle: rotationAngle.value,
            child: Image.asset(
              rulerTypeToImageMap[rulerType.value ?? RulerType.ruler]!,
            ), // Replace with your image
          ),
        ));
  }
}
