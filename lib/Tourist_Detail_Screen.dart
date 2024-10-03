import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TouristDetailScreen extends StatefulWidget {
  final String touristSpot;
  final int tourId; // 観光地IDを追加

  const TouristDetailScreen({
    Key? key,
    required this.touristSpot,
    required this.tourId, // 観光地IDを受け取る
  }) : super(key: key);

  @override
  _TouristDetailScreenState createState() => _TouristDetailScreenState();
}

class _TouristDetailScreenState extends State<TouristDetailScreen> {
  int? visitCount; // 訪問数を格納する変数
  bool isLoading = false; // ローディング状態の管理 
  String errorMessage = ''; // エラーメッセージの管理

  @override
  void initState() {
    super.initState();
    _fetchVisitCount(); // 画面が表示されるときに訪問数を取得
  }

  Future<void> _fetchVisitCount() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    // 今日の日付を取得 (yyyyMMdd形式)
    int today = 20240930;
    String date = '20240930';

    try {
      String url =
          'https://c8zv1lq2pe.execute-api.ap-northeast-1.amazonaws.com/QR/getQRCount?tour_id=${widget.tourId}&date=$date';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          visitCount = data['count'];
        });
      } else {
        setState(() {
          errorMessage = 'データの取得に失敗しました。';
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'エラーが発生しました: $error';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.touristSpot}の詳細'),
        backgroundColor: Color(0xFF4F81BD),
        automaticallyImplyLeading: false, // 戻るボタンを非表示にする
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '観光地名: ${widget.touristSpot}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Text(errorMessage, style: TextStyle(color: Colors.red))
            else if (visitCount != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('先週の訪問者数: $visitCount', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 16), // ボタンとテキストの間隔を調整
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // 前のページに戻る
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4F81BD), // ボタンの背景色を設定
                        foregroundColor: Colors.white, // ボタンのテキスト色を設定
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      ),
                    child: Text('戻る',
                        style: TextStyle(
                          fontSize: 20, // フォントサイズを大きく指定
                        ),
                        ), // ボタンのテキスト
                  ),
                ],
              )
            else
              Text('データがありません。', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

