import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'singleton.dart';
import 'player.dart';
import 'package:http/http.dart' as http;
import 'graphing.dart';
import 'helpers.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  bool isDetail;
  bool loading;
  Player myPlayer = Player.empty();

  final pageController = PageController(initialPage: 0);


  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();

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

  Widget buildListView(int i) {
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
      itemCount: gameList.length + 1,
      itemBuilder: (BuildContext context, int index) {
        index = index - 1;
        String type;
        if(i == 0) {
          type = "Standard";
        }
        else {
          type = "Rapid";
        }
        if (index == -1) {
          return ListTile(
            title: Text(myPlayer.name + " : " + gameList[0].myGrade.toString() + " : " +type)
          );
        }
        Game game = gameList[index];
        print(game.opponentName);
        if (game.opponentName == "") {
          return ListTile(
            title: Text("Bye")
          );
        }

        if ((game.increment == 0.0 && game.myGrade == null && game.opponentGrade == null)|| game.increment == null) {
          return ListTile (
            title: Text(myPlayer.name + " vs " + game.opponentName)
          );
        }
        String operator = "";
        if (game.increment > 0) {
          operator = "+";
        }
        else {
          operator = "-";
        }

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

  Widget buildGridView() {
    if (myPlayer == Player.empty()) {
      return null;
    }
    return new GridView.count(
      primary: true,
      crossAxisCount: 2,
      childAspectRatio: 6,
      shrinkWrap: true,
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      children: List.generate(myPlayer.clubs.length, (index) {
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
                    color: [Colors.red, Colors.green, Colors.yellow, Colors.blue, Colors.pink][Random().nextInt(5)],
                  )

                ]
            )
        );
      }),
    );
  }

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
  
  Widget buildMain(BuildContext context) {
    if (loading) {
      return Center(child:CircularProgressIndicator());
    }
    else {
      if (myPlayer.error != 0) {
        print(myPlayer.error);
        if (myPlayer.error == 1) {
          return Text("Please set your identity by searching for yourself in the search tab and using the button in the top right.");
        }
        return Text("Error");
      }
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
                child:Container(
                  height: 100,
                  child:Column(
                    children: <Widget>[
                      FittedBox(fit:BoxFit.fitWidth, child:Text(myPlayer.name, textScaleFactor: 2)),
                      Padding(padding: EdgeInsets.all(2),),
                      Text(myPlayer.currentClub.name + "| (" + myPlayer.gender + ") #" + myPlayer.refCode.toString() + ", FIDE:" + myPlayer.fide.toString() + " " + myPlayer.nation, textScaleFactor: 1.2, maxLines: 2, textAlign: TextAlign.center,),
                    ],
                  ),
                )
              ),

              Expanded(
                child: PageView.builder(itemBuilder: (context, position) => pages[position], itemCount: pages.length,),
              ),

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
          )
        ,
      ));
    }
  }
}

class DetailProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Singleton().isProfileViewDetail = true;

    return Scaffold(
      body: Profile(),
    );
  }
}

class MyProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Singleton().isProfileViewDetail = false;
    return Scaffold(
      body: Profile(),
    );
  }
}


class RelationButton extends StatefulWidget {
  int index;
  RelationButton(this.index);

  @override
  _RelationButtonState createState() => _RelationButtonState();
}

class _RelationButtonState extends State<RelationButton> {
  @override
  Widget build(BuildContext context) {
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

class IdentityButton extends StatefulWidget {
  @override
  _IdentityButtonState createState() => _IdentityButtonState();
}

class _IdentityButtonState extends State<IdentityButton> {

  bool selected = false;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return IconButton(icon: Icon(Icons.person), onPressed: onTap);
    }
    return IconButton(icon: Icon(Icons.person_outline), onPressed: onTap);
  }

  void onTap() {
    if (!selected) {
      setState(() {
        selected = true;
        
        Singleton().setMe(Singleton().selectedPlayer.refCode);
      });
    }
  }
}