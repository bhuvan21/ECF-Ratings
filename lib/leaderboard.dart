import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_project/player.dart';
import 'helpers.dart';
import 'singleton.dart';
import 'package:http/http.dart' as http;
import 'profile.dart';

class Leaderboard extends StatefulWidget {
  @override
  _LeaderboardState createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {

  bool loading = true;
  List<LeaderboardPlayer> myPlayers = [];

  @override
  Widget build(BuildContext context) {
    // Change filled icon if pressed or not
    return Scaffold(
      appBar:
        AppBar(title: Text("Leaderboard"), actions: <Widget>[
          IconButton(icon: Icon(Icons.filter_list,), onPressed: () => {
            Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeaderboardFilter())).then((dynamic)
              {
                setState(() {
                  loading = true;
                  getAllInfo().then((players){
                    myPlayers = players;
                    if (this.mounted) {
                      setState((){ loading = false; });
                    }
                  });
                });
              }
            )
            ,
          }
            ,)
        ],),
      body: buildList());
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      loading = true;
      getAllInfo().then((players){
        myPlayers = players;
        if (this.mounted) {
          setState((){ loading = false; });
        }
      });
    });
  }

  Future<List<LeaderboardPlayer>> getAllInfo() async {
    SharedPreferences p = await SharedPreferences.getInstance();
    List<LeaderboardPlayer> players = [];

    while (!p.containsKey("leaderboard")) {
    }

    List<String> args = p.getStringList("leaderboard");
    LeaderboardPrefs prefs = LeaderboardPrefs(args[0], args[1], args[2], args[3], args[4]);
    print(prefs);
    // Get main data
    final mainResponse = await http.get("https://www.ecfgrading.org.uk/v2/app/list_top_players.php?domain=${prefs.gameType}&age_limit=${prefs.ageLimit}&age_col=Age&nation=${prefs.nations}&gender=${prefs.genders}&type=${prefs.metric}&format=json");
    if (mainResponse.statusCode == 200) {
      var json = jsonDecode(mainResponse.body);
      for (int i = 0; i < json["players"].length; i++) {
        players.add(LeaderboardPlayer.fromJson(json["players"][i]));
      }
      return players;
    }
    else {
      // If the request failed, player has error code 2
      return [];
    }
  }

  Widget buildList() {
    if (loading) {
      return Center(child: CircularProgressIndicator(),);
    }






    return ListView.builder(
      itemCount: myPlayers.length,
      // Function is run for every index in the listview
      itemBuilder: (BuildContext context, int index) {
        LeaderboardPlayer player = myPlayers[index];
        String info1;
        String info2;
        Color info1color = Colors.red;
        Color info2color = Colors.blue;
        bool flip = true;

        if (Singleton().leaderboardPreference.metric == "player_grade") {
          info1 = player.standard.toString();
          info2 = player.rapid.toString();
        }
        else if (Singleton().leaderboardPreference.metric == "pdiff") {
          info1 = player.standardImprovement.toString();
          info2 = player.rapidImprovement.toString();
        }

        if (Singleton().leaderboardPreference.gameType == "S") {
          info1color = Colors.blue;
          info2color = Colors.red;
          flip = false;
        }

        if (flip) {
          String temp = info2;
          info2 = info1;
          info1 = temp;
        }
        if (info1 == "null") {
          info1 = "0";
        }
        if (info2 == "null") {
          info2 = "0";
        }


        return new ListTile(
          title: Text(myPlayers[index].name + " (${player.gender})"),
          onTap: () => {
            Singleton().selectedID = myPlayers[index].refCode,
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailProfile()),
            )
        },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[

              Container(
                color: info1color,
                child: SizedBox(
                width: 80,
                height: 40,
                child: Center(
                  child:Padding(
                    child:Text(info1, textScaleFactor: 1.2),
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                    )
                  ),
                )
              ),
              SizedBox(width: 7,),
              Container(
                  color: info2color,
                  child: SizedBox(
                    width: 80,
                    height: 40,
                    child: Center(
                        child:Padding(
                          child:Text(info2, textScaleFactor: 1.2),
                          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                        )
                    ),
                  )
              ),
            ],
          ),
        );
      },
    );
  }

}


class LeaderboardFilter extends StatefulWidget {
  @override
  _LeaderboardFilterState createState() => _LeaderboardFilterState();
}

class _LeaderboardFilterState extends State<LeaderboardFilter> {

  LeaderboardPrefs prefs;

  Map<int, Widget> _children = {
    0: Text('Male'),
    1: Text('Female'),
    2: Text('Both'),
  };
  List<String> genders = ["male", "female", "both"];
  int mfai;

  Map<int, Widget> _children2 = {
    0: Text('Rating'),
    1: Text('Improvement'),
    2: Text('Activity'),
  };
  List<String> metrics = ["player_grade", "pdiff", "pactivity"];
  int ria;

  FixedExtentScrollController firstController;
  List<String> ages = ['none', 'U20', 'U19', 'U18', 'U17', 'U16', 'U15', 'U14', 'U13', 'U12', 'U11', 'U9', 'U8', '50+', '55+', '60+', '65+', '70+', '75+'];
  List<Widget> pickerwidgs = [];

  @override
  void initState() {
    super.initState();
    prefs = Singleton().leaderboardPreference;
    mfai = genders.indexOf(prefs.genders);
    ria = metrics.indexOf(prefs.metric);
    firstController = FixedExtentScrollController(initialItem: ages.indexOf(prefs.ageLimit));
    for (int i = 0; i < ages.length; i++) {
      pickerwidgs.add(Center(child:Text(ages[i].toString())));
    }
  }

  void _pickerHandler() {
    setState(() {
      prefs.ageLimit = ages[firstController.selectedItem];
    });
    Singleton().setFilterPrefs(prefs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leaderboard Selection"),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: ()async{
        Navigator.pop(context,"From BackButton");
      }),),
      body:

      Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(0, 10, 0 ,0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child:  CupertinoSegmentedControl(
                    children: _children,
                    onValueChanged: (index)
                    {
                      setState(() {
                        mfai = index;
                      });
                      prefs.genders = genders[index];
                      Singleton().setFilterPrefs(prefs);
                    },
                    groupValue: mfai,
                  ),
                )
              ],
            )
          )
          ,
          Padding(child:Row(
            children: <Widget>[
              Text("Standard/Rapid"),
              Spacer(),
              Switch(
                value: prefs.gameType == "R",
                onChanged: (hit) {
                  if (hit) {
                    setState(() {
                      prefs.gameType = "R";
                    });
                  }
                  else {
                    setState(() {
                      prefs.gameType = "S";
                    });
                  }
                  Singleton().setFilterPrefs(prefs);
                },
              )
            ],
          ),
            padding: EdgeInsets.fromLTRB(18, 0, 5, 0),
          ),

          Padding(child:Row(
            children: <Widget>[
              Text("ENG/ALL"),
              Spacer(),
              Switch(
                value: prefs.nations == "ALL",
                onChanged: (hit) {
                  if (hit) {
                    setState(() {
                      prefs.nations = "ALL";
                    });
                  }
                  else {
                    setState(() {
                      prefs.nations = "ENG";
                    });
                  }
                  Singleton().setFilterPrefs(prefs);
                },
              )
            ],
          ),
            padding: EdgeInsets.fromLTRB(18, 0, 5, 0),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child:  CupertinoSegmentedControl(
                    children: _children2,
                    onValueChanged: (index)
                    {
                      setState(() {
                        ria = index;
                      });
                      prefs.metric = metrics[index];
                      Singleton().setFilterPrefs(prefs);
                    },
                    groupValue: ria,
                  ),
                )
              ],
            ),
          ),


          Expanded(
              child: Center(
                  child:CupertinoPicker(
                      itemExtent: 50,
                      scrollController: firstController,
                      onSelectedItemChanged: (int index) => _pickerHandler(),
                      children: pickerwidgs,
                      backgroundColor: Colors.white,
                  )

              )
          )



        ],
      ),);
  }

}