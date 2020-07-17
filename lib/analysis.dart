import 'package:flutter/material.dart';

import 'player.dart';
import 'graphing.dart';
import 'singleton.dart';
import 'helpers.dart';

// The Analysis widget handles the analysis tab of the app
// It contains a main graph putting you against your peers as well as a few stats below
// This is replicated (for standard and rapid) and placed in a page view
class Analysis extends StatefulWidget {
  @override
  _AnalysisState createState() => _AnalysisState();
}

class _AnalysisState extends State<Analysis> {

  // Used to track whether data has been fetched from server yet
  bool loading = true;

  // List of players who are relevant for analysis - myself + peers
  List<Player> myPlayers = [];

  // Widgets kept in page view, and the relevant controller
  List<Widget> pages = [];
  final pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analysis"),),
      body: buildBody(),);
  }

  // Run once at widget initialisation
  @override
  void initState() {
    super.initState();
    // Load data from server, store this data in myPlayers, and reload the widget states with loading now complete
    setState(() {
      loading = true;
      getAllInfo().then((players){
        myPlayers = players;
        setState((){ loading = false; });
      });
    });
  }

  // Returns the main body of the analysis page. This can be a loading indicator when necessary, or the actual page info
  Widget buildBody() {
    if (loading) {
      return Center(child:CircularProgressIndicator());
    }
    else {
      // User hasn't selected their own identity
      if (myPlayers.length == 0) {
        return Text("Select your identity");
      }
      // User has either selected a peer and not themselves, or just themselves and no peers
      else if (myPlayers.length == 1) {
        if (Singleton().peers.length == 0) {
          return Text("You need peers to use analysis, add players as peers by searching for them, and pressing the star button in the top right until it goes green.");
        }
        return Text("You need to select your identity");
      }

      // 2DArrays for standard and rapid games. Subarrays represent players, which contain their games
      List<List<Game>> standardGames = [];
      List<List<Game>> rapidGames = [];
      // List of player names for the legend
      List<String> names = [];

      // Populate these arrays
      for (int i = 0; i <myPlayers.length; i++) {
        standardGames.add(myPlayers[i].standardGames);
        rapidGames.add(myPlayers[i].rapidGames);
        names.add(myPlayers[i].name);
      }

      // Filter all game data, to get rid of games with incomplete data - these should not be graphed
      // Info will contain the relevant standard and rapid widgets for later use
      List<Widget> info = [];
      for (int i = 0; i < 2; i++) {
        // Used to store the unfiltered data
        List<List<Game>> data = [];
        if (i == 0) {
          data = standardGames;
        }
        else {
          data = rapidGames;
        }

        // Used to store the filtered data
        List<List<Game>> newData = [];
        for (int i = 0; i < data.length; i++) {
          List<Game> games = data[i];
          newData.add([]);
          for (int j = 0; j < games.length; j++) {
            Game game = games[j];
            // Criteria for a bad game is if ranking information is malformed, or there is no increment given
            if (!((game.increment == 0.0 && game.myGrade == null && game.opponentGrade == null)|| game.increment == null)) {
              newData[i].add(game);
            }
          }
        }

        // Re iterate through filtered data, counting up games and increase/decreases
        int myIncrease = 0;
        int theirIncrease = 0;
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

        // Calculate average improvements per game for the user and everyone else - round to 1dp
        String myAverage = (myIncrease/myGameCount).toStringAsFixed(1);
        String theirAverage = (theirIncrease/theirGameCount).toStringAsFixed(1);

        info.add(Column(
          children: <Widget>[
            ChessGraph(newData, names), // The actual graph
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[ // The two labels showing stats
                Padding(child: Text("You increased by an average of $myAverage points per game!"), padding: EdgeInsets.fromLTRB(0, 0, 0, 10)),
                Text("Peers increased by an average of $theirAverage points per game!")
              ],
            )
          ],
        ));
      }

      // Add these built widgets to the page view
      pages = [];
      pages.add(info[0]);
      pages.add(info[1]);

      // Return the page view with some spacing
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

  // async function to fetch all information about each player
  Future<List<Player>> getAllInfo() async {
    List<Player> workingPlayers = [];
    for (int i = 0; i < Singleton().peers.length+1; i++) {
      int refID;
      // If fetching the user's data, ensure the user has set themselves (this is actually not necessary i think)
      // Get the relevant player's ID and store it in refID
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

      // fetch all data for this player, and add the finished player object to working players
      Player player = await getPlayer(refID);
      workingPlayers.add(player);
    }
    return workingPlayers;
  }
}