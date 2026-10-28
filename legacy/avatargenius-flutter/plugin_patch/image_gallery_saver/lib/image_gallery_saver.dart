import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class ImageGallerySaver {
  static const MethodChannel _channel = MethodChannel('image_gallery_saver');

  /// Save image to gallery
  ///
  /// [imageBytes] is the image data as bytes
  /// [quality] is the quality of the image, from 0-100
  /// [name] is the name of the image, if null, a random name will be generated
  static Future<dynamic> saveImage(
    Uint8List imageBytes, {
    int quality = 80,
    String? name,
  }) async {
    final result = await _channel.invokeMethod(
      'saveImageToGallery',
      <String, dynamic>{
        'imageBytes': imageBytes,
        'quality': quality,
        'name': name,
      },
    );
    return result;
  }

  /// Save file to gallery
  ///
  /// [file] is the path of the file to save
  /// [name] is the name of the file, if null, the original name will be used
  static Future<dynamic> saveFile(String file, {String? name}) async {
    final result = await _channel.invokeMethod(
      'saveFileToGallery',
      <String, dynamic>{
        'file': file,
        'name': name,
      },
    );
    return result;
  }
}