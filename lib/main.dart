import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'player.dart';
import 'search.dart';
import 'leaderboard.dart';
import 'profile.dart';
import 'analysis.dart';
import 'singleton.dart';

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

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> with SingleTickerProviderStateMixin  {

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

        onTap: (currentIndex){

          setState(() {
            _currentIndex = currentIndex;
          });

          _tabController.animateTo(_currentIndex);

        },
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

  void _start_preferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Singleton().myID = prefs.getInt('myID') ?? 120787;

    if (!prefs.containsKey("favourites")) {
      prefs.setStringList("favourites", []);
      prefs.setStringList("peers", []);
      Singleton().favourites = [];
      Singleton().peers = [];
    }
    else {
      Singleton().favourites = prefs.getStringList("favourites");
      Singleton().peers = prefs.getStringList("peers");
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

