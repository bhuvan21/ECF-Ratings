import 'dart:convert';
import 'dart:math';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'player.dart';
import 'singleton.dart';
import 'profile.dart';

// Search widget, manages searching for players
class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {

  final TextEditingController _filter = new TextEditingController();

  String _searchText = "";
  bool loading = true;
  bool focused = false;
  List<dynamic> search_results = [];
  FocusScope searchBar;

  // Whenever text input is changed, get new searched players, store data, and reset state with loading over
  _SearchState() {
    _filter.addListener(() {
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

  // Uses search endpoint to look up players who match query
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

  // Show back button if input open
  Widget _buildSideButton(BuildContext context) {
    if (focused) {
      return IconButton(icon:Icon(Icons.arrow_back), onPressed: closeSearch);
    }
    else {
      return null;
    }
  }

  // dismiss keyboard when search dismissed
  void closeSearch() {
    setState(() {
      focused = false;
      Focus child1 = searchBar.child;
      TextField child2 = child1.child;
      //child2.controller.text = "";
      FocusScope.of(context).requestFocus(FocusNode());
    });

  }

  void focusOn(bool focus) {
    focused = focus;
  }

  void focusOff(String value) {
    focused = false;
  }

  // builds list of search results from saved result of search query
  Widget _buildList() {
    // Show peers + favs if search is empty
    if (_searchText.isEmpty) {
      return ListView.builder(
        itemCount: Singleton().favourites.length ,
        itemBuilder: (BuildContext context, int index) {
          String add = "";
          if (Singleton().isPeer(Singleton().favourites[index])) {
            add = "(Peer) ";
          }

          String toShow = Singleton().favourites[index].split("|")[0];
          return new ListTile(
            title: Text(add + toShow),
            onTap: () => {
              Singleton().selectedID = int.tryParse(Singleton().favourites[index].split("|")[1]),
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailProfile()),
              )
            }
          );
        },
      );
    }
    else {
      // If loading show indicator
      if (loading) {
        return Center(
            child:CircularProgressIndicator()
        );
      }
      // If no results, say so
      else {
        if (search_results.length == 0) {
          return Text("no results found");
        }
        // If short query, say so
        else if (search_results[0] is int) {
          int error_code = search_results[0];
          if (error_code == 0) {
            return Text("too short");
          }
          else {
            return Text("Wifi issues?");
          }
        }
        // If successful, return list of results
        else {
          List<Player> player_list = search_results;
          return ListView.builder(
            itemCount: player_list.length,
            itemBuilder: (BuildContext context, int index) {
              return new ListTile(
                title: Text(player_list[index].name),
                onTap: () => {
                  Singleton().selectedID = player_list[index].refCode,
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailProfile()),
                  )
                },
              );
            },
          );
        }
      }
    }
  }
}