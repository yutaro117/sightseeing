import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tourist_list_screen.dart'; // tourist_list_screenをインポート
import 'main_screen.dart';

class TextMessageScreen extends StatefulWidget {
  final int userId; // ユーザIDを受け取る
  final String userName; // ユーザ名前を受け取る
  final List<int> visitedTourIdList; // 訪問済み観光地リストを受け取る
  final List<int> plannedTourIdList; // 観光予定リストを受け取る

  const TextMessageScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.visitedTourIdList,
    required this.plannedTourIdList,
  }) : super(key: key);

  @override
  _TextMessageScreenState createState() => _TextMessageScreenState();
}

class _TextMessageScreenState extends State<TextMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<dynamic> _recommendedTourList = []; // 推奨観光地リスト
  List<int> _addedTourIds = []; // ユーザーが追加した観光地のIDを保持

  final List<String> _imagePaths = [
    'assets/castle.png',
    'assets/shrine.png',
    'assets/sweetShop.jpg',
    'assets/restaurant.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _imagePaths.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 2000),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _submitMessage() async {
    String message = _messageController.text;
    if (message.isNotEmpty) {
      print('Message submitted: $message');
      try {
        // APIリクエストを送信
        var url = Uri.parse(
          'https://c8zv1lq2pe.execute-api.ap-northeast-1.amazonaws.com/QR/getTourList?text_input=${Uri.encodeComponent(message)}&user_id=${widget.userId}',
        );
        var response = await http.get(url);

        // レスポンスボディをUTF-8でデコード
        String decodedResponse = utf8.decode(response.bodyBytes);
        print('Response body (decoded): $decodedResponse'); // デバッグ用ログ

        if (response.statusCode == 200) {
          var data = jsonDecode(decodedResponse);
          setState(() {
            _recommendedTourList = data; // 取得した観光地リストを保存
          });

          // ポップアップを表示
          if (_recommendedTourList.isNotEmpty) {
            _showRecommendedToursPopup();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('提案された観光地はありません。')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: ${response.statusCode}')),
          );
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました')),
        );
      }
    }
  }

  void _showRecommendedToursPopup() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('提案された観光地'),
        content: SingleChildScrollView(
          child: Column(
            children: _recommendedTourList.map<Widget>((tour) {
              int tourId = tour['tour_id'];

              // 追加済みの判定を観光済みリストか観光予定リストのいずれかにする
              bool isAdded = widget.visitedTourIdList.contains(tourId) || widget.plannedTourIdList.contains(tourId);
              String statusText = isAdded ? '追加済み' : '新規';

              return ListTile(
                title: Text('${tour['tour_name']} (ID: $tourId) - $statusText'),
                trailing: isAdded
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: Text('追加済み'),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          _addedTourIds.add(tourId); // 観光地を追加
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${tour['tour_name']} が追加されました。')),
                          );
                        },
                        child: Text('追加'),
                      ),
              );
            }).toList(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // ポップアップを閉じる
              _navigateToTouristListScreen();
            },
            child: Text('次へ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // ポップアップを閉じる
            },
            child: Text('戻る'),
          ),
        ],
      );
    },
  );
}


  Future<void> _navigateToTouristListScreen() async {
    // 観光地リスト画面に遷移
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TouristListScreen(
          visitedTourIdList: widget.visitedTourIdList,
          plannedTourIdList: List.from(widget.plannedTourIdList)..addAll(_addedTourIds), // 追加された観光地を観光予定リストに加える
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  // 「戻る」ボタンでMainScreenに遷移
  void _navigateBackToMainScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('テキスト入力'),
        backgroundColor: Color(0xFF4F81BD),
        automaticallyImplyLeading: false, // 戻るボタンを非表示にする
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.5,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/castle.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      return Image.asset(
                        _imagePaths[index],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                _buildTextField(_messageController, 'どんなコースを希望しますか？'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB0C4DE),
                    foregroundColor: Color(0xFF003366),
                    side: BorderSide(color: Color(0xFF4F81BD)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text('メッセージを送信'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _navigateBackToMainScreen, // 戻るボタンを押すとmain_screenに戻る
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB0C4DE),
                  ),
                  child: Text('戻る'),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF4F81BD)),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4F81BD)),
        ),
      ),
      keyboardType: TextInputType.multiline,
      maxLines: null,
    );
  }
}
