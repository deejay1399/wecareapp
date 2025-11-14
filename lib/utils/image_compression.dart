import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompression {
  static Future<Uint8List> compressImage(
    Uint8List bytes, {
    int maxWidth = 1280,
    int quality = 75,
  }) async {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minHeight: maxWidth,
      minWidth: maxWidth,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    return Uint8List.fromList(compressed);
  }
}
