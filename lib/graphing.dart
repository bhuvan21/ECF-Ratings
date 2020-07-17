//import 'dart:html';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'package:fl_chart/fl_chart.dart';
import 'indicator.dart';

class ChessGraph extends StatefulWidget {
  List<List<Game>> data;
  List<String> names;
  ChessGraph(this.data, this.names);
  List<List<Game>> newdata;

  @override
  _ChessGraphState createState() => _ChessGraphState();
}

class _ChessGraphState extends State<ChessGraph> {
  @override

  DateTime oldest;
  DateTime newest;
  int highest;
  int lowest = 9999999;
  List<DateTime> xAxis = [];
  List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.pink, Colors.deepOrange, Colors.amber, Colors.deepPurple];

  Widget build(BuildContext context) {
    xAxis = [];
    colors = colors + colors + colors + colors;


    List<List<Game>> newData = [];
    for (int i = 0; i < widget.data.length; i++) {

      List<Game> games = widget.data[i];
      newData.add([]);
      for (int j = 0; j < games.length; j++) {
        Game game = games[j];
        if (!((game.increment == 0.0 && game.myGrade == null && game.opponentGrade == null)|| game.increment == null)) {
          newData[i].add(game);
          if (oldest == null) {
            oldest = game.gameDate;
          }
          if (newest == null) {
            newest = game.gameDate;
          }
          if (highest == null) {
            highest = game.myGrade;
          }

          if (game.gameDate.isAfter(newest)) {
            newest = game.gameDate;
          }
          if (game.gameDate.isBefore(oldest)) {
            oldest = game.gameDate;
          }
          if (game.myGrade > highest) {
            highest = game.myGrade;
          }
          if (game.myGrade < lowest) {
            lowest = game.myGrade;
            //print(lowest);
          }
        }
      }
      if (newData.last.length == 0) {
        newData.removeLast();
    }

    }
    widget.data = newData;
    widget.newdata = newData;
    return Padding(
      padding: EdgeInsets.fromLTRB(15, 10, 30, 10),
      child:Column(children: <Widget>[
        LineChart(mainData()),
        buildLegend()
      ],)
    );
  }

  Widget buildLegend() {
    List<Widget> indicators = [];

    for (int i = 0; i <widget.data.length; i++) {
      indicators.add(Padding(
          padding: EdgeInsets.all(2),
          child:Row(children: [
            Container(
              width: 15, height: 15,
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i]),
            ),
            Text("  " + widget.names[i])
          ]))
      );

    }
    List<Row> bigrows = [];
    for (int i = 0; i < (widget.data.length.toDouble()/2.0).round(); i++) {
      List<Padding> rows = [];
      int limit = 2;
      if ((i+1)*2> widget.data.length) {
        limit = 1;
      }
      for (int j = 0; j < limit; j++) {
        int index = (i*2) + j;
        rows.add(Padding(
            padding: EdgeInsets.fromLTRB(20, 2, 20, 2),
            child:Row(children: [
              Container(
                width: 15, height: 15,
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors[index]),
              ),
              Text("  " + widget.names[index])
            ])));
      }
      bigrows.add(Row(children: rows,));
    }

    return Align(child:Container(
        child: Column(
        children: bigrows
    )), alignment: Alignment.topCenter,);
  }

  FlGridData getGridData() {
    return FlGridData(
      show: true,
      // CUSTOM AXIS LINES
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) {

        return FlLine(
          color: const Color(0xff37434d),
          strokeWidth: 1,
        );
      },
      getDrawingVerticalLine: (value) {
        return FlLine(
          color: const Color(0xff37434d),
          strokeWidth: 1,
        );
      },
    );
  }


  FlTitlesData getTitlesData() {
    return FlTitlesData(
      show: true,
      //BOTTOM AXIS TITLING FORMATTING
      bottomTitles: SideTitles(
        showTitles: true,
        reservedSize: 22,
        textStyle:
        const TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16),
        getTitles: (value) {
          DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
          List<String> months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

          if (xAxis.length == 0) {
            xAxis.add(date);
            return months[date.month-1] +" '" + date.year.toString().substring(2, 4);
          }
          //print((xAxis[xAxis.length-1].difference(date).inDays));

          if (xAxis[xAxis.length-1].difference(date).inDays.abs() > 60) {
            xAxis.add(date);
            //print(date.year);

            String displayed = months[date.month-1] +" '" + date.year.toString().substring(2, 4);
            return displayed;
          }

          return "";
        },
        margin: 8,
      ),
      // SIDE TITLING FORMATTING
      leftTitles: SideTitles(
        showTitles: true,
        textStyle: const TextStyle(
          color: Color(0xff67727d),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        getTitles: (value) {

          if (value%100 == 0) {
            return value.toInt().toString();
          }
        },
        reservedSize: 28,
        margin: 12,
      ),
    );
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: getGridData(),
      titlesData: getTitlesData(),
      // MIN MAX AXES
      borderData:
      FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: oldest.millisecondsSinceEpoch.toDouble(),
      maxX: newest.millisecondsSinceEpoch.toDouble(),
      minY: ((max(lowest , 0)/100).floor()*100).toDouble(),
      maxY: ((highest/100).ceil()*100).toDouble(),
      // THE ACTUAL DATA
      lineBarsData: getData(),
    );
  }

  List<LineChartBarData> getData() {
    List<LineChartBarData> data = [];
    for (int i = 0; i < widget.data.length; i++) {
      List<FlSpot> spots = [];
      Game lastGame;
      for (int j = 0; j < widget.data[i].length; j++) {
        Game game = widget.data[i][j];

        if (lastGame == null) {
          lastGame = game;
          spots.add(FlSpot(game.gameDate.millisecondsSinceEpoch.toDouble(), game.myGrade.toDouble()));
        }

        if (game.gameDate.difference(lastGame.gameDate).inDays.abs() > 0) {
          spots.add(FlSpot(game.gameDate.millisecondsSinceEpoch.toDouble(), game.myGrade.toDouble()));
          lastGame = game;
        }
        else {
          //spots.last = FlSpot(game.gameDate.millisecondsSinceEpoch.toDouble(), game.myGrade.toDouble());
        }

      }

      data.add(LineChartBarData(
        colors: [colors[i]],
        spots: spots,
        isCurved: false,
        curveSmoothness: 0.2,
        preventCurveOverShooting: true,
        preventCurveOvershootingThreshold: -50,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
        ),
        belowBarData: BarAreaData(
          show: false,
        ),
      ));
    }

    return data;
  }



}