import 'package:flutter/material.dart';
import 'text_message_screen.dart';  // システム1
import 'qr_camera_screen.dart';     // システム2
import 'tourist_list_screen.dart';  // システム3
import 'login.dart';                // ログアウトのためのログイン画面
import 'dart:convert';              // json.decodeのために必要
import 'package:http/http.dart' as http; // HTTPリクエスト用
import 'dart:async';

class MainScreen extends StatefulWidget {
  final int userId; // ユーザID
  final String userName; // ユーザ名

  MainScreen({required this.userId, required this.userName});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  late Future<Map<String, dynamic>> _tourIdListFuture;

  final List<String> _imagePaths = [
    'assets/castle.png', // スライドショーに表示する画像のパス
    'assets/shrine.png',
    'assets/sweetShop.jpg',
    'assets/restaurant.jpeg',
  ];

  @override
  void initState() {
    super.initState();

    // GetTourIDList APIの呼び出しを一度だけ行い、その結果を保持
    _tourIdListFuture = _fetchTourIdList(widget.userId);

    // PageControllerの初期化
    _pageController = PageController();

    // 3秒ごとに画像を自動で切り替えるタイマーの設定
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _imagePaths.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _tourIdListFuture, // 初回のみ呼び出される
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final List<int> tourIdList = (snapshot.data!['tour_id_list'] as List<dynamic>).map((e) => e as int).toList();
          final List<int> planTourIdList = (snapshot.data!['plan_tour_id_list'] as List<dynamic>).map((e) => e as int).toList();

          return Scaffold(
            appBar: AppBar(
              title: Text('ホーム画面'),
              backgroundColor: Color(0xFF4F81BD),
              automaticallyImplyLeading: false, // 戻るボタンを非表示にする
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
            body: Stack(
              children: [
                // 背景画像を設定
                PageView.builder(
                  controller: _pageController,
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    return Opacity(
                      opacity: 0.5, // 透明度を設定（0.0から1.0の範囲）
                      child: Image.asset(
                        _imagePaths[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    );
                  },
                ),
                // メインコンテンツ
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          // システム1: テキストメッセージ画面へ遷移
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TextMessageScreen(
                                userId: widget.userId,
                                userName: widget.userName,
                                visitedTourIdList: tourIdList, // 訪問済みリストを渡す
                                plannedTourIdList: planTourIdList, // 訪問予定リストを渡す
                              ),
                              ),
                          );
                        },
                        style: _buttonStyle(),
                        child: Text('希望を入力',
                        style: TextStyle(
                          fontSize: 20, // フォントサイズを大きく指定
                        ),
                      ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // システム2: QRコードカメラ画面へ遷移
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QRCodeCameraScreen(
                                userId: widget.userId,
                                userName: widget.userName,
                                visitedTourIdList: tourIdList, // 訪問済みリストを渡す
                                plannedTourIdList: planTourIdList, // 訪問予定リストを渡す
                              ),
                            ),
                          );
                        },
                        style: _buttonStyle(),
                        child: Text('QRコード読み込み',
                        style: TextStyle(
                          fontSize: 20, // フォントサイズを大きく指定
                        ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // システム3: スタンプラリー画面へ遷移
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TouristListScreen(
                                userId: widget.userId,
                                userName: widget.userName,
                                visitedTourIdList: tourIdList, // 訪問済みリストを渡す
                                plannedTourIdList: planTourIdList, // 訪問予定リストを渡す
                              ),
                            ),
                          );
                        },
                        style: _buttonStyle(),
                        child: Text('スタンプラリーを表示',
                        style: TextStyle(
                          fontSize: 20, // フォントサイズを大きく指定
                        ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // ログアウト: ログイン画面に戻る
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        },
                        style: _logoutButtonStyle(),
                        child: Text('ログアウト',
                        style: TextStyle(
                          fontSize: 20, // フォントサイズを大きく指定
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  // GetTourIDList APIを呼び出す 
  Future<Map<String, dynamic>> _fetchTourIdList(int userId) async {
    final response = await http.get(
      Uri.parse('https://c8zv1lq2pe.execute-api.ap-northeast-1.amazonaws.com/QR/getTourIDList?user_id=$userId'),
    );

    // レスポンスボディを出力して確認
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load tour ID list');
    }
  }

  // ボタンのスタイルを定義する共通メソッド
  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF4F81BD),
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }

  ButtonStyle _logoutButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFB0C4DE),
      foregroundColor: Color(0xFF003366),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}
