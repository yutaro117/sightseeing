import 'dart:convert'; // UTF-8用のライブラリ
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Tourist_Detail_Screen.dart'; // TouristDetailScreenのインポート
import 'main_screen.dart'; // main_screen.dartをインポート

class TouristListScreen extends StatefulWidget {
  final List<int> visitedTourIdList; // 訪問済み観光地IDのリスト
  final List<int> plannedTourIdList; // 訪問予定観光地IDのリスト
  final int userId; // ユーザID
  final String userName; // ユーザ名

  const TouristListScreen({
    Key? key,
    required this.visitedTourIdList,
    required this.plannedTourIdList,
    required this.userId,
    required this.userName, // userNameを受け取る
  }) : super(key: key);

  @override
  _TouristListScreenState createState() => _TouristListScreenState();
}

class _TouristListScreenState extends State<TouristListScreen> {
  Map<int, String> tourNames = {}; // tour_idに対するtour_nameを保存するマップ
  List<int> plannedTourIdList = []; // 訪問予定観光地IDのリスト

  @override
  void initState() {
    super.initState();
    plannedTourIdList = widget.plannedTourIdList; // 初期値をセット
    _removeDuplicatesAndFetchTourNames(); // 重複を除外して観光地名を取得
  }

  Future<void> _removeDuplicatesAndFetchTourNames() async {
    // 訪問済みの観光地IDと予定の観光地IDの重複をチェック
    List<int> duplicates = widget.visitedTourIdList
        .where((tourId) => plannedTourIdList.contains(tourId))
        .toList();

    for (var tourId in duplicates) {
      await _deletePlannedTour(tourId); // 重複している観光地IDを削除
    }

    // 重複を除外した後の観光地名を取得
    await _fetchTourNames();
  }

  Future<void> _fetchTourNames() async {
    List<int> allTourIds = [...widget.visitedTourIdList, ...plannedTourIdList];
    allTourIds.sort(); // tour_idを小さい順にソート
    for (var tourId in allTourIds) {
      final response = await http.get(
        Uri.parse('https://c8zv1lq2pe.execute-api.ap-northeast-1.amazonaws.com/QR/TourNameGet?tour_id=$tourId'),
      );

      if (response.statusCode == 200) {
        // 明示的にUTF-8でデコードする
        final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        String tourName = jsonResponse;
        setState(() {
          tourNames[tourId] = tourName; // tour_idとtour_nameのマッピングを追加
        });
      } else {
        print("Failed to fetch tour name for ID: $tourId");
      }
    }
  }

  Future<void> _deletePlannedTour(int tourId) async {
    final url = Uri.parse(
      'https://c8zv1lq2pe.execute-api.ap-northeast-1.amazonaws.com/QR/deletePlanTourIDList?user_id=${widget.userId}&tour_id=$tourId',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      setState(() {
        plannedTourIdList = List<int>.from(jsonResponse['plan_tour_id_list']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('観光地ID $tourId を削除しました')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<int> allTourIds = [...widget.visitedTourIdList, ...plannedTourIdList];
    allTourIds.sort(); // tour_idを小さい順にソート

    return Scaffold(
      appBar: AppBar(
        title: Text('観光地リスト'),
        backgroundColor: Color(0xFF4F81BD),
        automaticallyImplyLeading: false, // 戻るボタンを非表示にする
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                      Text(
                        'User ID: ${widget.userId}',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Name: ${widget.userName}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: allTourIds.length,
        itemBuilder: (context, index) {
          int tourId = allTourIds[index];
          bool isVisited = widget.visitedTourIdList.contains(tourId); // 訪問済みかどうかを判定
          bool isPlanned = plannedTourIdList.contains(tourId); // 訪問予定かどうかを判定

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              leading: Checkbox(
                value: isVisited,
                onChanged: null, // チェックボックスは操作不可（表示のみ）
              ),
              title: Text(
                tourNames[tourId] ?? 'Loading...', // tour_nameがまだ取得できていない場合はLoadingを表示
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('Tour ID: $tourId'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPlanned)
                    ElevatedButton(
                      onPressed: () => _deletePlannedTour(tourId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text('削除'),
                    ),
                  SizedBox(width: 8), // ボタンの間隔を調整
                  ElevatedButton(
                    onPressed: () {
                      // 詳細画面に遷移する際にtourIdとtourNameを渡す
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TouristDetailScreen(
                            touristSpot: tourNames[tourId] ?? 'Unknown Spot',
                            tourId: tourId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFB0C4DE),
                      foregroundColor: Color(0xFF003366),
                      side: BorderSide(color: Color(0xFF4F81BD)),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text('詳細'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // main_screen.dartに遷移する際にuserIdとuserNameを渡す
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4F81BD),
            foregroundColor: Colors.white, // ボタンのテキスト色を設定
            padding: EdgeInsets.symmetric(vertical: 15),
          ),
          child: Text('メイン画面に戻る', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

