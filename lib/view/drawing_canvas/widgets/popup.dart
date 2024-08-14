import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PopUpState {
  final String url;
  final double dx;
  final double dy;
  const PopUpState(this.url, this.dx, this.dy);
}

class PopUp extends HookWidget {
  final ValueNotifier<PopUpState?> popup;

  const PopUp(this.popup, {super.key});

  @override
  Widget build(BuildContext context) {

    final dx = useState<double>(popup.value?.dx ?? 0);
    final dy = useState<double>(popup.value?.dy ?? 0);

    return Positioned(
        left: dx.value,
        top: dy.value,
        child: Draggable(
          feedback: _buildWebView(popup.value?.url ?? 'https://google.com'),
          childWhenDragging: Container(),
          onDraggableCanceled: (Velocity velocity, Offset offset) {
            dx.value = offset.dx;
            dy.value = offset.dy;
          },
          child: _buildWebView(popup.value?.url ?? 'https://google.com'),
        ));
  }

  Widget _buildWebView(String url) {
    var controller = WebViewController()
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

    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromARGB(255, 218, 218, 218)),
      ),
      padding: const EdgeInsets.only(top:15.0),
      child: WebViewWidget(controller: controller),
    );
  }
}
