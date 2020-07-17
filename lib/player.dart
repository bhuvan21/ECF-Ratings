class Club {
  final String code;
  final String name;
  Club(this.name, this.code);
  Club.fromJson(Map<String, dynamic> json) :
      code =  json["club_code"] == null ? null : json["club_code"],
      name =  json["club_name"] == null ? null : json["club_name"];
}

class Grade {
  final DateTime date;
  final String type;
  final int value;

  Grade(this.value, this.date, this.type);
  Grade.fromJson(Map<String, dynamic> json, String typ) :
        date = json["effective_date"] == null ? null : DateTime.tryParse(json["effective_date"]),
        type = typ,
        value = json["revised_grade"] == "" ? null : int.tryParse(json["revised_grade"]);

}

class Game {
  final DateTime gameDate;
  final String color;
  final int score;
  final String opponentName;
  final int opponentID;
  final int opponentGrade;
  final double increment;
  final int myGrade;
  final int eventCode;
  final String organisationName;
  final String eventName;
  final String sectionName;
  String gameType;

  Game(this.gameDate, this.color, this.score, this.opponentName, this.opponentID, this.opponentGrade, this.increment, this.myGrade, this.eventCode, this.organisationName, this.eventName, this.sectionName, this.gameType);
  Game.fromJson(Map<String, dynamic> json) :
      gameDate = json["game_date"] == null ? null : DateTime.tryParse(json["game_date"]),
      color = json["colour"] == null ? null : json["colour"],
      score = json["score"] == null ? null : int.tryParse(json["score"]),
      opponentName = json["opponent_name"] == null ? null : json["opponent_name"],
      opponentID = json["opponent_no"] == null ? null : int.tryParse(json["opponent_no"]),
      opponentGrade = json["opponent_grade"] == null ? null : int.tryParse(json["opponent_grade"]),
      increment = json["increment"] == null ? null : double.tryParse(json["increment"]),
      myGrade = json["player_grade"] == null ? null : int.tryParse(json["player_grade"]),
      eventCode = json["event_code"] == null ? null : int.tryParse(json["event_code"]),
      organisationName = json["org_name"] == null ? null : json["org_name"],
      eventName = json["event_name"] == null ? null : json["event_name"],
      sectionName = json["section_title"] == null ? null : json["section_title"],
      gameType = "";
}

class Player {
  final String name;
  final int refCode;
  final int memberNumber;
  final String category;
  final DateTime dueDate;
  final int fide;
  final String gender;
  final String nation;
  final DateTime lastGame;
  final Club currentClub;
  Grade currentStandard;
  Grade currentRapid;
  List<Club> clubs;
  List<Game> standardGames;
  List<Game> rapidGames;
  int error;

  Player(this.name, this.refCode, this.memberNumber, this.category, this.dueDate, this.fide, this.gender, this.nation, this.lastGame, this.currentClub, this.currentStandard, this.currentRapid, this.clubs, this.standardGames, this.rapidGames, this.error);

  static List<Club> jsonToClubs(Map<String, dynamic> json) {
    List<Club> clubs = [];
    if (!json.containsKey("clubs"))  {
      return [];
    }
    for (int i = 0; i < json["clubs"].length ;i++) {
      clubs.add(Club.fromJson(json["clubs"][i]));
    }
    return clubs;
  }

  Player.fromJson(Map<String, dynamic> json)
      : name = json['full_name'],
        refCode = int.tryParse(json["ECF_code"]) ?? int.tryParse(json["ECF_code"].toString().substring(0, json["ECF_code"].toString().length-1)),
        memberNumber = json["member_no"] == null ? null : int.tryParse(json["member_no"]),
        category = json["category"] == null ? null : json["category"],
        dueDate = json["due_date"] == null ? null : DateTime.tryParse(json["due_date"]),
        fide = json["FIDE_no"] == "" ? null : int.tryParse(json["FIDE_no"]),
        gender = json["gender"] == null ? null : json["gender"],
        nation = json["nation"] == null ? null : json["nation"],
        lastGame = json["date_last_game"] == null ? null : DateTime.tryParse(json["date_last_game"]),
        currentClub = Club(json['club_name'] == null ? null : json['club_name'], json["club_code"] == null ? null : json["club_code"]),
        currentStandard = Grade(0, DateTime.now(), "F"),
        currentRapid = Grade(0, DateTime.now(), "F"),
        clubs = jsonToClubs(json),
        standardGames = [],
        rapidGames = [],
        error=0;

  Player.empty() :
        name = "",
        refCode = 0,
        memberNumber = 0,
        category = "",
        dueDate = DateTime.now(),
        fide = 0,
        gender = "",
        nation = "",
        lastGame = DateTime.now(),
        currentClub = Club("", ""),
        currentStandard = Grade(0, DateTime.now(), ""),
        currentRapid = Grade(0, DateTime.now(), ""),
        clubs = [],
        standardGames = [],
        rapidGames = [],
        error = 10;
}

