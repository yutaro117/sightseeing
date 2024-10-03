import 'package:flutter/material.dart';
import 'package:kadai_list/text_message_screen.dart';
import 'login.dart';
import 'main_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Stack(
        children: [
          // 背景画像を設定
          Opacity(
            opacity: 0.5, // 画像を薄く表示（0.0から1.0の範囲）
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/castle.png'), // 背景画像を設定
                  fit: BoxFit.cover, // 画像を全体にフィットさせる
                ),
              ),
            ),
          ),
          // メインコンテンツの表示
          LoginScreen(),
          //TextMessageScreen(),
        ],
      ),
      // 遷移のルートを設定 
      routes: {
        '/main': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          final userId = arguments['userId'] as int; // userIdを取得
          final userName = arguments['user_name'] as String; // userNameを取得

          return MainScreen(
            userId: userId,
            userName: userName, // userNameを渡す
          );
        },
      },
    );
  }
}
