import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:desktop_window/desktop_window.dart';

class SnapshotServer {
  SnapshotServer();

  late HttpServer _server;

  Future<void> init() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    _server.listen(_handleRequest);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final Size size = Size(
      double.tryParse(request.uri.queryParameters["w"] ?? "") ?? 1920,
      double.tryParse(request.uri.queryParameters["h"] ?? "") ?? 1080,
    );
    print("Request received: ${request.uri.path}");
    switch (request.uri.path) {
      case "/":
    }
    await _captureScreenshot(request.response, size);
    request.response.close();
  }

  Future<void> _captureScreenshot(HttpResponse res, Size size) async {
    await DesktopWindow.setWindowSize(size);
    res
      ..headers.contentType = ContentType.parse("image/png")
      ..statusCode = HttpStatus.ok;

    try {
      final xwd = await Process.start(
        "xwd",
        ["-root", "-silent"],
      );
      final convert = await Process.start(
        'convert',
        [
          'xwd:-',
          '-crop',
          '${size.width.toInt()}x${size.height.toInt()}',
          'png:-',
        ],
      );
      // Catch any errors in the process pipeline
      xwd.stderr.listen((error) {
        print('Error in xwd: $error');
      });

      convert.stderr.listen((error) {
        print('Error in convert: $error');
      });

      final completer = Completer<void>();
      convert.stdout.listen(
        res.add,
        onDone: completer.complete,
        onError: completer.completeError,
      );

      xwd.stdout.listen(
        convert.stdin.add,
        onDone: convert.stdin.close,
        onError: completer.completeError,
      );

      await completer.future;
    } catch (e) {
      res
        ..statusCode = HttpStatus.internalServerError
        ..write('Error capturing screenshot');
    }
  }
}
