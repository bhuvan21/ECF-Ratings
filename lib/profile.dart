import 'dart:math';
import 'package:flutter/material.dart';

import 'singleton.dart';
import 'player.dart';
import 'graphing.dart';
import 'helpers.dart';

// Profile widget is responsible for both the my profile and detail profile view, giving information about a player
class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {


  // Used to track whether data is loaded yet
  bool loading;
  // Stores the player this view is about
  Player myPlayer = Player.empty();
  // Controller for the main page view
  final pageController = PageController(initialPage: 0);
  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();

    // Load in the relevant player, store them to myPlayer, and set loading to be finished
    setState(() {
      loading = true;
      getAllInfo().then((player){
        myPlayer = player;
        Singleton().selectedPlayer = myPlayer;
        if (this.mounted) {
          setState((){ loading = false; });
        }
      });
    });
  }

  // Used to build the list of games view
  Widget buildListView(int i) {
    // Only continue if data is loaded
    if (loading) {
      return null;
    }
    List<Game> gameList = [];
    if (i == 0) {
      gameList = myPlayer.standardGames;
    }
    else {
      gameList = myPlayer.rapidGames;
    }

    if (myPlayer == Player.empty()) {
      return null;
    }
    return ListView.builder(
      // One extra row for the current rating
      itemCount: gameList.length + 1,
      // Function is run for every index in the listview
      itemBuilder: (BuildContext context, int index) {
        index = index - 1;
        String type;
        if(i == 0) {
          type = "Standard";
        }
        else {
          type = "Rapid";
        }
        // The top row should just show the current rating
        if (index == -1) {
          return ListTile(
            title: Text(myPlayer.name + " : " + gameList[0].myGrade.toString() + " : " +type)
          );
        }

        Game game = gameList[index];

        // If the oppenet doesn't exist, it's a bye
        if (game.opponentName == "") {
          return ListTile(
            title: Text("Bye")
          );
        }

        // If it's an incomplete game, just show player names
        if ((game.increment == 0.0 && game.myGrade == null && game.opponentGrade == null)|| game.increment == null) {
          return ListTile (
            title: Text(myPlayer.name + " vs " + game.opponentName)
          );
        }

        // Determine whether a + or - should be shown in front of increment
        String operator = "";
        if (game.increment > 0) {
          operator = "+";
        }
        else {
          operator = "-";
        }

        // Decide colors based on whether player won or lost
        Color meColor;
        Color themColor;
        if (game.increment > 0) {
          meColor = Colors.lightGreen;
          themColor = Colors.red;
        }
        else {
          meColor = Colors.red;
          themColor = Colors.lightGreen;
        }

        // Use rich text to make coloring easy, return a list tile (like a row), with colored game information
        return new ListTile(
          title: RichText(text:
          TextSpan(
            style: TextStyle(color:Colors.black),
            children: [
              TextSpan(
                text:myPlayer.name + " ",
              ),
              TextSpan(
                text: "(" +  (game.myGrade - game.increment).round().toString() + " " + operator +  (game.increment.round().abs()).toString() + ")",
                style: TextStyle(color:meColor)
              ),
              TextSpan(
                text: " vs "
              ),
              TextSpan(
                text: game.opponentName + " ",
              ),
              TextSpan(
                text: "(" + game.opponentGrade.toString() + ")",
                style: TextStyle(color: themColor)
              )
            ]
          )),
          onTap: () => print(gameList[index].opponentName),
        );
      },
    );
  }

  // Returns the grid view that displays the clubs a player is part of
  Widget buildGridView() {
    if (myPlayer == Player.empty()) {
      return null;
    }
    return new GridView.count(
      primary: true,
      crossAxisCount: 2, // Two columns
      childAspectRatio: 6, // Wide and short
      shrinkWrap: true, // Be as small as possible
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      children: List.generate(myPlayer.clubs.length, (index) {
        // Return a basic colored rect with the club name on it for every club
        return Container(
          child: Wrap(
            children:[
              Container(
                child: Padding(
                  child:Center(
                    child:Text(myPlayer.clubs[index].name)
                  ),
                  padding: EdgeInsets.all(10),
                ),
                // Assign the club a random color - TODO use a hash for consistency
                color: [Colors.red, Colors.green, Colors.yellow, Colors.blue, Colors.pink][Random().nextInt(5)],
              )
            ]
          )
        );
      }),
    );
  }

  // Determines what the player to get's ID is, and gets their info
  Future<Player> getAllInfo() async {
    int refID;
    Player workingPlayer;
    List<Club> clubs = [];
    if (!Singleton().isProfileViewDetail) {
      refID = Singleton().myID;
      if (refID == 0) {
        workingPlayer = Player.empty();
        workingPlayer.error = 1;
        return workingPlayer;
      }
    }
    else {
      refID = Singleton().selectedID;
    }
    return getPlayer(refID);
  }

  // Builds the app bar, adjusting the state of buttons depending on the context
  Widget buildBar(BuildContext context) {
    if (loading) {
      return null;
    }
    else {
      String text = "My Profile";
      if (Singleton().isProfileViewDetail) {
        text = "Profile";
        int pCode = 0;
        if (Singleton().isPeer(Singleton().selectedPlayer.name +"|"+ Singleton().selectedPlayer.refCode.toString())) {
          pCode = 2;
        }
        else if (Singleton().isFavourite(Singleton().selectedPlayer.name +"|" + Singleton().selectedPlayer.refCode.toString())) {
          pCode = 1;
        }

        return AppBar(title: Center(child:Text(text)),actions: <Widget>[RelationButton(pCode), IdentityButton()],);
      }
      else {
        return AppBar(title: Center(child:Text(text)),);
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBar(context),
      body: Container(
        child: buildMain(context),
      ),
      resizeToAvoidBottomPadding: false,
    );
  }

  // Returns the main view for the profile view
  Widget buildMain(BuildContext context) {
    // Still loading, so show an indicator
    if (loading) {
      return Center(child:CircularProgressIndicator());
    }
    else {
      // Guard against errors
      if (myPlayer.error != 0) {
        print(myPlayer.error);
        if (myPlayer.error == 1) {
          return Text("Please set your identity by searching for yourself in the search tab and using the button in the top right.");
        }
        return Text("Other error");
      }

      // Populate page view with graphs and tables (standard and rapid)
      pages = [];
      pages.add(ChessGraph([myPlayer.standardGames], [myPlayer.name]));
      pages.add(buildListView(0));
      pages.add(ChessGraph([myPlayer.rapidGames], [myPlayer.name]));
      pages.add(buildListView(1));


      return SizedBox.expand(
        child:Container(
          child: Column(
            children : <Widget> [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 5),
                child:Container( // Basic information is stored in a few labels
                  height: 100,
                  child:Column(
                    children: <Widget>[
                      FittedBox(fit:BoxFit.fitWidth, child:Text(myPlayer.name, textScaleFactor: 2)), // The name is adjusted to fit properly
                      Padding(padding: EdgeInsets.all(2),),
                      // The other information is given two lines to spread across
                      Text(myPlayer.currentClub.name + "| (" + myPlayer.gender + ") #" + myPlayer.refCode.toString() + ", FIDE:" + myPlayer.fide.toString() + " " + myPlayer.nation, textScaleFactor: 1.2, maxLines: 2, textAlign: TextAlign.center,),
                    ],
                  ),
                )
              ),

              // The page view with graphs and lists should fill the space it has - other widgets are relatively fixed
              Expanded(
                child: PageView.builder(itemBuilder: (context, position) => pages[position], itemCount: pages.length,),
              ),
              // Finally the grid view at the bottom, with a little padding
              Padding(
                padding: EdgeInsets.all(10),
                child:ConstrainedBox(
                  child:buildGridView(),
                  constraints: BoxConstraints(
                    maxHeight: 200
                  ),
                )
              )
            ]
          ),
        )
      );
    }
  }
}

// Basic widget containing a profile, lets it be known that this a detail view
class DetailProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Singleton().isProfileViewDetail = true;

    return Scaffold(
      body: Profile(),
    );
  }
}

// Basic widget containing a profile, lets it be known that this a my profile view
class MyProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Singleton().isProfileViewDetail = false;
    return Scaffold(
      body: Profile(),
    );
  }
}

// Widget button for marking players as favourites or peers, initialised with an index
// 0 = nothing, 1 = favourite, 2 = peer
class RelationButton extends StatefulWidget {
  int index;
  RelationButton(this.index);

  @override
  _RelationButtonState createState() => _RelationButtonState();
}

class _RelationButtonState extends State<RelationButton> {
  @override
  Widget build(BuildContext context) {
    // Change color of star icon, based on current state
    if(widget.index == 0 ) {
      return IconButton(icon:Icon(Icons.star_border), onPressed: onTap,);
    }
    else if (widget.index == 1) {
      return IconButton(icon: Icon(Icons.star, color: Colors.yellow,), onPressed: onTap);
    }
    else {
      return IconButton(icon: Icon(Icons.star, color: Colors.green,), onPressed: onTap);
    }
  }

  // When pressed, either remove player from peers and favourites, add them to favourites, or add them to peers
  // Peers is a subset of favourites
  void onTap() {
    setState(() {
      if (widget.index == 2) {
        widget.index = 0;
        Singleton().removeFavourite(playerToSaveString(Singleton().selectedPlayer));
        Singleton().removePeer(playerToSaveString(Singleton().selectedPlayer));
      }
      else if (widget.index == 1) {
        widget.index = widget.index + 1;
        Singleton().addPeer(playerToSaveString(Singleton().selectedPlayer));
      }
      else {
        widget.index = widget.index + 1;
        Singleton().addFavourite(playerToSaveString(Singleton().selectedPlayer));
      }
    });
  }
}

// Widget button for selecting identity
class IdentityButton extends StatefulWidget {
  @override
  _IdentityButtonState createState() => _IdentityButtonState();
}

class _IdentityButtonState extends State<IdentityButton> {

  bool selected = false;

  @override
  Widget build(BuildContext context) {
    // Change filled icon if pressed or not
    if (selected) {
      return IconButton(icon: Icon(Icons.person), onPressed: onTap);
    }
    return IconButton(icon: Icon(Icons.person_outline), onPressed: onTap);
  }

  // Add this player as "me"
  // There is no reverse to this, as there should never be no "me"
  void onTap() {
    if (!selected) {
      setState(() {
        selected = true;
        Singleton().setMe(Singleton().selectedPlayer.refCode);
      });
    }
  }
}