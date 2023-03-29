// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey _mainKey = GlobalKey();
  final GlobalKey _minimapKey = GlobalKey();

  final ScrollController _controller1 = ScrollController();
  final ScrollController _controller2 = ScrollController();
  List<Widget> _widgets = <Widget>[];
  Uint8List? _imageBytes = Uint8List(0);

  double _contentHeight = 0;
  double _minimapHeight = 0;
  double _ratio = 0.5;

  final availableHeight = 700;

  String text =
      "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // _calculateValue();
      // _setScrolling();
      // await getImageBytesFromWidget(_mainKey);
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  void _calculateValue() {
    print('_calculateValue called');
    double contentHeight = _mainKey.currentContext!.size!.height;
    // double minimapHeight = _minimapKey.currentContext!.size!.height;
    double minimapHeight = contentHeight * _ratio;
    // double ratio = contentHeight / minimapHeight;

    print('contentHeight $contentHeight');
    print('minimapHeight $minimapHeight');

    setState(() {
      _contentHeight = contentHeight;
      _minimapHeight = minimapHeight;
      // _ratio = ratio;
    });
  }

  void _setScrolling() {
    print('_setScrolling called');
    _controller2.addListener(() {
      _controller1.jumpTo(_controller2.offset / _ratio);
    });
  }

  void _setThumbPosition(TapDownDetails details) {
    var x = details.globalPosition.dx;
    var y = details.globalPosition.dy;

    print(details.localPosition);

    var dy = details.localPosition.dy;

    if (_minimapHeight < 700) {
      _controller1.jumpTo(dy * (1 / _ratio));
    } else {
      double length = _controller2.offset * 2 + dy * 2;
      _controller1.jumpTo(length);
    }
  }

  void _scrollMinimap(TapUpDetails details) {
    if (_minimapHeight > 700) {
      // _controller1.addListener(() {
      _controller2.jumpTo(_controller1.offset * _ratio);
      // });
    }
  }

  void addWidget() async {
    List<Widget> widgets = _widgets;

    widgets.add(
      Container(
        key: ValueKey(_widgets.length),
        height: 400,
        color: Colors.primaries[(Random().nextInt(Colors.primaries.length) *
                Random().nextInt(Colors.primaries.length)) %
            17],
        child: Text(text),
      ),
    );

    setState(() {
      _widgets = widgets;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final RenderRepaintBoundary boundary =
          _mainKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      print(pngBytes);
      setState(() {
        _imageBytes = pngBytes;
        _calculateValue();
        _setScrolling();
      });
    });

    // await getImageBytesFromWidget(_mainKey);
    print('getbytes called after adding widget');
  }

  // Future<void> getImageBytesFromWidget(GlobalKey key) async {
  //   print('getImageBytesFromWidget called');
  //   try {
  //     final RenderRepaintBoundary boundary =
  //         key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  //     final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  //     final ByteData? byteData =
  //         await image.toByteData(format: ui.ImageByteFormat.png);
  //     final Uint8List pngBytes = byteData!.buffer.asUint8List();
  //     print(pngBytes);
  //     setState(() {
  //       _imageBytes = pngBytes;
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimap Example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('minimap'),
          leading: GestureDetector(
            onTap: () {
              addWidget();
            },
            child: const Icon(Icons.add),
          ),
        ),
        body: SafeArea(
          child: Row(
            children: [
              // GestureDetector(
              //   onTapUp: (details) => _scrollMinimap(details),
              Expanded(
                child: GestureDetector(
                  onTapUp: (details) => _scrollMinimap(details),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      controller: _controller1,
                      child: RepaintBoundary(
                        key: _mainKey,
                        child: Column(
                          children: [..._widgets],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // ),
              SizedBox(
                width: 10,
              ),
              GestureDetector(
                // onTap: (details) {
                //   _setThumbPosition(details);
                // },
                onTapDown: (details) => _setThumbPosition(details),
                child: Container(
                  key: _minimapKey,
                  width: 100.0,
                  color: Colors.grey,
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      controller: _controller2,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: 0, // Set a minimum height
                          maxHeight: _minimapHeight, // Set a maximum height
                        ),
                        child: _imageBytes!.isNotEmpty
                            ? Stack(
                                children: [
                                  Positioned.fill(
                                    top: 0,
                                    right: 0,
                                    child: Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              )
                            : Container(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class Minimap extends StatefulWidget {
//   final GlobalKey mainKey;
//   final GlobalKey minimapKey;

//   Minimap({required this.mainKey, required this.minimapKey});

//   //  void getImageBytesFromWidget(GlobalKey key) async {
//   //   try {
//   //     final RenderRepaintBoundary boundary =
//   //         key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
//   //     final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//   //     final ByteData? byteData =
//   //         await image.toByteData(format: ui.ImageByteFormat.png);
//   //     final Uint8List pngBytes = byteData!.buffer.asUint8List();

//   //   } catch (e) {
//   //     print(e);
//   //   }
//   // }

//   @override
//   _MinimapState createState() => _MinimapState();
// }

// class _MinimapState extends State<Minimap> {
//   late double _minimapWidth = 100.0;
//   late double _minimapHeight = 300.0;
//   late double _contentHeight = 100;
//   final ScrollController mainScrollController = ScrollController();

//   late double boundary;

//   ui.Image? _image;
//   Uint8List? _imageBytes = Uint8List(0);

//   @override
//   void initState() {
//     super.initState();
//     // _init();

//     WidgetsBinding.instance.addPostFrameCallback((_) => _init());
//   }

//   void _init() async {
//     // Get the size of the content
//     print(widget.mainKey.currentContext);
//     print(widget.minimapKey.currentContext);

//     double contentHeight = widget.mainKey.currentContext!.size!.height;
//     print("contentHeight  $contentHeight");

//     // if (widget.mainKey.currentContext != null) {
//     //   final RenderBox renderBox =
//     //       widget.mainKey.currentContext!.findRenderObject() as RenderBox;
//     //   contentHeight = renderBox.size.height;
//     //   boundary = MediaQuery.of(context).size.height;
//     // } else {
//     //   print('mainKey currentContext is null');
//     // }

//     // Get the size of the minimap

//     double minimapHeight = widget.minimapKey.currentContext!.size!.height;
//     double minimapWidth = widget.minimapKey.currentContext!.size!.width;

//     // if (widget.minimapKey.currentContext != null) {
//     //   final RenderBox minimapBox =
//     //       widget.minimapKey.currentContext!.findRenderObject() as RenderBox;
//     //   minimapHeight = minimapBox.size.height;
//     //   minimapWidth = minimapBox.size.width;
//     // }

//     // Get the screenshot of the main page
//     final Uint8List? imageBytes = await getImageBytesFromWidget(widget.mainKey);

//     // ui.Image? image = Image.memory(imageBytes!) as ui.Image?;

//     setState(() {
//       _imageBytes = imageBytes;
//       _contentHeight = contentHeight;
//       _minimapHeight = minimapHeight;
//       _minimapWidth = minimapWidth;
//       // _image = image;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_imageBytes != Uint8List(0)) {
//       print(_imageBytes);
//       return Container(
//         child: Stack(
//           children: [
//             Positioned.fill(
//               top: 0,
//               right: 0,
//               child: Image.memory(
//                 _imageBytes!,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             // SizedBox(
//             //   width: 100.0,
//             //   child: RepaintBoundary(
//             //     // key: widget.minimapKey,
//             //     child: CustomPaint(
//             //       painter: MinimapPainter(
//             //         mainKey: widget.mainKey,
//             //         contentHeight: _contentHeight,
//             //         minimapHeight: _minimapHeight,
//             //         minimapWidth: _minimapWidth,
//             //       ),
//             //     ),
//             //   ),
//             // ),
//           ],
//         ),
//       );
//     } else {
//       return const Text(
//         'Loading',
//       );
//     }
//   }
// }

// class MinimapPainter extends CustomPainter {
//   MinimapPainter({
//     required this.mainKey,
//     required this.contentHeight,
//     required this.minimapHeight,
//     required this.minimapWidth,
//   });

//   final GlobalKey mainKey;
//   final double contentHeight;
//   final double minimapHeight;
//   final double minimapWidth;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint();
//     // Draw the content indicator
//     paint.color = Colors.grey;
//     paint.style = PaintingStyle.fill;
//     final contentRatio = minimapHeight / contentHeight;
//     canvas.drawRect(
//       Rect.fromLTRB(
//         0,
//         0,
//         minimapWidth,
//         contentHeight * contentRatio,
//       ),
//       paint,
//     );
//     // Draw the viewport indicator
//     paint.color = Colors.red;
//     paint.style = PaintingStyle.stroke;
//     paint.strokeWidth = 2.0;
//     final RenderBox? mainRenderBox =
//         mainKey.currentContext!.findRenderObject() as RenderBox?;
//     if (mainRenderBox != null) {
//       final viewportHeight = mainRenderBox.size.height;
//       final viewportRatio = minimapHeight / contentHeight;
//       final viewportOffset = mainRenderBox.size.height * viewportRatio;
//       canvas.drawRect(
//         Rect.fromLTRB(
//           0,
//           viewportOffset,
//           minimapWidth,
//           viewportOffset + viewportHeight * viewportRatio,
//         ),
//         paint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(MinimapPainter oldDelegate) => true;
// }