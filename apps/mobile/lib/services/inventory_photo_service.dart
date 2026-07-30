import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

enum InventoryPhotoFailure {
  cameraDenied,
  cameraUnavailable,
  imageTooLarge,
  captureFailed,
}

class InventoryPhotoException implements Exception {
  const InventoryPhotoException(this.failure);

  final InventoryPhotoFailure failure;
}

abstract interface class InventoryPhotoCapture {
  Future<Uint8List?> capture();
}

class DeviceInventoryPhotoCapture implements InventoryPhotoCapture {
  DeviceInventoryPhotoCapture({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  static const maxStoredBytes = 4 * 1024 * 1024;

  final ImagePicker _picker;

  @override
  Future<Uint8List?> capture() async {
    XFile? photo;
    try {
      photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
        requestFullMetadata: false,
      );
      if (photo == null) return null;
      final bytes = await photo.readAsBytes();
      if (bytes.lengthInBytes > maxStoredBytes) {
        throw const InventoryPhotoException(
          InventoryPhotoFailure.imageTooLarge,
        );
      }
      return bytes;
    } on InventoryPhotoException {
      rethrow;
    } on PlatformException catch (error) {
      if (error.code == 'camera_access_denied' ||
          error.code == 'camera_access_restricted') {
        throw const InventoryPhotoException(InventoryPhotoFailure.cameraDenied);
      }
      if (error.code == 'camera_unavailable') {
        throw const InventoryPhotoException(
          InventoryPhotoFailure.cameraUnavailable,
        );
      }
      throw const InventoryPhotoException(InventoryPhotoFailure.captureFailed);
    } on MissingPluginException {
      throw const InventoryPhotoException(
        InventoryPhotoFailure.cameraUnavailable,
      );
    } finally {
      final photoPath = photo?.path;
      if (photoPath != null) {
        try {
          final file = File(photoPath);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // The picker cache may already have removed the temporary capture.
        }
      }
    }
  }
}
