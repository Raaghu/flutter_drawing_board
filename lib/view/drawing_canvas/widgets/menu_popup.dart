import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PopupMenuState {
  final Offset offset;
  final double width;
  final double height;
  final Widget content;
  const PopupMenuState(
    this.offset,
    this.content, {
    this.width = 100,
    this.height = 100,
  });
}

class PopupMenu extends HookWidget {
  final ValueNotifier<PopupMenuState?> popupMenuState;

  const PopupMenu(this.popupMenuState, {super.key});

  @override
  Widget build(BuildContext context) {
    if (popupMenuState.value == null) {
      return Container();
    }

    return Positioned(
      left: popupMenuState.value!.offset.dx - popupMenuState.value!.width / 2,
      top: popupMenuState.value!.offset.dy - popupMenuState.value!.height - 5,
      child: Container(
        width: popupMenuState.value!.width,
        height: popupMenuState.value!.height,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          border: Border.all(
            color: Colors.grey,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(5),
        child: popupMenuState.value!.content,
      ),
    );
  }
}
