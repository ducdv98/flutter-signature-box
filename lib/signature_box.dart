library signature_box;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ClearButtonOptions {
  const ClearButtonOptions({
    this.hasClearButton = true,
    this.buttonText = 'Clear',
    this.position = Alignment.bottomRight,
  });

  final bool hasClearButton;
  final String buttonText;
  final AlignmentGeometry position;
}

class PaintOptions {
  const PaintOptions({
    this.penColor = Colors.black,
    this.strokeWidth = 2,
  });

  final Color penColor;
  final double strokeWidth;
}

class SignatureBox extends StatefulWidget {
  const SignatureBox({
    @required this.width,
    @required this.height,
    @required this.onChanged,
    this.hasBaseline = false,
    this.paintOptions,
    this.clearButtonOptions,
    this.boxDecoration,
    Key key,
  })  : assert(width != null),
        assert(height != null),
        assert(onChanged != null),
        assert(hasBaseline != null),
        super(key: key);

  final double width;
  final double height;
  final PaintOptions paintOptions;
  final ClearButtonOptions clearButtonOptions;
  final BoxDecoration boxDecoration;
  final bool hasBaseline;
  final ValueChanged<List<Offset>> onChanged;

  @override
  _SignatureBoxState createState() => _SignatureBoxState();
}

class _SignatureBoxState extends State<SignatureBox> {
  final _points = <Offset>[];

  Timer _timer;

  @override
  Widget build(BuildContext context) {
    final _clearOptions = widget.clearButtonOptions ?? ClearButtonOptions();
    final _decoration = widget.boxDecoration ??
        BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Colors.blueGrey),
        );

    final _paint = widget.paintOptions ?? PaintOptions();

    final gestureDetector = GestureDetector(
      onPanUpdate: (details) {
        final RenderBox renderBox = context.findRenderObject();
        final containerSize = renderBox.size;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        if (localPosition.dx > 0 &&
            localPosition.dy > 0 &&
            localPosition.dx < containerSize.width - 1 &&
            localPosition.dy < containerSize.height - 1) {
          setState(() => _points.add(localPosition));

          _timer?.cancel();
          _timer = Timer(
            const Duration(milliseconds: 100),
            () => widget.onChanged(UnmodifiableListView(_points)),
          );
        }
      },
      onPanEnd: (details) => _points.add(null),
      child: CustomPaint(painter: _Painter(_points, _paint)),
    );

    final signatureArea = Container(
      height: widget.height,
      width: double.maxFinite,
      child: gestureDetector,
    );

    Widget baseline;
    if (widget.hasBaseline) {
      baseline = Padding(
        child: Divider(
          height: 2,
          thickness: 1,
          color: Colors.black,
        ),
        padding: EdgeInsets.only(
          bottom: 40,
          left: 20,
          right: 20,
        ),
      );
    }

    Widget clear;
    if (_clearOptions.hasClearButton) {
      clear = Align(
        alignment: _clearOptions.position,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: GestureDetector(
            child: Text(_clearOptions.buttonText),
            onTap: () {
              setState(() {
                _points.clear();
                widget.onChanged(UnmodifiableListView(_points));
              });
            },
          ),
        ),
      );
    }

    final body = Stack(
      children: [
        if (baseline != null) baseline,
        signatureArea,
        if (_points.isNotEmpty && clear != null) clear,
      ],
      alignment: Alignment.bottomCenter,
    );
    final box = Container(
      decoration: _decoration,
      child: body,
    );
    return box;
  }
}

class _Painter extends CustomPainter {
  const _Painter(
    this.points,
    this.paintOptions,
  );

  final List<Offset> points;
  final PaintOptions paintOptions;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length <= 1) {
      return;
    }

    final _painter = Paint()
      ..color = paintOptions.penColor
      ..strokeWidth = paintOptions.strokeWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], _painter);
      }
    }
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) => true;
}
