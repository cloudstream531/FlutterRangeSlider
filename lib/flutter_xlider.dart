import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:core';

double _touchSize;

/// A material design slider and range slider with rtl support and lots of options and customizations for flutter
class FlutterSlider extends StatefulWidget {
  final Key key;
  final Axis axis;
  final double handlerWidth;
  final double handlerHeight;
  final FlutterSliderHandler handler;
  final FlutterSliderHandler rightHandler;
  final Function(int handlerIndex, double lowerValue, double upperValue)
      onDragStarted;
  final Function(int handlerIndex, double lowerValue, double upperValue)
      onDragCompleted;
  final Function(int handlerIndex, double lowerValue, double upperValue)
      onDragging;
  final double min;
  final double max;
  final List<double> values;
  final bool rangeSlider;
  final bool rtl;
  final bool jump;
  final bool selectByTap;
  final List<FlutterSliderIgnoreSteps> ignoreSteps;
  final bool disabled;
  final double touchSize;
  final bool visibleTouchArea;
  final double minimumDistance;
  final double maximumDistance;
  final FlutterSliderHandlerAnimation handlerAnimation;
  final FlutterSliderTooltip tooltip;
  final FlutterSliderTrackBar trackBar;
  final double step;

  FlutterSlider(
      {this.key,
      @required this.min,
      @required this.max,
      @required this.values,
      this.axis = Axis.horizontal,
      this.handler,
      this.rightHandler,
      this.handlerHeight = 35,
      this.handlerWidth = 35,
      this.onDragStarted,
      this.onDragCompleted,
      this.onDragging,
      this.rangeSlider = false,
      this.rtl = false,
      this.jump = false,
      this.ignoreSteps = const [],
      this.disabled = false,
      this.touchSize,
      this.visibleTouchArea = false,
      this.minimumDistance = 0,
      this.maximumDistance = 0,
      this.tooltip,
      this.trackBar = const FlutterSliderTrackBar(),
      this.handlerAnimation = const FlutterSliderHandlerAnimation(),
      this.selectByTap = true,
      this.step = 1})
      : assert(touchSize == null ||
            (touchSize != null && (touchSize >= 10 && touchSize <= 100))),
        assert(values != null),
        assert(min != null && max != null && min <= max),
        assert(handlerAnimation != null),
        super(key: key);

  @override
  _FlutterSliderState createState() => _FlutterSliderState();
}

class _FlutterSliderState extends State<FlutterSlider>
    with TickerProviderStateMixin {
  Widget leftHandler;
  Widget rightHandler;

  double _leftHandlerXPosition = -1;
  double _rightHandlerXPosition = 0;
  double _leftHandlerYPosition = -1;
  double _rightHandlerYPosition = 0;

  double _lowerValue = 0;
  double _upperValue = 0;
  double _outputLowerValue = 0;
  double _outputUpperValue = 0;

  double _fakeMin;
  double _fakeMax;

  double _divisions;
  double _handlersPadding = 0;

  GlobalKey leftHandlerKey = GlobalKey();
  GlobalKey rightHandlerKey = GlobalKey();
  GlobalKey containerKey = GlobalKey();

  double _handlersWidth = 30;
  double _handlersHeight = 30;

  double _constraintMaxWidth;
  double _constraintMaxHeight;

  double _containerWidthWithoutPadding;
  double _containerHeightWithoutPadding;

  double _containerLeft = 0;
  double _containerTop = 0;

  FlutterSliderTooltip _tooltipData;

  List<Function> _positionedItems;

  double _finalLeftHandlerWidth;
  double _finalRightHandlerWidth;
  double _finalLeftHandlerHeight;
  double _finalRightHandlerHeight;

  double _rightTooltipOpacity = 0;
  double _leftTooltipOpacity = 0;

  AnimationController _rightTooltipAnimationController;
  Animation<Offset> _rightTooltipAnimation;
  AnimationController _leftTooltipAnimationController;
  Animation<Offset> _leftTooltipAnimation;

  AnimationController _leftHandlerScaleAnimationController;
  Animation<double> _leftHandlerScaleAnimation;
  AnimationController _rightHandlerScaleAnimationController;
  Animation<double> _rightHandlerScaleAnimation;

  double _originalMin;
  double _originalMax;

  /*toString. to compare new data with old ones*/
  String _originalLeftHandler;
  String _originalRightHandler;
  String _originalToolTipData;

  double _containerHeight;
  double _containerWidth;

  int _decimalScale = 0;

  double xDragTmp = 0;
  double yDragTmp = 0;

  double xDragStart;
  double yDragStart;

  double __dAxis,
      __rAxis,
      __axisDragTmp,
      __axisPosTmp,
      __containerSizeWithoutPadding,
      __rightHandlerPosition,
      __leftHandlerPosition,
      __containerSizeWithoutHandlerSize,
      __middle,
      __containerSizeWithoutHalfPadding,
      __handlerSize;

  void _setParameters() {
    _originalLeftHandler = widget.handler.toString();
    _originalRightHandler = widget.rightHandler.toString();

    _fakeMin = 0;
    _fakeMax = widget.max - widget.min;

    _divisions = _fakeMax / widget.step;

    String tmpDecimalScale = widget.step.toString().split(".")[1];
    if (int.parse(tmpDecimalScale) > 0) {
      _decimalScale = tmpDecimalScale.length;
    }

    _positionedItems = [
      _leftHandlerWidget,
      _rightHandlerWidget,
    ];

    _tooltipData = widget.tooltip ?? FlutterSliderTooltip();
    _tooltipData.boxStyle ??= FlutterSliderTooltipBox(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black12, width: 0.5),
            color: Color(0xffffffff)));
    _tooltipData.textStyle ??= TextStyle(fontSize: 12, color: Colors.black38);
    _tooltipData.leftPrefix ??= Container();
    _tooltipData.leftSuffix ??= Container();
    _tooltipData.rightPrefix ??= Container();
    _tooltipData.rightSuffix ??= Container();
    _tooltipData.alwaysShowTooltip ??= false;
    _tooltipData.disabled ??= false;

    _arrangeHandlersZIndex();

    _originalToolTipData = _tooltipData.toString();

    _generateHandler();
  }

  List<double> _calculateUpperAndLowerValues() {
    double localLV, localUV;
    localLV = widget.values[0];
    if (widget.rangeSlider) {
      localUV = widget.values[1];
    } else {
      // when direction is rtl, then we use left handler. so to make right hand side
      // as blue ( as if selected ), then upper value should be max
      if (widget.rtl) {
        localUV = widget.max;
      } else {
        // when direction is ltr, so we use right handler, to make left hand side of handler
        // as blue ( as if selected ), we set lower value to min, and upper value to (input lower value)
        localUV = localLV;
        localLV = widget.min;
      }
    }

    return [localLV, localUV];
  }

  void _setValues() {
    // lower value. if not available then min will be used

    List<double> localValues = _calculateUpperAndLowerValues();

    _lowerValue = localValues[0] - widget.min;
    _upperValue = localValues[1] - widget.min;

    _outputUpperValue = _displayRealValue(_upperValue);
    _outputLowerValue = _displayRealValue(_lowerValue);

    if (widget.rtl == true) {
      _outputLowerValue = _displayRealValue(_upperValue);
      _outputUpperValue = _displayRealValue(_lowerValue);

      double tmpUpperValue = _fakeMax - _lowerValue;
      double tmpLowerValue = _fakeMax - _upperValue;

      _lowerValue = tmpLowerValue;
      _upperValue = tmpUpperValue;
    }
  }

  void _arrangeHandlersPosition() {
    if (widget.axis == Axis.horizontal) {
      _handlersPadding = _handlersWidth / 2;
      _leftHandlerXPosition =
          (((_constraintMaxWidth - _handlersWidth) / _fakeMax) * _lowerValue) -
              (_touchSize);
      _rightHandlerXPosition =
          (((_constraintMaxWidth - _handlersWidth) / _fakeMax) * _upperValue) -
              (_touchSize);
    } else {
      _handlersPadding = _handlersHeight / 2;
      _leftHandlerYPosition =
          (((_constraintMaxHeight - _handlersHeight) / _fakeMax) *
                  _lowerValue) -
              (_touchSize);
      _rightHandlerYPosition =
          ((_constraintMaxHeight - _handlersHeight) / _fakeMax) * _upperValue -
              (_touchSize);
    }
  }

  @override
  void initState() {
    _touchSize = widget.touchSize ?? 25;

    // validate inputs
    _validations();

    // to display min of the range correctly.
    // if we use fakes, then min is always 0
    // so calculations works well, but when we want to display
    // result numbers to user, we add ( widget.min ) to the final numbers

    _handlersWidth = widget.handlerWidth;
    _handlersHeight = widget.handlerHeight;

    _finalLeftHandlerWidth = _handlersWidth;
    _finalRightHandlerWidth = _handlersWidth;
    _finalLeftHandlerHeight = _handlersHeight;
    _finalRightHandlerHeight = _handlersHeight;

    _leftHandlerScaleAnimationController = AnimationController(
        duration: widget.handlerAnimation.duration, vsync: this);
    _rightHandlerScaleAnimationController = AnimationController(
        duration: widget.handlerAnimation.duration, vsync: this);
    _leftHandlerScaleAnimation =
        Tween(begin: 1.0, end: widget.handlerAnimation.scale).animate(
            CurvedAnimation(
                parent: _leftHandlerScaleAnimationController,
                reverseCurve: widget.handlerAnimation.reverseCurve,
                curve: widget.handlerAnimation.curve));
    _rightHandlerScaleAnimation =
        Tween(begin: 1.0, end: widget.handlerAnimation.scale).animate(
            CurvedAnimation(
                parent: _rightHandlerScaleAnimationController,
                reverseCurve: widget.handlerAnimation.reverseCurve,
                curve: widget.handlerAnimation.curve));

    _originalMin = widget.min;
    _originalMax = widget.max;

    _setParameters();
    _setValues();

    if (widget.rangeSlider == true &&
        widget.maximumDistance != null &&
        widget.maximumDistance > 0 &&
        (_upperValue - _lowerValue) > widget.maximumDistance) {
      throw 'lower and upper distance is more than maximum distance';
    }
    if (widget.rangeSlider == true &&
        widget.minimumDistance != null &&
        widget.minimumDistance > 0 &&
        (_upperValue - _lowerValue) < widget.minimumDistance) {
      throw 'lower and upper distance is less than minimum distance';
    }

    _rightTooltipOpacity = (_tooltipData.alwaysShowTooltip == true) ? 1 : 0;
    _leftTooltipOpacity = (_tooltipData.alwaysShowTooltip == true) ? 1 : 0;

    Offset animationStart = Offset(0, 0.20);
    Offset animationFinish = Offset(0, -0.92);

    _leftTooltipAnimationController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    _leftTooltipAnimation =
        Tween<Offset>(begin: animationStart, end: animationFinish).animate(
            CurvedAnimation(
                parent: _leftTooltipAnimationController,
                curve: Curves.fastOutSlowIn));
    _rightTooltipAnimationController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    _rightTooltipAnimation =
        Tween<Offset>(begin: animationStart, end: animationFinish).animate(
            CurvedAnimation(
                parent: _rightTooltipAnimationController,
                curve: Curves.fastOutSlowIn));

    WidgetsBinding.instance.addPostFrameCallback(_initialize);

    super.initState();
  }

  _initialize(_) {
    _renderBoxInitialization();

    _handlersWidth = _finalLeftHandlerWidth;
    _handlersHeight = _finalLeftHandlerHeight;

    if (widget.rangeSlider == true &&
        _finalLeftHandlerWidth != _finalRightHandlerWidth) {
      throw 'ERROR: Width of both handlers should be equal';
    }

    if (widget.rangeSlider == true &&
        _finalLeftHandlerHeight != _finalRightHandlerHeight) {
      throw 'ERROR: Height of both handlers should be equal';
    }

    _arrangeHandlersPosition();

    setState(() {});
  }

  @override
  void didUpdateWidget(FlutterSlider oldWidget) {
    bool lowerValueEquality = oldWidget.values[0] != widget.values[0];
    bool upperValueEquality =
        (widget.values.length > 1 && oldWidget.values[1] != widget.values[1]);

    if (lowerValueEquality ||
        upperValueEquality ||
        _originalMin != widget.min ||
        _originalMax != widget.max ||
        _originalLeftHandler != widget.handler.toString() ||
        _originalRightHandler != widget.rightHandler.toString() ||
        _originalToolTipData != widget.tooltip.toString()) {
      bool reArrangePositions = false;

      _setParameters();

      if (lowerValueEquality || upperValueEquality) {
        reArrangePositions = true;
        _setValues();
      }

      if (reArrangePositions) {
        _arrangeHandlersPosition();
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      _constraintMaxWidth = constraints.maxWidth;
      _constraintMaxHeight = constraints.maxHeight;

      _containerWidthWithoutPadding = _constraintMaxWidth - _handlersWidth;

      _containerHeightWithoutPadding = _constraintMaxHeight - _handlersHeight;

      _containerWidth = constraints.maxWidth;
      _containerHeight = (_handlersHeight * 1.8);

      if (widget.axis == Axis.vertical) {
        _containerWidth = (_handlersWidth * 1.8);
        _containerHeight = constraints.maxHeight;
      }

      return Container(
        key: containerKey,
        height: _containerHeight,
        width: _containerWidth,
        child: Stack(
          overflow: Overflow.visible,
          children: drawHandlers(),
        ),
      );
    });
  }

  void _validations() {
    if (widget.rangeSlider == true && widget.values.length < 2)
      throw 'when range mode is true, slider needs both lower and upper values';

    if (widget.values[0] != null && widget.values[0] < widget.min)
      throw 'Lower value should be greater than min';

    if (widget.rangeSlider == true) {
      if (widget.values[1] != null && widget.values[1] > widget.max)
        throw 'Upper value should be smaller than max';
    }
  }

  void _generateHandler() {
    /*Right Handler Data*/
    FlutterSliderHandler tmpInputRightHandler;
    if (widget.rightHandler != null &&
        (widget.rightHandler.icon != null || widget.rightHandler.child != null))
      tmpInputRightHandler = widget.rightHandler;

    rightHandler = _MakeHandler(
      animation: _rightHandlerScaleAnimation,
      id: rightHandlerKey,
      visibleTouchArea: widget.visibleTouchArea,
      handlerData: tmpInputRightHandler ??
          FlutterSliderHandler(
              icon: Icon(
                  (widget.axis == Axis.horizontal)
                      ? Icons.chevron_left
                      : Icons.expand_less,
                  color: Colors.black45)),
      width: _handlersWidth,
      height: _handlersHeight,
      axis: widget.axis,
    );

    /*Left Handler Data*/
    IconData hIcon = (widget.axis == Axis.horizontal)
        ? Icons.chevron_right
        : Icons.expand_more;
    if (widget.rtl && !widget.rangeSlider) {
      hIcon = (widget.axis == Axis.horizontal)
          ? Icons.chevron_left
          : Icons.expand_less;
    }

    FlutterSliderHandler tmpInputHandler;
    if (widget.handler != null &&
        (widget.handler.icon != null || widget.handler.child != null))
      tmpInputHandler = widget.handler;

    leftHandler = _MakeHandler(
        animation: _leftHandlerScaleAnimation,
        id: leftHandlerKey,
        visibleTouchArea: widget.visibleTouchArea,
        handlerData: tmpInputHandler ??
            FlutterSliderHandler(icon: Icon(hIcon, color: Colors.black45)),
        width: _handlersWidth,
        height: _handlersHeight,
        axis: widget.axis);

    if (widget.rangeSlider == false) {
      rightHandler = leftHandler;
    }
  }

  void _leftHandlerMove(PointerEvent pointer,
      [double tappedPositionWithPadding = 0]) {
    if (widget.disabled || (widget.handler != null && widget.handler.disabled))
      return;

    bool validMove = true;

    if (widget.axis == Axis.horizontal) {
      __dAxis =
          pointer.position.dx - tappedPositionWithPadding - _containerLeft;
      __axisDragTmp = xDragTmp;
      __containerSizeWithoutPadding = _containerWidthWithoutPadding;
      __rightHandlerPosition = _rightHandlerXPosition;
      __leftHandlerPosition = _leftHandlerXPosition;
      __containerSizeWithoutHandlerSize = _constraintMaxWidth - _handlersWidth;
      __middle = __dAxis + ((_touchSize + _handlersWidth) / 2) - __axisDragTmp;
      __handlerSize = _handlersWidth;
    } else {
      __dAxis = pointer.position.dy - tappedPositionWithPadding - _containerTop;
      __axisDragTmp = yDragTmp;
      __containerSizeWithoutPadding = _containerHeightWithoutPadding;
      __rightHandlerPosition = _rightHandlerYPosition;
      __leftHandlerPosition = _leftHandlerYPosition;
      __containerSizeWithoutHandlerSize =
          _constraintMaxHeight - _handlersHeight;
      __middle = __dAxis + ((_touchSize + _handlersHeight) / 2) - __axisDragTmp;
      __handlerSize = _handlersHeight;
    }

    __axisPosTmp = __dAxis - __axisDragTmp + (_touchSize);
    __rAxis = ((__axisPosTmp / (__containerSizeWithoutPadding / _divisions)) *
        widget.step);
    __rAxis = (double.parse(__rAxis.toStringAsFixed(_decimalScale)) -
        double.parse((__rAxis % widget.step).toStringAsFixed(_decimalScale)));

    if (widget.rangeSlider &&
        widget.minimumDistance > 0 &&
        (__rAxis + widget.minimumDistance) >= _upperValue) {
      _lowerValue = (_upperValue - widget.minimumDistance > _fakeMin)
          ? _upperValue - widget.minimumDistance
          : _fakeMin;
      validMove = false;
      _updateLowerValue(_lowerValue);
    }

    if (widget.rangeSlider &&
        widget.maximumDistance > 0 &&
        __rAxis <= (_upperValue - widget.maximumDistance)) {
      _lowerValue = (_upperValue - widget.maximumDistance > _fakeMin)
          ? _upperValue - widget.maximumDistance
          : _fakeMin;
      validMove = false;
      _updateLowerValue(_lowerValue);
    }

    if (widget.ignoreSteps.length > 0) {
      for (FlutterSliderIgnoreSteps steps in widget.ignoreSteps) {
        if (!((widget.rtl == false &&
                (__rAxis >= steps.from && __rAxis <= steps.to) == false) ||
            (widget.rtl == true &&
                ((_fakeMax - __rAxis) >= steps.from &&
                        (_fakeMax - __rAxis) <= steps.to) ==
                    false))) {
          validMove = false;
        }
      }
    }

    if (validMove &&
            __axisPosTmp - (_touchSize) <= __rightHandlerPosition + 1 &&
            __axisPosTmp + _handlersPadding >=
                _handlersPadding - 1 /* - _leftPadding*/
        ) {
      double tmpLowerValue = __rAxis;

      if (tmpLowerValue > _fakeMax) tmpLowerValue = _fakeMax;
      if (tmpLowerValue < _fakeMin) tmpLowerValue = _fakeMin;

      if (tmpLowerValue > _upperValue) tmpLowerValue = _upperValue;

      if (widget.jump == true) {
        double des =
            ((__containerSizeWithoutHandlerSize / _fakeMax) * tmpLowerValue) -
                (_touchSize);

        if (__middle <=
                des +
                    ((__handlerSize > _touchSize)
                        ? __handlerSize
                        : _touchSize) &&
            (__middle >=
                des -
                    ((__handlerSize > _touchSize)
                        ? __handlerSize
                        : _touchSize))) {
          _lowerValue = tmpLowerValue;
          __leftHandlerPosition = des;

          _updateLowerValue(tmpLowerValue);
        }
//        else if (__dragStartPoint < __dAxis) {
//
//          _lowerValue = tmpLowerValue;
//          __leftHandlerPosition = des;
//
//          _updateLowerValue(tmpLowerValue);
//        }
      } else {
        _lowerValue = tmpLowerValue;
        __leftHandlerPosition = __dAxis - __axisDragTmp;
        _updateLowerValue(tmpLowerValue);
      }
    }

    if (widget.axis == Axis.horizontal) {
      _leftHandlerXPosition = __leftHandlerPosition;
    } else {
      _leftHandlerYPosition = __leftHandlerPosition;
    }

    setState(() {});

    _callbacks('onDragging', 0);
  }

  void _updateLowerValue(value) {
    _outputLowerValue = _displayRealValue(value);
    if (widget.rtl == true) {
      _outputLowerValue = _displayRealValue(_fakeMax - value);
    }
  }

  void _rightHandlerMove(PointerEvent pointer,
      [double tappedPositionWithPadding = 0]) {
    if (widget.disabled ||
        (widget.rightHandler != null && widget.rightHandler.disabled)) return;

    bool validMove = true;

    if (widget.axis == Axis.horizontal) {
      __dAxis =
          pointer.position.dx - tappedPositionWithPadding - _containerLeft;
      __axisDragTmp = xDragTmp;
      __containerSizeWithoutPadding = _containerWidthWithoutPadding;
      __rightHandlerPosition = _rightHandlerXPosition;
      __leftHandlerPosition = _leftHandlerXPosition;
      __containerSizeWithoutHandlerSize = _constraintMaxWidth - _handlersWidth;
      __containerSizeWithoutHalfPadding =
          _constraintMaxWidth - _handlersPadding + 1;
      __middle = __dAxis + ((_touchSize + _handlersWidth) / 2) - __axisDragTmp;
      __handlerSize = _handlersWidth;
    } else {
      __dAxis = pointer.position.dy - tappedPositionWithPadding - _containerTop;
      __axisDragTmp = yDragTmp;
      __containerSizeWithoutPadding = _containerHeightWithoutPadding;
      __rightHandlerPosition = _rightHandlerYPosition;
      __leftHandlerPosition = _leftHandlerYPosition;
      __containerSizeWithoutHandlerSize =
          _constraintMaxHeight - _handlersHeight;
      __containerSizeWithoutHalfPadding =
          _constraintMaxHeight - _handlersPadding + 1;
      __middle = __dAxis + ((_touchSize + _handlersHeight) / 2) - __axisDragTmp;
      __handlerSize = _handlersHeight;
    }

    __axisPosTmp = __dAxis - __axisDragTmp + (_touchSize);

    __rAxis = ((__axisPosTmp / (__containerSizeWithoutPadding / _divisions)) *
        widget.step);
    __rAxis = (double.parse(__rAxis.toStringAsFixed(_decimalScale)) -
        double.parse((__rAxis % widget.step).toStringAsFixed(_decimalScale)));

    if (widget.rangeSlider &&
        widget.minimumDistance > 0 &&
        (__rAxis - widget.minimumDistance) <= _lowerValue) {
      _upperValue = (_lowerValue + widget.minimumDistance < _fakeMax)
          ? _lowerValue + widget.minimumDistance
          : _fakeMax;
      validMove = false;
      _updateUpperValue(_upperValue);
    }
    if (widget.rangeSlider &&
        widget.maximumDistance > 0 &&
        __rAxis >= (_lowerValue + widget.maximumDistance)) {
      _upperValue = (_lowerValue + widget.maximumDistance < _fakeMax)
          ? _lowerValue + widget.maximumDistance
          : _fakeMax;
      validMove = false;
      _updateUpperValue(_upperValue);
    }

    if (widget.ignoreSteps.length > 0) {
      for (FlutterSliderIgnoreSteps steps in widget.ignoreSteps) {
        if (!((widget.rtl == false &&
                (__rAxis >= steps.from && __rAxis <= steps.to) == false) ||
            (widget.rtl == true &&
                ((_fakeMax - __rAxis) >= steps.from &&
                        (_fakeMax - __rAxis) <= steps.to) ==
                    false))) {
          validMove = false;
        }
      }
    }

    if (validMove &&
        __axisPosTmp >= __leftHandlerPosition - 1 + (_touchSize) &&
        __axisPosTmp + _handlersPadding <= __containerSizeWithoutHalfPadding) {
      double tmpUpperValue = __rAxis;

      if (tmpUpperValue > _fakeMax) tmpUpperValue = _fakeMax;
      if (tmpUpperValue < _fakeMin) tmpUpperValue = _fakeMin;

      if (tmpUpperValue < _lowerValue) tmpUpperValue = _lowerValue;

      if (widget.jump == true) {
        double des =
            ((__containerSizeWithoutHandlerSize / _fakeMax) * tmpUpperValue) -
                (_touchSize);

        // drag from right to left
        if (__middle <=
                des +
                    ((__handlerSize > _touchSize)
                        ? __handlerSize
                        : _touchSize) &&
            (__middle >=
                des -
                    ((__handlerSize > _touchSize)
                        ? __handlerSize
                        : _touchSize))) {
          _upperValue = tmpUpperValue;
          __rightHandlerPosition = des;

          _updateUpperValue(tmpUpperValue);
        }

/*        else if (__dragStartPoint < __dAxis) {

          _upperValue = tmpUpperValue;
          __rightHandlerPosition = des;

          _updateUpperValue(tmpUpperValue);
        }*/
      } else {
        _upperValue = tmpUpperValue;

        __rightHandlerPosition = __dAxis - __axisDragTmp; // - (_touchSize);

        _updateUpperValue(tmpUpperValue);
      }
    }

    if (widget.axis == Axis.horizontal) {
      _rightHandlerXPosition = __rightHandlerPosition;
    } else {
      _rightHandlerYPosition = __rightHandlerPosition;
    }

    setState(() {});

    _callbacks('onDragging', 1);
  }

  void _updateUpperValue(value) {
    _outputUpperValue = _displayRealValue(value);
    if (widget.rtl == true) {
      _outputUpperValue = _displayRealValue(_fakeMax - value);
    }
  }

  Positioned _leftHandlerWidget() {
    if (widget.rangeSlider == false)
      return Positioned(
        child: Container(),
      );

    double bottom;
    double right;
    if (widget.axis == Axis.horizontal) {
      bottom = 0;
    } else {
      right = 0;
    }

    return Positioned(
      key: Key('leftHandler'),
      left: _leftHandlerXPosition,
      top: _leftHandlerYPosition,
      bottom: bottom,
      right: right,
      child: Listener(
        child: Draggable(
            axis: widget.axis,
            child: Stack(
              overflow: Overflow.visible,
              children: <Widget>[
                _tooltip(
                    side: 'left',
                    value: _outputLowerValue,
                    opacity: _leftTooltipOpacity,
                    animation: _leftTooltipAnimation),
                leftHandler,
              ],
            ),
            feedback: Container()),
        onPointerMove: (_) {
          _leftHandlerMove(_);
        },
        onPointerDown: (_) {
          if (widget.disabled ||
              (widget.handler != null && widget.handler.disabled)) return;

          _renderBoxInitialization();

          xDragTmp = (_.position.dx - _containerLeft - _leftHandlerXPosition);
          yDragTmp = (_.position.dy - _containerTop - _leftHandlerYPosition);

          if (!_tooltipData.disabled &&
              _tooltipData.alwaysShowTooltip == false) {
            _leftTooltipOpacity = 1;
            _leftTooltipAnimationController.forward();
          }

          _leftHandlerScaleAnimationController.forward();

          setState(() {});

          _callbacks('onDragStarted', 0);
        },
        onPointerUp: (_) {
          if (widget.disabled ||
              (widget.handler != null && widget.handler.disabled)) return;

          _arrangeHandlersZIndex();

          _stopHandlerAnimation(
              animation: _leftHandlerScaleAnimation,
              controller: _leftHandlerScaleAnimationController);

          if (_tooltipData.alwaysShowTooltip == false) {
            _leftTooltipOpacity = 0;
            _leftTooltipAnimationController.reset();
          }

          setState(() {});

          _callbacks('onDragCompleted', 0);
        },
      ),
    );
  }

  Positioned _rightHandlerWidget() {
    double bottom;
    double right;
    if (widget.axis == Axis.horizontal) {
      bottom = 0;
    } else {
      right = 0;
    }

    return Positioned(
      key: Key('rightHandler'),
      left: _rightHandlerXPosition,
      top: _rightHandlerYPosition,
      right: right,
      bottom: bottom,
      child: Listener(
        child: Draggable(
            axis: Axis.horizontal,
            child: Stack(
              overflow: Overflow.visible,
              children: <Widget>[
                _tooltip(
                    side: 'right',
                    value: _outputUpperValue,
                    opacity: _rightTooltipOpacity,
                    animation: _rightTooltipAnimation),
                rightHandler,
              ],
            ),
            feedback: Container(
//                            width: 20,
//                            height: 20,
//                            color: Colors.blue.withOpacity(0.7),
                )),
        onPointerMove: (_) {
          _rightHandlerMove(_);
        },
        onPointerDown: (_) {
          if (widget.disabled ||
              (widget.rightHandler != null && widget.rightHandler.disabled))
            return;

          _renderBoxInitialization();

          xDragTmp = (_.position.dx - _containerLeft - _rightHandlerXPosition);
          yDragTmp = (_.position.dy - _containerTop - _rightHandlerYPosition);

          if (!_tooltipData.disabled &&
              _tooltipData.alwaysShowTooltip == false) {
            _rightTooltipOpacity = 1;
            _rightTooltipAnimationController.forward();
            setState(() {});
          }
          if (widget.rangeSlider == false)
            _leftHandlerScaleAnimationController.forward();
          else
            _rightHandlerScaleAnimationController.forward();

          _callbacks('onDragStarted', 1);
        },
        onPointerUp: (_) {
          if (widget.disabled ||
              (widget.rightHandler != null && widget.rightHandler.disabled))
            return;

          _arrangeHandlersZIndex();

          if (widget.rangeSlider == false) {
            _stopHandlerAnimation(
                animation: _leftHandlerScaleAnimation,
                controller: _leftHandlerScaleAnimationController);
          } else {
            _stopHandlerAnimation(
                animation: _rightHandlerScaleAnimation,
                controller: _rightHandlerScaleAnimationController);
          }

          if (_tooltipData.alwaysShowTooltip == false) {
            _rightTooltipOpacity = 0;
            _rightTooltipAnimationController.reset();
          }

          setState(() {});

          _callbacks('onDragCompleted', 1);
        },
      ),
    );
  }

  void _stopHandlerAnimation(
      {Animation animation, AnimationController controller}) {
    if (widget.handlerAnimation.reverseCurve != null) {
      if (animation.isCompleted)
        controller.reverse();
      else {
        controller.reset();
      }
    } else
      controller.reset();
  }

  drawHandlers() {
    List<Positioned> items = [
      Function.apply(_inactiveTrack, []),
      Function.apply(_activeTrack, []),
      Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Opacity(
            opacity: 0,
            child: Listener(
              onPointerDown: (_) {
                if (widget.selectByTap) {
                  double distanceFromLeftHandler,
                      distanceFromRightHandler,
                      tappedPositionWithPadding;

                  if (widget.axis == Axis.horizontal) {
                    tappedPositionWithPadding =
                        _handlersPadding + (_touchSize) - xDragTmp;
                    distanceFromLeftHandler = ((_leftHandlerXPosition +
                                _handlersPadding +
                                (_touchSize)) +
                            _containerLeft -
                            _.position.dx)
                        .abs();
                    distanceFromRightHandler = ((_rightHandlerXPosition +
                                _handlersPadding +
                                (_touchSize)) +
                            _containerLeft -
                            _.position.dx)
                        .abs();
                  } else {
                    tappedPositionWithPadding =
                        _handlersPadding + (_touchSize) - yDragTmp;
                    distanceFromLeftHandler = ((_leftHandlerYPosition +
                                _handlersPadding +
                                (_touchSize)) +
                            _containerTop -
                            _.position.dy)
                        .abs();
                    distanceFromRightHandler = ((_rightHandlerYPosition +
                                _handlersPadding +
                                (_touchSize)) +
                            _containerTop -
                            _.position.dy)
                        .abs();
                  }

                  if (distanceFromLeftHandler < distanceFromRightHandler) {
                    if (!widget.rangeSlider) {
                      _rightHandlerMove(_, tappedPositionWithPadding);
                    } else {
                      _leftHandlerMove(_, tappedPositionWithPadding);
                    }
                  } else
                    _rightHandlerMove(_, tappedPositionWithPadding);
                }
              },
              child: Container(
              ),
            ),
          )),
    ];

    for (Function func in _positionedItems) {
      items.add(Function.apply(func, []));
    }

    return items;
  }

  Positioned _tooltip(
      {String side, double value, double opacity, Animation animation}) {
    if (_tooltipData.disabled)
      return Positioned(
        child: Container(),
      );

    Widget prefix;
    Widget suffix;

    if (side == 'left') {
      prefix = _tooltipData.leftPrefix;
      suffix = _tooltipData.leftSuffix;
      if (widget.rangeSlider == false)
        return Positioned(
          child: Container(),
        );
    } else {
      prefix = _tooltipData.rightPrefix;
      suffix = _tooltipData.rightSuffix;
    }
    String numberFormat = value.toString();
    if (_tooltipData.numberFormat != null)
      numberFormat = _tooltipData.numberFormat.format(value);

    Widget tooltipWidget = IgnorePointer(
        child: Center(
      child: Container(
        alignment: Alignment.center,
        child: Container(
            padding: EdgeInsets.all(8),
            decoration: _tooltipData.boxStyle.decoration,
            foregroundDecoration: _tooltipData.boxStyle.foregroundDecoration,
            transform: _tooltipData.boxStyle.transform,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                prefix,
                Text(numberFormat, style: _tooltipData.textStyle),
                suffix,
              ],
            )),
      ),
    ));

    double top = -(_containerHeight - _handlersHeight);
    if (widget.axis == Axis.vertical) top = -_handlersHeight + 10;

    if (_tooltipData.alwaysShowTooltip == false) {
      top = 0;
      tooltipWidget =
          SlideTransition(position: animation, child: tooltipWidget);
    }

    return Positioned(
      left: -50,
      right: -50,
      top: top,
      child: Opacity(
        opacity: opacity,
        child: tooltipWidget,
      ),
    );
  }

  Positioned _inactiveTrack() {
    Color trackBarColor = widget.trackBar.inactiveTrackBarColor;
    if (widget.disabled)
      trackBarColor = widget.trackBar.inactiveDisabledTrackBarColor;

    double top, bottom, left, right, width, height;
    top = left = right = width = height = 0;
    right = bottom = null;

    if (widget.axis == Axis.horizontal) {
      bottom = 0;
      left = _handlersPadding;
      width = _containerWidthWithoutPadding;
      height = widget.trackBar.inactiveTrackBarHeight;
    } else {
      right = 0;
      height = _containerHeightWithoutPadding;
      top = _handlersPadding;
      width = widget.trackBar.inactiveTrackBarHeight;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Center(
        child: Container(
          height: height,
          width: width,
          color: trackBarColor,
        ),
      ),
    );
  }

  Positioned _activeTrack() {
    Color trackBarColor = widget.trackBar.activeTrackBarColor;
    if (widget.disabled)
      trackBarColor = widget.trackBar.activeDisabledTrackBarColor;

    double top, bottom, left, right, width, height;
    top = left = width = height = 0;
    right = bottom = null;

    if (widget.axis == Axis.horizontal) {
      bottom = 0;
      height = widget.trackBar.activeTrackBarHeight;
      width = _rightHandlerXPosition - _leftHandlerXPosition;
      left = _leftHandlerXPosition + _handlersWidth / 2 + (_touchSize);
      if (widget.rtl == true && widget.rangeSlider == false) {
        left = _rightHandlerXPosition + (_touchSize);
        width = _constraintMaxWidth -
            _rightHandlerXPosition -
            _handlersWidth / 2 -
            (_touchSize);
      }
    } else {
      right = 0;
      width = widget.trackBar.activeTrackBarHeight;
      height = _rightHandlerYPosition - _leftHandlerYPosition;
      top = _leftHandlerYPosition + _handlersHeight / 2 + (_touchSize);
      if (widget.rtl == true && widget.rangeSlider == false) {
        top = _rightHandlerYPosition + (_touchSize);
        height = _constraintMaxHeight -
            _rightHandlerYPosition -
            _handlersHeight / 2 -
            (_touchSize);
      }
    }

    width = (width < 0) ? 0 : width;
    height = (height < 0) ? 0 : height;

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Center(
        child: Container(
          height: height,
          width: width,
          color: trackBarColor,
        ),
      ),
    );
  }

  void _callbacks(String callbackName, int handlerIndex) {
    double lowerValue = _outputLowerValue;
    double upperValue = _outputUpperValue;
    if (widget.rtl == true || widget.rangeSlider == false) {
      lowerValue = _outputUpperValue;
      upperValue = _outputLowerValue;
    }

    switch (callbackName) {
      case 'onDragging':
        if (widget.onDragging != null)
          widget.onDragging(handlerIndex, lowerValue, upperValue);
        break;
      case 'onDragCompleted':
        if (widget.onDragCompleted != null)
          widget.onDragCompleted(handlerIndex, lowerValue, upperValue);
        break;
      case 'onDragStarted':
        if (widget.onDragStarted != null)
          widget.onDragStarted(handlerIndex, lowerValue, upperValue);
        break;
    }
  }

  double _displayRealValue(double value) {
    return double.parse((value + widget.min).toStringAsFixed(_decimalScale));
  }

  void _arrangeHandlersZIndex() {
    if (_lowerValue >= (_fakeMax / 2))
      _positionedItems = [
        _rightHandlerWidget,
        _leftHandlerWidget,
      ];
    else
      _positionedItems = [
        _leftHandlerWidget,
        _rightHandlerWidget,
      ];
  }

  void _renderBoxInitialization() {
    if (_containerLeft <= 0 ||
        (MediaQuery.of(context).size.width - _constraintMaxWidth) <=
            _containerLeft) {
      RenderBox containerRenderBox =
          containerKey.currentContext.findRenderObject();
      _containerLeft = containerRenderBox.localToGlobal(Offset.zero).dx;
    }
    if (_containerTop <= 0 ||
        (MediaQuery.of(context).size.height - _constraintMaxHeight) <=
            _containerTop) {
      RenderBox containerRenderBox =
          containerKey.currentContext.findRenderObject();
      _containerTop = containerRenderBox.localToGlobal(Offset.zero).dy;
    }
  }
}

class _MakeHandler extends StatelessWidget {
  final double width;
  final double height;
  final GlobalKey id;
  final FlutterSliderHandler handlerData;
  final bool visibleTouchArea;
  final Animation animation;
  final Axis axis;

  _MakeHandler(
      {this.id,
      this.handlerData,
      this.visibleTouchArea,
      this.width,
      this.height,
      this.animation,
      this.axis});

  @override
  Widget build(BuildContext context) {
    double touchOpacity = (visibleTouchArea == true) ? 1 : 0;

    double localWidth, localHeight;
    if (axis == Axis.vertical) localHeight = height + (_touchSize * 2);

    if (axis == Axis.horizontal) localWidth = width + (_touchSize * 2);

    return Container(
      key: id,
      width: localWidth,
      height: localHeight,
      child: Stack(children: <Widget>[
        Opacity(
          opacity: touchOpacity,
          child: Container(
            color: Colors.black12,
            child: Container(),
          ),
        ),
        Center(
          child: ScaleTransition(
            scale: animation,
            child: handlerData.child ??
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        spreadRadius: 0.2,
                        offset: Offset(0, 1))
                  ], color: Colors.white, shape: BoxShape.circle),
                  width: width,
                  height: height,
                  child: handlerData.icon,
                ),
          ),
        )
      ]),
    );
  }
}

class FlutterSliderHandler {
  final Widget child;
  final Icon icon;
  final bool disabled;

  FlutterSliderHandler({this.child, this.icon, this.disabled = false})
      : assert(disabled != null);

  @override
  String toString() {
    return child.toString() + icon.toString();
  }
}

class FlutterSliderTooltip {
  TextStyle textStyle;
  FlutterSliderTooltipBox boxStyle;
  Widget leftPrefix;
  Widget leftSuffix;
  Widget rightPrefix;
  Widget rightSuffix;
  intl.NumberFormat numberFormat;
  bool alwaysShowTooltip;
  bool disabled;

  FlutterSliderTooltip(
      {this.textStyle,
      this.boxStyle,
      this.leftPrefix,
      this.leftSuffix,
      this.rightPrefix,
      this.rightSuffix,
      this.numberFormat,
      this.alwaysShowTooltip,
      this.disabled});

  @override
  String toString() {
    return textStyle.toString() +
        boxStyle.toString() +
        leftPrefix.toString() +
        leftSuffix.toString() +
        rightPrefix.toString() +
        rightSuffix.toString() +
        numberFormat.toString() +
        alwaysShowTooltip.toString() +
        disabled.toString();
  }
}

class FlutterSliderTooltipBox {
  final BoxDecoration decoration;
  final BoxDecoration foregroundDecoration;
  final Matrix4 transform;

  const FlutterSliderTooltipBox(
      {this.decoration, this.foregroundDecoration, this.transform});

  @override
  String toString() {
    return decoration.toString() +
        foregroundDecoration.toString() +
        transform.toString();
  }
}

class FlutterSliderTrackBar {
  final Color activeTrackBarColor;
  final Color activeDisabledTrackBarColor;
  final Color inactiveTrackBarColor;
  final Color inactiveDisabledTrackBarColor;
  final double activeTrackBarHeight;
  final double inactiveTrackBarHeight;

  const FlutterSliderTrackBar({
    this.inactiveTrackBarColor = const Color(0x110000ff),
    this.activeTrackBarColor = const Color(0xff2196F3),
    this.activeDisabledTrackBarColor = const Color(0xffb5b5b5),
    this.inactiveDisabledTrackBarColor = const Color(0xffe5e5e5),
    this.activeTrackBarHeight = 3.5,
    this.inactiveTrackBarHeight = 3,
  })  : assert(activeTrackBarHeight != null &&
            activeTrackBarHeight > 0 &&
            inactiveTrackBarHeight != null &&
            inactiveTrackBarHeight > 0 &&
            activeTrackBarHeight >= inactiveTrackBarHeight),
        assert(inactiveTrackBarColor != null && activeTrackBarColor != null),
        assert(activeDisabledTrackBarColor != null &&
            inactiveDisabledTrackBarColor != null);
}

class FlutterSliderIgnoreSteps {
  final double from;
  final double to;

  FlutterSliderIgnoreSteps({this.from, this.to})
      : assert(from != null && to != null && from <= to);
}

class FlutterSliderHandlerAnimation {
  final Curve curve;
  final Curve reverseCurve;
  final Duration duration;
  final double scale;

  const FlutterSliderHandlerAnimation(
      {this.curve = Curves.elasticOut,
      this.reverseCurve,
      this.duration = const Duration(milliseconds: 700),
      this.scale = 1.3})
      : assert(curve != null && duration != null && scale != null);
}
