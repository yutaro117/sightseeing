import 'package:flutter/material.dart';
import 'dart:async'; // Timerを使用するために追加
import 'dart:convert'; // JSONを扱うために追加
import 'package:http/http.dart' as http; // HTTPリクエストを扱うために追加

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _loginMessage = '';
  int? userId; // ログインしたユーザID
  String? userName; // ユーザー名 

  // 広告画像のリスト
  final List<String> adImages = [
    'assets/mountain.jpeg',
    'assets/restaurant.jpeg',
    'assets/shrine.png',
    'assets/sweetShop.jpg',
  ];

  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // 5秒ごとに画像を自動で切り替えるタイマーの設定
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_currentPage < adImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds:1500),
        curve: Curves.easeIn,
      );
    });
  }

  // ログイン処理
  Future<void> _login() async {
    String enteredId = _idController.text;
    String enteredPassword = _passwordController.text;

    if (enteredId.isEmpty || enteredPassword.isEmpty) {
      setState(() {
        _loginMessage = 'ユーザIDとパスワードを入力してください。';
      });
      return;
    }

    // APIリクエストを作成
    final response = await http.get(Uri.parse(
      'https://c8zv1lq2pe.execute-api.ap-northeast-1.amazonaws.com/QR/login?user_id=$enteredId&user_pass=$enteredPassword',
    ));

    // レスポンスボディを出力して確認
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        // サーバーからのレスポンスをUTF-8でデコード
        final String responseBody = utf8.decode(response.bodyBytes);
        // JSON形式に変換
        final String jsonResponse = json.decode(responseBody);
        
        // ユーザー名を取得
        userName = jsonResponse; // 正しいキーを使用する

        setState(() {
          _loginMessage = 'ログイン成功!';
          userId = int.parse(enteredId); // ユーザIDを保存
        });

        // メイン画面にユーザID、ユーザー名を渡して遷移
        Navigator.pushReplacementNamed(
          context,
          '/main',
          arguments: {
            'userId': userId,
            'user_name': userName, // user_name のキーを統一
          },
        );
      } catch (e) {
        print('JSONデコードエラー: $e');
        setState(() {
          _loginMessage = 'サーバーからのレスポンスが不正です。${response.statusCode}';
        });
      }
    } else {
      setState(() {
        _loginMessage = 'ログインに失敗しました。エラーコード: ${response.statusCode}';
      });
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ログイン'),
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
                  image: AssetImage('assets/castle.png'), // 背景画像を設定
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildTextField(_idController, 'ユーザID'),
                      SizedBox(height: 16),
                      _buildTextField(_passwordController, 'パスワード', isPassword: true),
                      SizedBox(height: 16),
                      _buildLoginButton(),
                      SizedBox(height: 16),
                      _buildMessageText(),
                    ],
                  ),
                ),
              ),
              _buildAdBanner(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdBanner() {
    return Container(
      height: 100, // 広告バナーの高さ
      child: PageView.builder(
        controller: _pageController,
        itemCount: adImages.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(adImages[index]), // 画像を表示
                fit: BoxFit.cover,
              ),
            ),
          );
        },
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
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFB0C4DE),
        foregroundColor: Color(0xFF003366),
        side: BorderSide(color: Color(0xFF4F81BD)),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text('ログイン',
                        style: TextStyle(
                          fontSize: 20, // フォントサイズを大きく指定
                        ),),
    );
  }

  Widget _buildMessageText() {
    return Text(
      _loginMessage,
      style: TextStyle(
        color: _loginMessage == 'ログイン成功!' ? Colors.green : Colors.red,
        fontSize: 16,
      ),
    );
  }
}
