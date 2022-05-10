import 'dart:io';

import 'package:cloudflare/cloudflare.dart';
import 'package:cloudflare/src/entity/data_upload_draft.dart';
import 'package:test/test.dart';

import 'base_tests.dart';
import 'utils/matchers.dart';

/// ImageAPI tests on each Cloudflare Image API endpoint.
/// These tests ensures that every uploaded test image gets deleted.
void main() async {
  await init();
  final File imageFile = File(Platform.environment['CLOUDFLARE_IMAGE_FILE'] ?? ''),
      imageFile1 = File(Platform.environment['CLOUDFLARE_IMAGE_FILE_1'] ?? ''),
      imageFile2 = File(Platform.environment['CLOUDFLARE_IMAGE_FILE_2'] ?? '');
  final String imageUrl = Platform.environment['CLOUDFLARE_IMAGE_URL'] ?? '';
  Set<String> imageIds = {};

  void addId(String? id) {
    if(id != null) imageIds.add(id);
  }

  test('Handling image from url tests', (){
    final image1 = CloudflareImage.fromUrl('https://imagedelivery.net/c3ymt7v4gt5cifhjdsf/af771366-b3bb-4570-8e33-e10c8544ce00/thumbnail');
    final image2 = CloudflareImage.fromUrl('https://imagedelivery.net/c3ymt7v4gt5cifhjdsf/af771366-b3bb-4570-8e33-e10c8544ce00/public');
    final image3 = CloudflareImage.fromUrl('https://imagedelivery.net/c3ymt7v4gt5cifhjdsf/af771366-b3bb-4570-8e33-e10c8544ce00/');
    final image4 = CloudflareImage.fromUrl('https://imagedelivery.net/c3ymt7v4gt5cifhjdsf/af771366-b3bb-4570-8e33-e10c8544ce00');
    final image5 = CloudflareImage.fromUrl('https://upload.imagedelivery.net/c3ymt7v4gt5cifhjdsf/af771366-b3bb-4570-8e33-e10c8544ce00');
    final image6 = CloudflareImage(id: 'm3xgriuradsz3ed23', imageDeliveryId: '4m5x3gt2o5htuergn');
    final image7 = CloudflareImage();
    expect(image1.firstVariant, isNotEmpty);
    expect(image2.firstVariant, isNotEmpty);
    expect(image3.firstVariant, isNotEmpty);
    expect(image4.firstVariant, isNotEmpty);
    expect(image5.firstVariant, isNotEmpty);
    expect(image6.firstVariant, isNotEmpty);
    expect(image7.firstVariant, isEmpty);
  });

  group('Upload image tests', () {

    test('Simple upload image from file with progress update', () async {
      if (!imageFile.existsSync()) {
        fail('No image file available to upload');
      }
      final response = await cloudflare.imageAPI.upload(
          contentFromFile: DataTransmit<File>(
              data: imageFile,
              progressCallback: (count, total) {
                final split = imageFile.path.split(Platform.pathSeparator);
                String? filename = split.isNotEmpty ? split.last : null;
                print('Simple upload image: $filename from file progress: $count/$total');
              }));
      expect(response, ImageMatcher());
      addId(response.body?.id);
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Simple upload image from path with progress update', () async {
      if (!imageFile.existsSync()) {
        fail('No image path available to upload');
      }
      final response = await cloudflare.imageAPI.upload(
          contentFromPath: DataTransmit<String>(
              data: imageFile.path,
              progressCallback: (count, total) {
                final split = imageFile.path.split(Platform.pathSeparator);
                String? filename = split.isNotEmpty ? split.last : null;
                print('Simple upload image: $filename from path progress: $count/$total');
              }));
      expect(response, ImageMatcher());
      addId(response.body?.id);
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Simple upload image from bytes with progress update', () async {
      if (!imageFile.existsSync()) {
        fail('No image bytes available to upload');
      }
      final response = await cloudflare.imageAPI.upload(
          contentFromBytes: DataTransmit<List<int>>(
              data: imageFile.readAsBytesSync(),
              progressCallback: (count, total) {
                final split = imageFile.path.split(Platform.pathSeparator);
                String? filename = split.isNotEmpty ? split.last : null;
                print('Simple upload image: $filename from bytes progress: $count/$total');
              }));
      expect(response, ImageMatcher());
      addId(response.body?.id);
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Simple upload image from url with progress update', () async {
      if (imageUrl.isEmpty) {
        fail('No image url available to upload');
      }
      final response = await cloudflare.imageAPI.upload(
          contentFromUrl: DataTransmit<String>(
              data: imageUrl,
              progressCallback: (count, total) {
                print('Simple upload image from url: $imageUrl progress: $count/$total');
              }));
      expect(response, ImageMatcher());
      addId(response.body?.id);
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Multiple upload image from file with progress update', () async {
      if (!imageFile.existsSync() ||
          !imageFile1.existsSync() ||
          !imageFile2.existsSync()) {
        fail(
            'imageFile and imageFile1 and imageFile2 are required for multiple upload test. Check if you set each image file for each env var.');
      }
      final files = [imageFile, imageFile1, imageFile2];
      List<DataTransmit<File>> contents = [];
      for (final file in files) {
        contents.add(DataTransmit<File>(
            data: file,
            progressCallback: (count, total) {
              final split = file.path.split(Platform.pathSeparator);
              String? filename = split.isNotEmpty ? split.last : null;
              print(
                  'Multiple upload image from file: $filename progress: $count/$total');
            }));
      }
      final responses = await cloudflare.imageAPI.uploadMultiple(
        contentFromFiles: contents,
      );
      for (final response in responses) {
        expect(response, ImageMatcher());
        addId(response.body?.id);
      }
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Multiple upload image from path with progress update', () async {
      if (!imageFile.existsSync() ||
          !imageFile1.existsSync() ||
          !imageFile2.existsSync()) {
        fail(
            'imageFile and imageFile1 and imageFile2 are required for multiple upload test. Check if you set each image file for each env var.');
      }
      final paths = [imageFile.path, imageFile1.path, imageFile2.path];
      List<DataTransmit<String>> contents = [];
      for (final path in paths) {
        contents.add(DataTransmit<String>(
            data: path,
            progressCallback: (count, total) {
              final split = path.split(Platform.pathSeparator);
              String? filename = split.isNotEmpty ? split.last : null;
              print(
                  'Multiple upload image from path: $filename progress: $count/$total');
            }));
      }
      final responses = await cloudflare.imageAPI.uploadMultiple(
        contentFromPaths: contents,
      );
      for (final response in responses) {
        expect(response, ImageMatcher());
        addId(response.body?.id);
      }
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Multiple upload image from bytes with progress update', () async {
      if (!imageFile.existsSync() ||
          !imageFile1.existsSync() ||
          !imageFile2.existsSync()) {
        fail(
            'imageFile and imageFile1 and imageFile2 are required for multiple upload test. Check if you set each image file for each env var.');
      }
      final files = [imageFile, imageFile1, imageFile2];
      List<DataTransmit<List<int>>> contents = [];
      for (final file in files) {
        contents.add(DataTransmit<List<int>>(
            data: file.readAsBytesSync(),
            progressCallback: (count, total) {
              final split = file.path.split(Platform.pathSeparator);
              String? filename = split.isNotEmpty ? split.last : null;
              print(
                  'Multiple upload image from bytes: $filename progress: $count/$total');
            }));
      }
      final responses = await cloudflare.imageAPI.uploadMultiple(
        contentFromBytes: contents,
      );
      for (final response in responses) {
        expect(response, ImageMatcher());
        addId(response.body?.id);
      }
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Multiple upload image from url with progress update', () async {
      if (imageUrl.isEmpty) {
        fail(
            'imageUrl is required for multiple upload test. Check if you set imageUrl in the env vars.');
      }
      final urls = [imageUrl, imageUrl, imageUrl];
      List<DataTransmit<String>> contents = [];
      for (final url in urls) {
        contents.add(DataTransmit<String>(
            data: url,
            progressCallback: (count, total) {
              print(
                  'Multiple upload image from url: $url progress: $count/$total');
            }));
      }
      final responses = await cloudflare.imageAPI.uploadMultiple(
        contentFromUrls: contents,
      );
      for (final response in responses) {
        expect(response, ImageMatcher());
        addId(response.body?.id);
      }
    }, timeout: Timeout(Duration(minutes: 2)));

    test('Upload image with requireSignedURLs and metadata', () async {
      if (!imageFile.existsSync()) {
        fail('No image file available to upload');
      }
      final metadata = {
        'system_id': "image-test-system-id'",
        'description': 'This is an image test',
      };
      final response = await cloudflare.imageAPI.upload(
        contentFromFile: DataTransmit<File>(data: imageFile),
        requireSignedURLs: true,
        metadata: metadata,
      );
      expect(response, ImageMatcher());
      expect(response.body!.requireSignedURLs, true);
      expect(response.body!.meta, metadata);
      addId(response.body?.id);
    }, timeout: Timeout(Duration(minutes: 2)));

    group('Image direct upload tests', () {
      late final CloudflareHTTPResponse<DataUploadDraft?> response;
      late final String? imageId;
      late final String? uploadURL;

      setUpAll(() async {
        response = await cloudflare.imageAPI.createDirectUpload();
        imageId = response.body?.id;
        uploadURL = response.body?.uploadURL;
      });

      test('Create authenticated direct image upload URL', () async {
        expect(response, ResponseMatcher());
        expect(response.body?.id, isNotEmpty);
        expect(response.body?.uploadURL, isNotEmpty);
      });

      test('Check created image draft status', () async {
        if (imageId?.isEmpty ?? true) {
          fail('No imageId available to check draft status');
        }
        final response = await cloudflare.imageAPI.get(id: imageId);
        expect(response, ImageMatcher());
        expect(response.body?.draft, true);
      }, timeout: Timeout(Duration(minutes: 2)));

      test('Doing image upload to direct upload URL', () async {
        if (uploadURL?.isEmpty ?? true) {
          fail('No uploadURL available to upload to');
        }
        final response = await cloudflare.imageAPI.directUpload(
          uploadURL: uploadURL!,
          contentFromFile: DataTransmit<File>(
            data: imageFile,
            progressCallback: (count, total) {
              print('Image upload to direct upload URL from file progress: $count/$total');
            })
        );
        expect(response, ImageMatcher());
        addId(response.body?.id);
        expect(response.body?.id, imageId);
        expect(response.body?.draft, false);
      }, timeout: Timeout(Duration(minutes: 2)));
    });
  });

  test('Get image usage statistics', () async {
    final response = await cloudflare.imageAPI.getStats();
    expect(response, ResponseMatcher());
    print('Stats: ${response.body?.toJson()}');
  });

  group('Retrieve image tests', () {
    late final CloudflareHTTPResponse<List<CloudflareImage>?> responseList;
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
      if (imageId == null) {
        // markTestSkipped('Get image byId skipped: No image available to get by Id');
        fail('No image available to get by Id');
      }
      final response = await cloudflare.imageAPI.get(id: imageId!);
      expect(response, ImageMatcher());
    });

    test('Get base image byId', () async {
      if (imageId == null) {
        fail('No base image available to get by Id');
      }
      final response = await cloudflare.imageAPI.getBase(id: imageId!);
      expect(response, ResponseMatcher());
      expect(response.body, isNotNull);
    });
  });

  group('Update image tests', () {
    String? imageId;
    final metadata = {
      'system_id': "image-test-system-id'",
      'description': 'This is an image test',
    };
    setUpAll(() async {
      final response = await cloudflare.imageAPI.upload(
        contentFromFile: DataTransmit<File>(data: imageFile),
        requireSignedURLs: true,
        metadata: metadata,
      );
      imageId = response.body?.id;
      addId(imageId);
    });

    test('Update image', () async {
      if (imageId == null) {
        fail('No image available to update');
      }
      metadata['system_id'] = '${metadata['system_id']}-updated';
      metadata['description'] = '${metadata['description']}-updated';
      final response = await cloudflare.imageAPI.update(
        id: imageId!,
        requireSignedURLs: false,
        metadata: metadata,
      );
      expect(response, ImageMatcher());
      imageIds.remove(imageId);//After image updated the imageId changes
      addId(response.body?.id);
      expect(response.body!.requireSignedURLs, false);
      expect(response.body!.meta, metadata);
    });
  });

  test('Delete image test', () async {
    final imageId = imageIds.isNotEmpty ? imageIds.first : null;
    if (imageId == null) {
      fail('No image available to delete');
    }
    final response = await cloudflare.imageAPI.delete(
      id: imageId,
    );
    expect(response, ResponseMatcher());
    imageIds.remove(imageId);
  });
  
  test('Delete multiple images', () async {
    /// This code below is not part of the tests and should remain commented, be careful.
    // final responseList = await cloudflare.imageAPI.getAll(page: 1, size: 20);
    // if(responseList.isSuccessful && (responseList.body?.isNotEmpty ?? false)) {
    //   imageIds = responseList.body!.map((e) => e.id).toSet();
    // }

    if (imageIds.isEmpty) {
      fail('There are no uploaded images to test multi delete.');
    }

    final responses = await cloudflare.imageAPI.deleteMultiple(
      ids: imageIds.toList(),
    );
    int deleted = responses.where((response) => response.isSuccessful).length;
    print('Deleted: $deleted of ${imageIds.length}');
    for (final response in responses) {
      expect(response, ResponseMatcher());
    }
  }, timeout: Timeout(Duration(minutes: 10)));
}
