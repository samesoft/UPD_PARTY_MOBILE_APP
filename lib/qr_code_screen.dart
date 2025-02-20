import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeScreen extends StatefulWidget {
  final int eventId;
  final String memberId, eventTitle, eventDescription, eventLocation, eventStartTime, eventEndTime;

  const QrCodeScreen({
    super.key,
    required this.eventId,
    required this.memberId,
    required this.eventTitle,
    required this.eventDescription,
    required this.eventLocation,
    required this.eventStartTime,
    required this.eventEndTime,
  });

  @override
  _QrCodeScreenState createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  final GlobalKey _qrKey = GlobalKey();

  Future<Uint8List?> _captureQrCode() async {
    try {
      debugPrint('Starting capture process...');

      // Wait for the widget to be fully rendered
      await Future.delayed(const Duration(milliseconds: 1000));
      await SchedulerBinding.instance.endOfFrame;

      if (_qrKey.currentContext == null) {
        debugPrint('Invalid context: _qrKey.currentContext is null');
        _showError('Failed to capture QR code: Invalid context');
        return null;
      }

      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Check if the boundary is ready to be painted
      if (boundary.debugNeedsPaint) {
        debugPrint('Boundary not ready yet, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('ByteData is null. Failed to convert image to bytes.');
        _showError('Failed to capture QR code.');
        return null;
      }

      debugPrint('Image captured successfully.');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR code: $e');
      _showError('Failed to capture QR code: $e');
      return null;
    }
  }

  Future<void> _saveQrCode() async {
    try {
      Uint8List? pngBytes = await _captureQrCode();
      if (pngBytes == null) return;

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showError('Failed to access external storage.');
        return;
      }

      final imagePath = '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(imagePath).writeAsBytes(pngBytes);
      _showSuccess('QR code saved to $imagePath');
    } catch (e) {
      debugPrint('Error saving QR code: $e');
      _showError('Failed to save QR code.');
    }
  }

  Future<void> _shareQrCode() async {
    try {
      Uint8List? pngBytes = await _captureQrCode();
      if (pngBytes == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(imagePath).writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Check out my event QR code!',
        subject: 'UPD events',
      );
      debugPrint('Share process completed successfully.');
    } catch (e) {
      debugPrint('Error sharing QR code: $e');
      _showError('Failed to share QR code.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventTitle),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareQrCode),
          IconButton(icon: const Icon(Icons.download), onPressed: _saveQrCode),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  child: QrImageView(
                    data: '${widget.eventId}/${widget.memberId}',
                    version: QrVersions.auto,
                    size: 200,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.eventDescription, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Location: ${widget.eventLocation}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 10),
            Text('Start: ${_formatDate(widget.eventStartTime)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('End: ${_formatDate(widget.eventEndTime)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}