import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'tourist_list_screen.dart'; // TouristListScreenのインポート
import 'package:http/http.dart' as http; // HTTP通信のためにインポート
import 'dart:convert';

class QRCodeCameraScreen extends StatefulWidget {
  final int userId; // ユーザID
  final String userName; // ユーザ名前
  final List<int> visitedTourIdList; // 訪問済み観光地IDのリスト
  final List<int> plannedTourIdList; // 訪問予定観光地IDのリスト

  const QRCodeCameraScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.visitedTourIdList, // 訪問済み観光地IDリストを受け取る
    required this.plannedTourIdList, // 訪問予定観光地IDリストを受け取る
  }) : super(key: key);

  @override
  _QRCodeCameraScreenState createState() => _QRCodeCameraScreenState();
}

class _QRCodeCameraScreenState extends State<QRCodeCameraScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isTorchOn = false; // フラッシュの状態を手動で管理
  bool isScanning = true; // QRコードのスキャンを制御するフラグ 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        actions: [
          IconButton(
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
            iconSize: 32.0,
            onPressed: () {
              setState(() {
                isTorchOn = !isTorchOn;
                cameraController.toggleTorch(); // フラッシュの切り替え
              });
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (isScanning) { // スキャン中の場合のみ処理
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              debugPrint('Barcode found! ${barcode.rawValue}');
              final int? tourId = int.tryParse(barcode.rawValue ?? '');

              if (tourId != null) {
                // QRコードに観光地IDがある場合
                _incrementQRCount(tourId, widget.userId); //訪問数を更新

                // 観光地IDが訪問済みリストに含まれていない場合、追加
                if (!widget.visitedTourIdList.contains(tourId)) {
                  widget.visitedTourIdList.add(tourId); // 新しい観光地IDを追加
                }

                setState(() {
                  isScanning = false; // スキャンを停止
                });

                // TouristListScreenに訪問済みと訪問予定のリストを渡す
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TouristListScreen(
                      visitedTourIdList: widget.visitedTourIdList,
                      plannedTourIdList: widget.plannedTourIdList,
                      userId: widget.userId, // ユーザIDも渡す
                      userName: widget.userName,
                    ),
                  ),
                );
              } else {
                // QRコードが無効な場合の処理
                _showInvalidQRCodeDialog();
              }
            }
          }
        },
      ),
    );
  }

  Future<void> _incrementQRCount(int tourId, int userId) async {
    DateTime now = DateTime.now();
    String formattedDate = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final response = await http.get(
      Uri.parse('https://c8zv1lq2pe.execute-api.ap-northeast-1.amazonaws.com/QR/incQRcount?tour_id=$tourId&date=$formattedDate&user_id=$userId'),
    );

    if (response.statusCode == 200) {
      // 成功した場合の処理
      print("Visit count incremented successfully.");
    } else {
      // エラーハンドリング
      print("Failed to increment visit count.");
    }
  }

  void _showInvalidQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid QR Code'),
        content: const Text('The QR code does not contain a valid tourist spot ID.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose(); // コントローラの解放
    super.dispose();
  }
}

