import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'singleton.dart';
import 'player.dart';
import 'package:http/http.dart' as http;

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
        pages.add(buildFirstListView());
        setState((){ loading = false; });
      });
    });
  }

  Widget buildFirstListView() {
    if (myPlayer == Player.empty()) {
      return null;
    }
    return ListView.builder(
      itemCount: myPlayer.standardGames.length + 1,
      itemBuilder: (BuildContext context, int index) {
        index = index - 1;
        if (index == -1) {
          return ListTile(
            title: Text(myPlayer.name + " : " + myPlayer.standardGames[0].myGrade.toString())
          );
        }
        Game game = myPlayer.standardGames[index];


        if (game.opponentName == "") {
          return ListTile(
            title: Text("Bye")
          );
        }

        if (game.increment == 0.0 && game.myGrade == null && game.opponentGrade == null) {
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

        print(game.opponentName);
        int t = 0;
        print(game.myGrade);
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
          onTap: () => print(myPlayer.standardGames[index].opponentName),
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
    String refID;
    Player workingPlayer;
    List<Club> clubs = [];
    if (!Singleton().isProfileViewDetail) {
      refID = Singleton().myID.toString();
      if (refID == 0) {
        workingPlayer = Player.empty();
        workingPlayer.error = 1;
        return workingPlayer;
      }
    }
    else {
      refID = Singleton().selectedID.toString();
    }

    final mainResponse = await http.get('https://www.ecfgrading.org.uk/sandbox/new/api.php?v2/players/code/'+refID);

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

  Widget buildBar(BuildContext context) {
    if (loading) {
      return null;
    }
    else {
      String text = "My Profile";
      if (Singleton().isProfileViewDetail) {
        text = "Profile";
      }

      int pCode = 0;
      if (Singleton().isPeer(Singleton().selectedPlayer.name +"|"+ Singleton().selectedPlayer.refCode)) {
        pCode = 2;
      }
      else if (Singleton().isFavourite(Singleton().selectedPlayer.name +"|" + Singleton().selectedPlayer.refCode)) {
        pCode = 1;
      }

      return AppBar(title: Center(child:Text(text)),actions: <Widget>[RelationButton(pCode)],);
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
      return SizedBox.expand(
          child:Container(
          child: Column(
            children : <Widget> [
              Padding(
                padding: EdgeInsets.all(16.0),
                child:Container(
                  height: 100,
                  child:Column(
                    children: <Widget>[
                      FittedBox(fit:BoxFit.fitWidth, child:Text(myPlayer.name, textScaleFactor: 2)),
                      Padding(padding: EdgeInsets.all(2),),
                      Text(myPlayer.currentClub.name + "| (" + myPlayer.gender + ") #" + myPlayer.refCode + ", FIDE:" + myPlayer.fide.toString() + " " + myPlayer.nation, textScaleFactor: 1.2, maxLines: 2, textAlign: TextAlign.center,),
                    ],
                  ),
                )
              ),

              Expanded(
                child: PageView.builder(itemBuilder: (context, position) => pages[position]),
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
        Singleton().removeFavourite(Singleton().selectedPlayer.name +"|" + Singleton().selectedPlayer.refCode );
        Singleton().removePeer(Singleton().selectedPlayer.name +"|"+ Singleton().selectedPlayer.refCode );
      }
      else if (widget.index == 1) {
        widget.index = widget.index + 1;
        Singleton().addPeer(Singleton().selectedPlayer.name +"|"+ Singleton().selectedPlayer.refCode );
      }
      else {
        widget.index = widget.index + 1;
        Singleton().addFavourite(Singleton().selectedPlayer.name +"|"+ Singleton().selectedPlayer.refCode);
      }
    });

  }

}