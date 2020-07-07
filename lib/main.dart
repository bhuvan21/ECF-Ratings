import 'dart:convert';
import 'dart:math';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Home(),
    );
  }
}


class Player {
  final String name;
  final String primaryClub;
  final String refCode;
  final int memberNumber;
  final String category;
  final DateTime dueDate;
  final int fide;
  final String primaryClubCode;
  final String gender;
  final String nation;
  final DateTime lastGame;

  Player(this.name, this.primaryClub, this.refCode, this.memberNumber, this.category, this.dueDate, this.fide, this.primaryClubCode, this.gender, this.nation, this.lastGame);

  Player.fromJson(Map<String, dynamic> json)
      : name = json['full_name'],
        primaryClub = json['club_name'] == null ? null : json['club_name'],
        refCode = json["ECF_code"],
        memberNumber = json["member_no"] == null ? null : int.tryParse(json["member_no"]),
        category = json["category"] == null ? null : json["category"],
        dueDate = json["due_date"] == null ? null : DateTime.tryParse(json["due_date"]),
        fide = json["FIDE_no"] == "" ? null : int.tryParse(json["FIDE_no"]),
        primaryClubCode = json["club_code"] == null ? null : json["club_code"],
        gender = json["gender"] == null ? null : json["gender"],
        nation = json["nation"] == null ? null : json["nation"],
        lastGame = json["due_date"] == null ? null : DateTime.tryParse(json["date_last_game"]);
}



class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final TextEditingController _filter = new TextEditingController();

  String _searchText = "";
  Icon _searchIcon = new Icon(Icons.search);

  Widget _appBarTitle = new Text( 'Search' );
  bool loading = true;
  bool focused = false;
  List<dynamic> search_results = [];


  FocusScope searchBar;

  _HomeState() {
    _filter.addListener(() {
      print("epico");
      setState(() {
        _searchText = _filter.text;
        loading = true;
        GetSearchedPlayers().then((players){
          search_results = players;

          setState((){ loading = false; });
        });
      });
    });
  }

  Future<List<dynamic>> GetSearchedPlayers() async {
    if (_searchText.length <= 3) {
      return [0];
    }
    final response = await http.get('https://www.ecfgrading.org.uk/sandbox/new/api.php?v2/players/name/$_searchText');

    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);

        List players = json["players"];
        List<Player> player_objects = [];
        for (int i = 0; i < min(players.length, 100); i++) {
          player_objects.add(Player.fromJson(players[i]));
        }
        return player_objects;
      }

    else {
      if (response.statusCode == 404) {
        if (jsonDecode(response.body)["msg"] == "no players found") {
          return [];
        }
      }
      return [1];

    }
  }



  @override
  void initState() {
    super.initState();
    searchBar = FocusScope(
        child: Focus(
            onFocusChange: focusOn,
            child: new TextField(
              controller: _filter,
              onSubmitted:  focusOff,
              decoration: new InputDecoration(
                  hintText: 'Search...'
              ),
            )
        )
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildBar(context),
      body: Container(
        child: _buildList(),
      ),
      resizeToAvoidBottomPadding: false,
    );
  }

  Widget _buildBar(BuildContext context) {
    return new AppBar(
      centerTitle: true,

      leading: _buildSideButton(context),
      title: searchBar

    );
  }

  Widget _buildSideButton(BuildContext context) {
    if (focused) {
      return IconButton(icon:Icon(Icons.arrow_back), onPressed: closeSearch);
    }
    else {
      return null;
    }
  }

  void closeSearch() {
    setState(() {
      focused = false;
      Focus child1 = searchBar.child;
      TextField child2 = child1.child;
      child2.controller.text = "";
      FocusScope.of(context).requestFocus(FocusNode());
    });

  }

  void focusOn(bool focus) {

    focused = focus;
  }

  void focusOff(String value) {
    focused = false;
  }

  Widget _buildList() {

    if (_searchText.isEmpty) {
      return Text("Favourites n peers");
    }
    else {
      if (loading) {
        return Center(
            child:CircularProgressIndicator()
        );
      }
      else {
        if (search_results.length == 0) {
          return Text("no results found");
        }
        else if (search_results[0] is int) {
          int error_code = search_results[0];
          if (error_code == 0) {
            return Text("too short");
          }
          else {
            return Text("Wifi issues?");
          }
        }

        else {
          List<Player> player_list = search_results;
          return ListView.builder(
            itemCount: player_list.length,
            itemBuilder: (BuildContext context, int index) {
              return new ListTile(
                title: Text(player_list[index].name),
                onTap: () => print(player_list[index].name),
              );
            },
          );
        }
      }
    }
  }



}

class Detail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Text("Detail"),
          ],
        ),
      ),
    );
  }
}
