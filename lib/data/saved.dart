import 'package:sqflite/sqflite.dart' as sql;

import 'database.dart';

class StopwatchSaved {
    int id;
    Duration time;
    List<Duration> laps;
    DateTime date;

    StopwatchSaved({
        required this.time,
        List<Duration>? laps,
        this.id = -1,
        DateTime? date
    }) :
        laps = List.from(laps ?? List<Duration>.empty(growable: true)),
        date = date ?? DateTime.now()
    ;

    Future<int> insertDB([DatabaseInsertOptions? options]) async {
        int id = await Database.insert(options ?? DatabaseInsertOptions(
            databaseTable, {
                'time': time.inMicroseconds,
                'laps': laps.map((e) => e.inMicroseconds).join(';'),
                'date': date.toIso8601String()
            }
        ));
        this.id = id;
        return id;
    }

    Future<int> deleteDB([DatabaseDeleteOptions? options]) async {
        return await Database.delete(options ?? DatabaseDeleteOptions(
            databaseTable,
            where: 'id = ?',
            whereArgs: [id]
        ));
    }

    Future<int> updateDB([DatabaseUpdateOptions? options]) async {
        return await Database.update(options ?? DatabaseUpdateOptions(
            databaseTable, {
                'time': time.inMicroseconds,
                'laps': laps.map((e) => e.inMicroseconds).join(';'),
                'date': date.toIso8601String()
            },
            where: 'id = ?',
            whereArgs: [id]
        ));
    }

    static StopwatchSaved copy(StopwatchSaved other){
        return StopwatchSaved(
            time: other.time,
            date: other.date,
            id: other.id,
            laps: other.laps
        );
    }

    static DatabaseTables databaseTable = DatabaseTables.stopwatchSaved;

    static Future<List<StopwatchSaved>> queryDB([DatabaseQueryOptions? options]) async {
        List<Map<String, dynamic>> items = await Database.query(options ?? DatabaseQueryOptions(databaseTable));
        return [for (var item in items) StopwatchSaved(
            id: item['id'] as int,
            time: Duration(microseconds: item['time'] as int),
            laps: (){
                List<String> laps = (item['laps'] as String).split(';')..removeWhere((lap) => lap.trim().isEmpty);
                return laps.isEmpty
                    ? List<Duration>.empty(growable: true)
                    : laps.map((e) => Duration(microseconds: int.parse(e))).toList()
                ;
            }(),
            date: DateTime.parse(item['date'] as String),
        )];
    }

    static Future<int> clearDB() async {
        return await Database.delete(DatabaseDeleteOptions(databaseTable));
    }

    static Future<void> createDB(sql.Database db) async {
        return await db.execute(SQLCommands.createStopwatchSaved);
    }
}