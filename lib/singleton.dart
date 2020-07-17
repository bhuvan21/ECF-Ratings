import 'player.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Singleton stores data that needs to be accessed globally
class Singleton {
  static final Singleton _singleton = Singleton._internal();

  factory Singleton() {
    return _singleton;
  }

  Singleton._internal();

  bool isProfileViewDetail;
  int myID;
  int selectedID;

  List<String> favourites;
  List<String> peers;

  Player selectedPlayer;

  // Bunch of helper functions which manage peers, favs, and identity, all of which require shared preferences
  void removeFavourite(String fav) async {
    for (int i = 0; i < Singleton().favourites.length; i++) {
      if (Singleton().favourites[i] == fav) {
        Singleton().favourites.removeAt(i);
      }
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("favourites", Singleton().favourites);
  }

  bool isFavourite(String fav) {
    for (int i = 0; i < Singleton().favourites.length; i++) {
      if (Singleton().favourites[i] == fav) {
        return true;
      }
    }
    return false;
  }

  bool isPeer(String peer) {
    for (int i = 0; i < Singleton().peers.length; i++) {
      if (Singleton().peers[i] == peer) {
        return true;
      }
    }
    return false;
  }

  void removePeer(String peer) async {
    for (int i = 0; i < Singleton().peers.length; i++) {
      if (Singleton().peers[i] == peer) {
        Singleton().peers.removeAt(i);
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("peers", Singleton().peers);
  }

  void addPeer(String peer) async {
    Singleton().peers.add(peer);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("peers", Singleton().peers);
  }

  void addFavourite(String fav) async {
    Singleton().favourites.add(fav);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("favourites", Singleton().favourites);
  }

  void setMe(int me) async {
    Singleton().myID = me;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("myID", Singleton().myID);
  }
}