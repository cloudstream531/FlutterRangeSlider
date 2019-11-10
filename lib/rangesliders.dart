import 'package:flutter/material.dart';
import 'flutter_xlider.dart';
import 'package:intl/intl.dart' as intl;

class Range_Slider extends StatefulWidget {
  @override
  _Range_SliderState createState() => _Range_SliderState();
}

class _Range_SliderState extends State<Range_Slider> {
  double _lowerValue = 50;
  double _upperValue = 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Center(child:
      new SingleChildScrollView(
          child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 50, left: 50, right: 50),
            alignment: Alignment.centerLeft,
            child: FlutterSlider(
              values: [60, 160],
              max: 200,
              min: 50,
              maximumDistance: 300,
              rangeSlider: true,
              rtl: true,
              handlerAnimation: FlutterSliderHandlerAnimation(
                  curve: Curves.elasticOut,
                  reverseCurve: null,
                  duration: Duration(milliseconds: 700),
                  scale: 1.4),
              onDragging: (handlerIndex, lowerValue, upperValue) {
                _lowerValue = lowerValue;
                _upperValue = upperValue;
                setState(() {});
              },
            ),
          ),
          Container(
              margin: EdgeInsets.only(top: 20, left: 20, right: 20),
              alignment: Alignment.centerLeft,
              child: FlutterSlider(
                values: [1000, 15000],
                rangeSlider: true,
                ignoreSteps: [
                  FlutterSliderIgnoreSteps(from: 8000, to: 12000),
                  FlutterSliderIgnoreSteps(from: 18000, to: 22000),
                ],
                max: 25000,
                min: 0,
                step: 100,

                jump: true,

                trackBar: FlutterSliderTrackBar(
                  activeTrackBarColor: Colors.redAccent,
                  activeTrackBarHeight: 5,
                ),
                tooltip: FlutterSliderTooltip(
                  textStyle: TextStyle(fontSize: 17, color: Colors.lightBlue),
                  numberFormat: intl.NumberFormat(),
                ),
                handler: FlutterSliderHandler(
                  child: Material(
                    type: MaterialType.canvas,
                    color: Colors.orange,
                    elevation: 3,
                    child: Container(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.adjust,
                          size: 25,
                        )),
                  ),
                ),
                rightHandler: FlutterSliderHandler(
                  icon: Icon(
                    Icons.chevron_left,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                disabled: false,

                onDragging: (handlerIndex, lowerValue, upperValue) {
                  _lowerValue = lowerValue;
                  _upperValue = upperValue;
                  setState(() {});
                },
              )),
          Container(
              margin: EdgeInsets.only(top: 20, left: 20, right: 20),
              alignment: Alignment.centerLeft,
              child: FlutterSlider(
                values: [3000, 17000],
                rangeSlider: true,
//rtl: true,
//                touchZone: 2,
//                ignoreSteps: [
//                  FlutterSliderIgnoreSteps(from: 8000, to: 12000),
//                  FlutterSliderIgnoreSteps(from: 18000, to: 22000),
//                ],
                max: 25000,
                min: 0,
                step: 100,
//displayTestTouchZone: true,
                jump: true,
                trackBar: FlutterSliderTrackBar(
                  activeTrackBarColor: Colors.blue.withOpacity(0.6),
                  inactiveTrackBarHeight: 2,
                  activeTrackBarHeight: 3,
                ),

                disabled: false,

                handler: customHandler(Icons.chevron_right),
                rightHandler: customHandler(Icons.chevron_left),
                tooltip: FlutterSliderTooltip(
                  numberFormat: intl.NumberFormat(),
                  leftPrefix: Icon(
                    Icons.attach_money,
                    size: 19,
                    color: Colors.black45,
                  ),
                  rightSuffix: Icon(
                    Icons.attach_money,
                    size: 19,
                    color: Colors.black45,
                  ),
                  textStyle: TextStyle(fontSize: 17, color: Colors.black45),
                ),

                onDragging: (handlerIndex, lowerValue, upperValue) {
                  _lowerValue = lowerValue;
                  _upperValue = upperValue;
                  setState(() {});
                },
              )),
          Container(
            margin: EdgeInsets.only(top: 20, left: 20, right: 20),
            alignment: Alignment.centerLeft,
            child: FlutterSlider(
              key: Key('3343'),
              values: [300000000, 1600000000],
              rangeSlider: true,
              tooltip: FlutterSliderTooltip(
                alwaysShowTooltip: true,
                numberFormat: intl.NumberFormat.compact(),
              ),
              max: 2000000000,
              min: 0,
              step: 20,
              jump: true,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                _lowerValue = lowerValue;
                _upperValue = upperValue;
                setState(() {});
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 40, left: 50, right: 50),
            alignment: Alignment.centerLeft,
            child: FlutterSlider(
              values: [30, 60],
              rangeSlider: true,
              max: 100,
              min: 0,
              visibleTouchArea: true,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                _lowerValue = lowerValue;
                _upperValue = upperValue;
                setState(() {});
              },
            ),
          ),
          SizedBox(
            height: 50,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Lower Value: ' + _lowerValue.toString()),
          ),
          SizedBox(height: 25),
          Padding(
            padding: EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 20),
            child: Text('Upper Value: ' + _upperValue.toString()),
          )
        ],
      ))),
    );
  }

  customHandler(IconData icon) {
    return FlutterSliderHandler(
      child: Container(
        child: Container(
          margin: EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
          child: Icon(
            icon,
            color: Colors.white,
            size: 23,
          ),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                spreadRadius: 0.05,
                blurRadius: 5,
                offset: Offset(0, 1))
          ],
        ),
      ),
    );
  }
}
