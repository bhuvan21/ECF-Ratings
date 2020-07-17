import 'package:http/http.dart' as http;
import 'dart:convert';
import 'player.dart';


String playerToSaveString(Player player) {
  return player.name +"|" + player.refCode.toString();
}

Future<Player> getPlayer(int refID) async {

  Player workingPlayer = Player.empty();
  if (refID == 0) {
    return Player.empty();
  }

  final mainResponse = await http.get('https://www.ecfgrading.org.uk/sandbox/new/api.php?v2/players/code/'+refID.toString());

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