import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class ActionDatabase {
  static final _databseName = "ActionDatabse.db"; // DBの名前
  static final _databaseVersion = 1; // スキーマのバージョン指定

  static final table = 'action_table' // テーブル名

  // カラム名の定義
  static final id = 'ID'; // アクション識別番号
  static final name = 'Name'; // アクション名
  static final mtag = 'Mtag'; // メインタグ
  static final tag = 'Tag'; // サブタグ
  static final start = 'Start'; // 開始時刻
  static final end = 'End'; // 終了時刻
  static final duration = 'Duration'; // 総時間
  static final message = 'Message'; // 開始メッセージ
  static final media = 'Media'; // 添付メディア
  static final notes = 'Notes'; // 説明文
  static final score = 'Score'; // 充実度
  static final state = 'State'; // 記録状態
  static final place = 'Place'; // 場所

  // ActionDataBaseクラスを定義
  ActionDatabase._privateConstructor();
  // ActionDataBaseクラスのインスタンスは、常に同じものであるという保証
  static final ActionDatabase instance = ActionDatabase._privateConstructor();

  // Databaseクラス型のstatic変数_databaseを宣言
  // クラスはインスタンス化しない
  static Database? a_database;

  // databaseメソッド定義
  //　非同期処理
  Future<Database?> get a_database async {
    // NULLの場合、_initDatabaseを呼び出しデータベースの初期化し、_databaseに返す
    // NULLでない場合、そのままa_database変数を返す
    // これにより、データベースを初期化する処理は、最初にデータベースを参照するときにのみ実行されるようになります。
    if (a_database != null) return a_database;
    a_database = await _initDatabase();
    return a_database;
  }

  // データベース持続
  _initDatabase() async {
    // アプリケーションのドキュメントディレクトリのパスを取得
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // 取得パスを基に、データベースのパスを生成
    String path = join(documentsDirectory.path, a_databaseName);
    // データベース接続
    return await openDatabase(path,
        version: a_databaseVersion,
        // テーブル作成メソッドの呼び出し
        onCreate: _onCreate);
  }

  _addcolumn() async {
    await a_database?.execute('ALTER TABALE action_table ADD COLUMN time TEXT');
  }

  // テーブルの作成
  // 引数:dbの名前
  // 引数:スキーマーのversion
  // スキーマーのバージョンはテーブル変更時にバージョンを上げる（テーブル・カラム追加・変更・削除など）
  Future _onCreate(Database db, int version) async {
    //それぞれのidの型を指定する必要がある($id 型)の形で指定
    //データベースを再生成するときは１行下のプログラム実行しないといけない
    //await db.execute('DROP TABLE IF EXISTS action_table');
    await db.execute('''
          CREATE TABLE $table (
            $id INTEGER PRIMARY KEY,
            $name TEXT,
            $mtag TEXT,
            $tag TEXT,
            $start TEXT,
            $end TEXT,
            $duration INTEGER,
            $message TEXT,
            $media BLOB,
            $notes TEXT,
            $score INTEGER,
            $state INTEGER,
            $place TEXT
          )
          ''');
  }

  // データベースの任意の属性を読みだすメソッド
  Future<List<Map<String, dynamic>>> readAttribute(String attribute) async {
    Database? db = await instance.database;
    return await db!.query(table, columns: [attribute]);
  }

  // アクションが登録された時刻を取得し登録する
  void startTime() async {
    Database? db = await instance.database;
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    Map<String, dynamic> row = {start: currentTime.toString()};
    await db!.insert(table, row);
  }

  // アクションが終了ボタンからの信号を受け取った際に、その時刻を取得しデータベースの終了時刻属性に登録する
  void endTime() async {
    Database? db = await instance.database;
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    Map<String, dynamic> row = {end: currentTime.toString()};
    await db!.insert(table, row);
  }

  // 開始時刻と終了時刻をint型に直し経過時刻を計算
  // 計算された時間を総時間属性に登録
  void totalTime() async {
    Database? db = await instance.database;
    List<Map<String, dynamic>> rows = await db!.query(table);
    for (var row in rows) {
      int? startTime = int.tryParse(row[start]);
      int? endTime = int.tryParse(row[end]);
      if (startTime != null && endTime != null) {
        int elapsedTime = endTime - startTime;
        await db.update(table, {duration: elapsedTime}, where: '$id = ?', whereArgs: [row[id]]);
      }
    }
  }
}