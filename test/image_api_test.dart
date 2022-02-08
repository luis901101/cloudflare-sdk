import 'dart:io';

import 'package:cloudflare/cloudflare.dart';
import 'package:cloudflare/src/base_api/c_response.dart';
import 'package:cloudflare/src/model/data_transmit.dart';
import 'package:test/test.dart';

import 'base_tests.dart';
import 'utils/matchers.dart';

void main() async {

  await init();

  group('Retrieve image tests', () {
    late final CResponse<List<CloudflareImage>?> responseList;
    String? imageId;
    setUpAll(() async {
      responseList = await cloudflare.imageAPI.getAll(page: 1, size: 20);
    });

    test('Get image list', () async {
      expect(responseList, ResponseMatcher());
      expect(responseList.body, isNotNull);
      expect(responseList.body, isNotEmpty);
      imageId = responseList.body![0].id;
    });

    test('Get image byId', () async {
      if(imageId == null) {
        // markTestSkipped('Get image byId skipped: No image available to get by Id');
        throw Exception('No image available to get by Id');
      }
      final response = await cloudflare.imageAPI.get(id: imageId!);
      expect(response, ImageMatcher());
    });

    test('Get base image byId', () async {
      if(imageId == null) {
        throw Exception('No base image available to get by Id');
      }
      final response = await cloudflare.imageAPI.getBase(id: imageId!);
      expect(response, ResponseMatcher());
      expect(response.body, isNotNull);
    });
  });

  group('Upload image tests', () {
    late final File imageFile, imageFile1, imageFile2;
    setUpAll(() async {
      imageFile = File(Platform.environment['CLOUDFLARE_IMAGE_FILE'] ?? '');
      imageFile1 = File(Platform.environment['CLOUDFLARE_IMAGE_FILE_1'] ?? '');
      imageFile2 = File(Platform.environment['CLOUDFLARE_IMAGE_FILE_2'] ?? '');
    });

    test('Simple upload image from file', () async {
      if(!imageFile.existsSync()) {
        throw Exception('No image file available to upload');
      }
      final response = await cloudflare.imageAPI.uploadFromFile(
        content: DataTransmit<File>(data: imageFile)
      );
      expect(response, ImageMatcher());
    });

    test('Simple upload image from file with progress update', () async {
      if(!imageFile.existsSync()) {
        throw Exception('No image file available to upload');
      }
      final response = await cloudflare.imageAPI.uploadFromFile(
        content: DataTransmit<File>(data: imageFile, progressCallback: (count, total) {
          print('Simple upload image from file progress: $count/$total');
        })
      );
      expect(response, ImageMatcher());
    });

    test('Multiple upload image from file with progress update', () async {
      if(!imageFile.existsSync() || !imageFile1.existsSync() || !imageFile2.existsSync()) {
        throw Exception('imageFile and imageFile1 and imageFile2 are required for multiple upload test. Check if you set each image file for each env var.');
      }
      final files = [imageFile, imageFile1, imageFile2];
      List<DataTransmit<File>> contents = [];
      for (final file in files) {
        contents.add(DataTransmit(data: file, progressCallback: (count, total) {
          final split = file.path.split(Platform.pathSeparator);
          String? filename = split.isNotEmpty ? split.last : null;
          print('Multiple upload image from file: $filename progress: $count/$total');
        }));
      }
      final responses = await cloudflare.imageAPI.uploadFromFiles(
        contents: contents,
      );
      for (final response in responses) {
        expect(response, ImageMatcher());
      }
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Upload image with requireSignedURLs and metadata', () async {
      if(!imageFile.existsSync()) {
        throw Exception('No image file available to upload');
      }
      final metadata = {
        'system_id': "image-test-system-id'",
        'description': 'This is an image test',
      };
      final response = await cloudflare.imageAPI.uploadFromFile(
        content: DataTransmit<File>(data: imageFile),
        requireSignedURLs: true,
        metadata: metadata,
      );
      expect(response, ImageMatcher());
      expect(response.body!.requireSignedURLs, true);
      expect(response.body!.meta, metadata);
    });
  });

  group('Update/Delete image tests', () {
    late final File imageFile;
    String? imageId;
    final metadata = {
      'system_id': "image-test-system-id'",
      'description': 'This is an image test',
    };
    setUpAll(() async {
      imageFile = File(Platform.environment['CLOUDFLARE_IMAGE_FILE'] ?? '');
      final response = await cloudflare.imageAPI.uploadFromFile(
        content: DataTransmit<File>(data: imageFile),
        // requireSignedURLs: true,
        metadata: metadata,

      );
      imageId = response.body?.id;
    });

    test('Update image', () async {
      if(imageId == null) {
        throw Exception('No image available to update');
      }
      metadata['system_id'] = '${metadata['system_id']}-updated';
      metadata['description'] = '${metadata['description']}-updated';
      final response = await cloudflare.imageAPI.update(
        id: imageId!,
        // requireSignedURLs: false,
        metadata: metadata,
      );
      expect(response, ImageMatcher());
      // expect(response.body!.requireSignedURLs, false);
      expect(response.body!.meta, metadata);
    });

    test('Delete image', () async {
      if(imageId == null) {
        throw Exception('No image available to delete');
      }
      final response = await cloudflare.imageAPI.delete(
        id: imageId!,
      );
      expect(response, ResponseMatcher());
    });
  });
}
