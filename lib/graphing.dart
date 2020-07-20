import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'player.dart';

// All purpose graphing widget, taking a 2D array of games, and a list of names
// Displays a graph of all players given, with a legend
class ChessGraph extends StatefulWidget {
  List<List<Game>> data;
  List<String> names;
  ChessGraph(this.data, this.names);

  @override
  _ChessGraphState createState() => _ChessGraphState();
}

class _ChessGraphState extends State<ChessGraph> {

  // Stores the oldest/newest games for x Axis cropping, and highest/lowest ratings for Y axis cropping
  DateTime oldest;
  DateTime newest;
  int highest = 0;
  int lowest = 9999999;

  // Used to store xAxis points to correctly space out xAxis labels
  List<DateTime> xAxis = [];

  // List of colors used for different players - these repeat
  List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.pink, Colors.deepOrange, Colors.amber, Colors.deepPurple];

  @override
  Widget build(BuildContext context) {
    // Reset xAxis record
    xAxis = [];
    // Just in case too many peers are added - this is not a good solution
    colors = colors + colors + colors + colors;

    // Iterate through all games, recording highest, lowest, oldest, newest
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
      // Don't graph players who have no games
      if (newData[i].length == 0) {
        newData.removeAt(i);
        widget.names.removeAt(i);
      }
    }
    // Overwrite old data with filtered data
    widget.data = newData;

    // Return a padded linechart and legend
    return Padding(
      padding: EdgeInsets.fromLTRB(15, 0, 30, 0),
      child:Column(children: <Widget>[
        LineChart(mainData()),
        buildLegend()
      ],)
    );
  }

  // Builds and returns the legend widget
  Widget buildLegend() {
    // Creates a legend entry for each player, putting two in a row until there is only one left
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
              decoration:
              BoxDecoration(shape: BoxShape.circle, color: colors[index]),
            ),
            Text("  " + widget.names[index])
          ])
        ));
      }
      bigrows.add(Row(children: rows,));
    }

    // Returns these rows put together in a column
    return Align(child:Container(
        child: Column(
        children: bigrows
    )), alignment: Alignment.topCenter,);
  }

  // Responsible for the grid displayed in the graph
  FlGridData getGridData() {
    return FlGridData(
      show: true,
      // Custom Axes lines
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: const Color(0xff37434d),
          strokeWidth: 1,
        );
      }
    );
  }

  // Responsible for the Axes label markings
  FlTitlesData getTitlesData() {
    return FlTitlesData(
      show: true,

      // X Axis markings
      bottomTitles: SideTitles(
        showTitles: true,
        reservedSize: 22,
        textStyle:
        const TextStyle(color: Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16),
        getTitles: (value) { // This function is called for a bunch of y Axis values, and should return text to be displayed at that y value
          // Get a DateTime from the epoch timestamp
          DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
          List<String> months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

          // If this is the first call of this function, display a label at this point
          if (xAxis.length == 0) {
            xAxis.add(date);
            return months[date.month-1] +" '" + date.year.toString().substring(2, 4);
          }

          // Otherwise, check if it has been 60 days since the last label, and if so, add a new label
          if (xAxis[xAxis.length-1].difference(date).inDays.abs() > 60) {
            xAxis.add(date);
            return months[date.month-1] +" '" + date.year.toString().substring(2, 4);
          }

          // Otherwise there should be no label
          return "";
        },
          margin: 8
      ),

      // Y Axis markings
      leftTitles: SideTitles(
        showTitles: true,
        textStyle: const TextStyle(
          color: Color(0xff67727d),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        getTitles: (value) {
          // Same principle as X axis, but only show labels every 100 points
          if (value%100 == 0) {
            return value.toInt().toString();
          }
          return "";
        },
        reservedSize: 28,
        margin: 12,
      ),
    );
  }

  // Returns the actual data for the graph
  List<LineChartBarData> getData() {
    // Iterates through games, adding spots to "spots" which is used to make LineChartBarData, added to "data"
    List<LineChartBarData> data = [];
    for (int i = 0; i < widget.data.length; i++) {
      List<FlSpot> spots = [];
      Game lastGame;
      for (int j = 0; j < widget.data[i].length; j++) {
        Game game = widget.data[i][j];

        // This ensures that if multiple games took place on the same day, the latest ranking will be used as the data for this day on the graph
        if (lastGame == null) {
          lastGame = game;
          spots.add(FlSpot(game.gameDate.millisecondsSinceEpoch.toDouble(), game.myGrade.toDouble()));
        }

        if (game.gameDate.difference(lastGame.gameDate).inDays.abs() > 0) {
          spots.add(FlSpot(game.gameDate.millisecondsSinceEpoch.toDouble(), game.myGrade.toDouble()));
          lastGame = game;
        }
      }

      // Contains some aesthetics data for each trace
      data.add(LineChartBarData(
        colors: [colors[i]],
        spots: spots,
        isCurved: false,
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

  // Returns the full graph, calling on other helper functions to construct the graph
  LineChartData mainData() {
    return LineChartData(
      gridData: getGridData(),
      titlesData: getTitlesData(),
      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
      // Cropping of the axes, goes from oldest game to newest game
      // And from lowest rating rounded down to nearest 100, and highest round up to nearest 100
      minX: oldest.millisecondsSinceEpoch.toDouble(),
      maxX: newest.millisecondsSinceEpoch.toDouble(),
      minY: ((max(lowest , 0)/100).floor()*100).toDouble(),
      maxY: ((highest/100).ceil()*100).toDouble(),
      lineBarsData: getData(),
    );
  }
}