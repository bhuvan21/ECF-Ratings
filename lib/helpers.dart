import 'package:http/http.dart' as http;
import 'dart:convert';

import 'player.dart';

// This file contains a bunch of helper functions/classes, used across multiple pages

// Converts a player to a string, retaining basic display data, and further lookup refID
String playerToSaveString(Player player) {
  return player.name +"|" + player.refCode.toString();
}

// Gets all data about a player from their refID
Future<Player> getPlayer(int refID) async {

  Player workingPlayer = Player.empty();
  // If refID is invalid, return an empty player with error code 1
  if (refID == 0) {
    Player empty = Player.empty();
    empty.error = 1;
    return empty;
  }

  // Get main data
  final mainResponse = await http.get('https://www.ecfgrading.org.uk/sandbox/new/api.php?v2/players/code/'+refID.toString());
  if (mainResponse.statusCode == 200) {
    var json = jsonDecode(mainResponse.body);
    workingPlayer = Player.fromJson(json);
  }
  else {
    // If the request failed, player has error code 2
    workingPlayer = Player.empty();
    workingPlayer.error = 2;
    return workingPlayer;
  }

  // Assuming nothing bad happened, get standard games and add them to the player object
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
      // If the request failed, player has error code 2
      workingPlayer = Player.empty();
      workingPlayer.error = 2;
      return workingPlayer;
    }
  }

  // Assuming nothing bad happened, get rapid games and add them to the player object
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
      // If the request failed, player has error code 2
      workingPlayer = Player.empty();
      workingPlayer.error = 2;
      return workingPlayer;
    }
  }
  return workingPlayer;
}



class LeaderboardPrefs {
  String gameType;
  String nations;
  String ageLimit;
  String genders;
  String metric;
  LeaderboardPrefs(this.gameType, this.nations, this.ageLimit, this.genders, this.metric);
}