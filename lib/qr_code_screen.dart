import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeScreen extends StatefulWidget {
  final int eventId;
  final String memberId;
  final String eventTitle;
  final String eventDescription;
  final String eventLocation;
  final String eventStartTime;
  final String eventEndTime;

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
      await Future.delayed(const Duration(milliseconds: 500));

      RenderRepaintBoundary? boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('RenderBoundary is null');
        return null;
      }

      ui.Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing QR code: $e');
      return null;
    }
  }

  Future<void> _downloadQrCode(BuildContext context) async {
    Uint8List? imageBytes = await _captureQrCode();

    if (imageBytes != null) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/qr_code.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      //   bool? success = await GallerySaver.saveImage(file.path);
      //   if (success == true) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('QR code saved to gallery')),
      //     );
      //   } else {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('Failed to save QR code')),
      //     );
      //   }
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Failed to capture QR code')),
      //   );
    }
  }

  Future<void> _shareQrCode(BuildContext context) async {
    Uint8List? imageBytes = await _captureQrCode();

    if (imageBytes != null) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/qr_code.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Check out my event QR code!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture QR code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData = '${widget.eventId}/${widget.memberId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventTitle),
        actions: [
          // Commented out the share button
          // IconButton(
          //   icon: const Icon(Icons.share),
          //   onPressed: () => _shareQrCode(context),
          // ),
          // Commented out the download button
          // IconButton(
          //   icon: const Icon(Icons.download),
          //   onPressed: () => _downloadQrCode(context),
          // ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.eventDescription,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Location: ${widget.eventLocation}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              'Start: ${_formatDate(widget.eventStartTime)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'End: ${_formatDate(widget.eventEndTime)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:$minute';
  }
}