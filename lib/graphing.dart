import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'player.dart';
import 'package:fl_chart/fl_chart.dart';

class ChessGraph extends StatefulWidget {
  List<List<Game>> data;
  ChessGraph(this.data);

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

  Widget build(BuildContext context) {
    xAxis = [];


    List<List<Game>> newData = [];
    for (int i = 0; i <widget.data.length; i++) {
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
          }
        }
      }
      widget.data = newData;
    }





    return Padding(child:LineChart(mainData()), padding: EdgeInsets.fromLTRB(15, 0, 30, 0),);
  }

  FlGridData getGridData() {
    return FlGridData(
      show: true,
      // CUSTOM AXIS LINES
      drawVerticalLine: true,
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
          print(value);
          if (value%200 == 0) {
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
      minY: ((max(lowest - 300, 0)/100).round()*100).toDouble(),
      maxY: highest*1.2,
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
        print(lastGame.gameDate);
        if (game.gameDate.difference(lastGame.gameDate).inDays.abs() > 0) {
          spots.add(FlSpot(game.gameDate.millisecondsSinceEpoch.toDouble(), game.myGrade.toDouble()));
          lastGame = game;
        }
        else {
          //spots.last = FlSpot(game.gameDate.millisecondsSinceEpoch.toDouble(), game.myGrade.toDouble());
        }

      }
      print(spots);
      data.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.2,
        preventCurveOverShooting: true,
        preventCurveOvershootingThreshold: -50,
        barWidth: 5,
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