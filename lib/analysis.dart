import 'package:flutter/material.dart';
import 'player.dart';
import 'graphing.dart';
import 'singleton.dart';
import 'helpers.dart';

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
        return Text("Select your identity");
      }
      else if (myPlayers.length == 1) {
        if (Singleton().peers.length == 0) {
          return Text("You need peers to use analysis, add players as peers by searching for them, and pressing the star button in the top right until it goes green.");
        }
        return Text("You need to select your identity");
      }
      List<List<Game>> standardGames = [];
      List<List<Game>> rapidGames = [];
      List<String> names = [];
      for (int i = 0; i <myPlayers.length; i++) {
        standardGames.add(myPlayers[i].standardGames);
        rapidGames.add(myPlayers[i].rapidGames);
        names.add(myPlayers[i].name);
      }


      ChessGraph standardGraph = ChessGraph(standardGames, names);
      ChessGraph rapidGraph = ChessGraph(rapidGames, names);

      List<Widget> info = [];
      for (int i = 0; i < 2; i++) {
        List<List<Game>> data = [];
        int myIncrease = 0;
        int theirIncrease = 0;

        if (i == 0) {
          data = standardGames;
        }
        else {
          data = rapidGames;
        }

        List<List<Game>> newData = [];
        for (int i = 0; i < data.length; i++) {
          List<Game> games = data[i];
          newData.add([]);
          for (int j = 0; j < games.length; j++) {
            Game game = games[j];
            if (!((game.increment == 0.0 && game.myGrade == null && game.opponentGrade == null)|| game.increment == null)) {
              newData[i].add(game);
            }
          }
        }
        int myGameCount = 0;
        int theirGameCount = 0;
        for (int i = 0; i < newData.length; i ++) {
          if (i == 0) {
            myIncrease = newData[i][0].myGrade - newData[i].last.myGrade;
            myGameCount = newData[i].length;
          }
          else {
            if (newData[i].length != 0) {
              theirIncrease = theirIncrease + newData[i][0].myGrade - newData[i].last.myGrade;
              theirGameCount = theirGameCount + newData[i].length;
            }

          }
        }

        String myAverage = (myIncrease/myGameCount).toStringAsFixed(1);
        String theirAverage = (theirIncrease/theirGameCount).toStringAsFixed(1);

        info.add(Column(

          children: <Widget>[
            ChessGraph(newData, names),

            Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(child: Text("You increased by an average of $myAverage points per game!"), padding: EdgeInsets.fromLTRB(0, 0, 0, 10)),
                  Text("Peers increased by an average of $theirAverage points per game!")
                ],
              )


          ],
        ));
      }
      pages = [];
      pages.add(info[0]);
      pages.add(info[1]);



      return SizedBox.expand(
        child: Padding(
            padding: EdgeInsets.fromLTRB(5, 40, 5, 40),
            child :Container(
              child: PageView.builder(itemBuilder: (context, position) => pages[position], itemCount: pages.length,),
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
          Player error = Player.empty();
          error.error = 1;
          workingPlayers.add(error);
          return workingPlayers;
        }
      }
      else {
        refID = int.tryParse(Singleton().peers[i-1].split("|")[1]);
      }
      Player player = await getPlayer(refID);
      workingPlayers.add(player);
    }
    //print(workingPlayers.length);
    return workingPlayers;
  }




}