import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'search.dart';
import 'leaderboard.dart';
import 'profile.dart';
import 'analysis.dart';
import 'singleton.dart';
import 'helpers.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Main(),
    );
  }
}

// This is the root widget, managing tabs of other widgets
class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> with SingleTickerProviderStateMixin  {

  // Used for managing tabs
  int _currentIndex = 0;
  List<Widget> _tabList = [
    Leaderboard(),
    Search(),
    Analysis(),
    MyProfile()
  ];
  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _start_preferences();
    _tabController = TabController(vsync: this, length: _tabList.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: _tabList,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        // When a tab button is pressed, go the relevant widget
        onTap: (currentIndex){
          setState(() {_currentIndex = currentIndex;});
          _tabController.animateTo(_currentIndex);
        },
        // Tab bar button items
        items: [
          BottomNavigationBarItem(
              title: Text("Leaderboard"),
              backgroundColor: Colors.blue,
              icon: Icon(Icons.assistant_photo)
          ),
          BottomNavigationBarItem(
              title: Text("Search"),
              backgroundColor: Colors.blue,
              icon: Icon(Icons.search)
          ),
          BottomNavigationBarItem(
              title: Text("Analysis"),
              backgroundColor: Colors.blue,
              icon: Icon(Icons.table_chart)
          ),
          BottomNavigationBarItem(
              title: Text("My Profile"),
              backgroundColor: Colors.blue,
              icon: Icon(Icons.perm_contact_calendar)
          )
        ],
      ),
    );
  }

  // Handle loading from saved preferences, or setting defaults on first run
  void _start_preferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Singleton().myID = prefs.getInt('myID') ?? 0;

    if (!prefs.containsKey("favourites")) {
      prefs.setStringList("favourites", []);
      prefs.setStringList("peers", []);
      Singleton().favourites = [];
      Singleton().peers = [];
      LeaderboardPrefs leaderboard = LeaderboardPrefs("S", "ENG", "none", "both", "player_grade");
      Singleton().setFilterPrefs(leaderboard);
    }
    else {
      Singleton().favourites = prefs.getStringList("favourites");
      Singleton().peers = prefs.getStringList("peers");
      List<String> args = prefs.getStringList("leaderboard");
      Singleton().leaderboardPreference = LeaderboardPrefs(args[0], args[1], args[2], args[3], args[4]);
      print(Singleton().leaderboardPreference);
    }
  }
}