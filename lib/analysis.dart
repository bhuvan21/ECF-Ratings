import 'package:flutter/material.dart';
import 'player.dart';
import 'graphing.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'singleton.dart';

class Analysis extends StatefulWidget {

  @override
  _AnalysisState createState() => _AnalysisState();
}

class _AnalysisState extends State<Analysis> {

  bool loading = true;
  List<Player> myPlayers = [];
  final pageController = PageController(initialPage: 0);
  List<Widget> pages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Analysis"),), body: buildBody(),);
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      loading = true;
      getAllInfo().then((players){
        myPlayers = players;
        setState((){ loading = false; });
      });
    });
  }

  Widget buildBody() {
    if (loading) {
      return Center(child:CircularProgressIndicator());
    }
    else {
      if (myPlayers.length == 0) {
        return Text("Select urself");
      }
      List<List<Game>> standardGames = [];
      List<List<Game>> rapidGames = [];
      List<String> names = [];
      for (int i = 0; i <myPlayers.length; i++) {
        standardGames.add(myPlayers[i].standardGames);
        rapidGames.add(myPlayers[i].rapidGames);
        names.add(myPlayers[i].name);
      }
      pages.add(ChessGraph(standardGames, names));
      pages.add(ChessGraph(rapidGames, names));
      print(standardGames.length);
      return SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.fromLTRB(5, 40, 5, 40),
          child :Container(
            child: PageView.builder(itemBuilder: (context, position) => pages[position]),
          )
        ),
      );
    }
  }

  Future<List<Player>> getAllInfo() async {

    List<Player> workingPlayers = [];

    for (int i = 0; i < Singleton().peers.length+1; i++) {
      int refID;
      if (i == 0){
        refID = Singleton().myID;
        if (refID == 0){
          Player error =Player.empty();
          error.error = 1;
          workingPlayers.add(error);
          return workingPlayers;
        }
        Player player = await getPlayer(refID);
        workingPlayers.add(player);
      }
      else {

        String temp = Singleton().peers[i-1].split("|")[1];
        if (int.tryParse(temp) == null) {
          refID = int.tryParse(temp.substring(0, (temp.length-1 )));
        }
        else {
          refID = int.tryParse(temp);
        }
        Player player = await getPlayer(refID);
        workingPlayers.add(player);
      }
    }
    //print(workingPlayers.length);
    return workingPlayers;
  }

  Future<Player> getPlayer(int refID) async {
    Player workingPlayer = Player.empty();
    if (refID == 0) {
      return Player.empty();
    }

    print(refID);
    final mainResponse = await http.get('https://www.ecfgrading.org.uk/sandbox/new/api.php?v2/players/code/'+refID.toString());

    if (mainResponse.statusCode == 200) {
      var json = jsonDecode(mainResponse.body);

      workingPlayer = Player.fromJson(json);
    }

    else {
      workingPlayer = Player.empty();
      workingPlayer.error = 2;
      return workingPlayer;
    }

    if (workingPlayer.error == 0) {
      final game1Response = await http.get('https://www.ecfgrading.org.uk/sandbox/new/api.php?v2/games/Standard/player/$refID/limit/100');

      if (game1Response.statusCode == 200) {
        var json = jsonDecode(game1Response.body);
        List games = json["games"];
        List<Game> gameObjects = [];
        for (int i = 0; i < games.length; i++) {
          Game game = Game.fromJson(games[i]);
          game.gameType = "S";
          gameObjects.add(game);
        }
        workingPlayer.standardGames = gameObjects;
      }

      else {
        workingPlayer = Player.empty();
        workingPlayer.error = 2;
        return workingPlayer;
      }
    }

    if (workingPlayer.error == 0) {
      final game2Response = await http.get('https://www.ecfgrading.org.uk/sandbox/new/api.php?v2/games/Rapid/player/$refID/limit/100');

      if (game2Response.statusCode == 200) {
        var json = jsonDecode(game2Response.body);
        List games = json["games"];
        List<Game> gameObjects = [];
        for (int i = 0; i < games.length; i++) {
          Game game = Game.fromJson(games[i]);
          game.gameType = "R";
          gameObjects.add(game);
        }
        workingPlayer.rapidGames = gameObjects;
      }

      else {
        workingPlayer = Player.empty();
        workingPlayer.error = 2;
        return workingPlayer;
      }
    }
    return workingPlayer;
  }


}