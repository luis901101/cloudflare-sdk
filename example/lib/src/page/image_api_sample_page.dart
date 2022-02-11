import 'dart:async';
import 'dart:io';
import 'package:cloudflare/cloudflare.dart';
import 'package:cloudflare_example/main.dart';
import 'package:cloudflare_example/src/utils/alert_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloudflare_example/src/utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';

class ImageAPIDemoPage extends StatefulWidget {
  const ImageAPIDemoPage({Key? key}) : super(key: key);

  @override
  _ImageAPIDemoPageState createState() => _ImageAPIDemoPageState();
}

enum FileSource {
  path,
  bytes,
}

class _ImageAPIDemoPageState extends State<ImageAPIDemoPage> {
  //Change this values with your own
  static const int loadImage = 1;
  static const int uploadImages = 2;
  static const int deleteUploadedImages = 3;
  List<String> pathImages = [];
  List<CloudflareImage> cloudflareImages = [];
  bool loading = false;
  String? errorMessage;
  FileSource fileSource = FileSource.path;

  @override
  void initState() {
    super.initState();
  }

  void onUploadSourceChanged(FileSource? value) => setState(() => fileSource = value!);

  Widget get uploadSourceView => Column(
    children: [
      const Text("File source"),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: RadioListTile<FileSource>(
                title: const Text("Path"),
                value: FileSource.path,
                groupValue: fileSource,
                onChanged: onUploadSourceChanged),
          ),
          SizedBox(
            width: 150,
            child: RadioListTile<FileSource>(
                title: const Text("Bytes"),
                value: FileSource.bytes,
                groupValue: fileSource,
                onChanged: onUploadSourceChanged),
          ),
        ],
      )
    ],
  );

  Widget imageFromPathView(String path) {
    return Image.file(
      File(path),
      width: 100,
      height: 100,
    );
  }

  Widget imageFromUrlView(CloudflareImage image) {
    return Image.network(
      image.baseUrl,
      width: 100,
      height: 100,
    );
  }

  Widget imageGalleryView({
    bool fromPath = true,
  }) {
    List imagesSource = fromPath ? pathImages : cloudflareImages;

    final imageViews = List.generate(imagesSource.length, (index) {
      final source = imagesSource[index];
      return fromPath ? imageFromPathView(source) : imageFromUrlView(source);
    });

    if(loading && !fromPath) {
      imageViews.add(
        const Center(child: CircularProgressIndicator(),)
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: imageViews,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image API Demo'),
      ),
      body: Center(
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 16),
                const Text(
                  'Images from file',
                ),
                const SizedBox(
                  height: 16,
                ),
                imageGalleryView(fromPath: true),
                ElevatedButton(
                  onPressed: loading || pathImages.isEmpty
                      ? null
                      : () {
                    pathImages = [];
                    setState(() {});
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                          return states.contains(MaterialState.disabled)
                              ? null
                              : Colors.deepPurple;
                        }),
                  ),
                  child: const Text(
                    'Clear list',
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(
                  height: 48,
                ),
                const Text(
                  'Images from cloudflare',
                ),
                const SizedBox(
                  height: 16,
                ),
                imageGalleryView(fromPath: false),
                const SizedBox(
                  height: 32,
                ),
                Visibility(
                    visible: errorMessage?.isNotEmpty ?? false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$errorMessage",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18, color: Colors.red.shade900),
                        ),
                        const SizedBox(
                          height: 128,
                        ),
                      ],
                    )),
                ElevatedButton(
                  onPressed: loading || cloudflareImages.isEmpty
                      ? null
                      : () {
                    cloudflareImages = [];
                    setState(() {});
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                          return states.contains(MaterialState.disabled)
                              ? null
                              : Colors.purple;
                        }),
                  ),
                  child: const Text(
                    'Clear list',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                uploadSourceView,
                const SizedBox(
                  height: 32,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading ||
                              (pathImages.isEmpty && cloudflareImages.isEmpty)
                              ? null
                              : () {
                            pathImages = [];
                            cloudflareImages = [];
                            setState(() {});
                          },
                          style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                  return states.contains(MaterialState.disabled)
                                      ? null
                                      : Colors.deepOrange;
                                }),
                          ),
                          child: const Text(
                            'Clear all',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading || pathImages.isEmpty
                              ? null
                              : () => onClick(uploadImages),
                          child: const Text(
                            'Upload',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading || cloudflareImages.isEmpty
                              ? null
                              : () => onClick(deleteUploadedImages),
                          style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) {
                                  return states.contains(MaterialState.disabled)
                                      ? null
                                      : Colors.red.shade600;
                                }),
                          ),
                          child: const Text(
                            'Delete uploaded images',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onClick(loadImage),
        tooltip: 'Choose image',
        child: const Icon(Icons.photo),
      ),
    );
  }

  onNewImages(List<String> filePaths) {
    if(filePaths.isNotEmpty) {
      for (final path in filePaths) {
        if (path.isNotEmpty) {
          pathImages.add(path);
        }
      }
      setState(() {});
    }
  }

  Future<List<int>> getFileBytes(String path) async {
    return await File(path).readAsBytes();
  }

  Future<void> doMultipleUpload() async {
    try {

      List<DataTransmit<String>>? contentFromPaths;
      List<DataTransmit<List<int>>>? contentFromBytes;

      switch (fileSource) {
        case FileSource.path:
          contentFromPaths = pathImages.map((path) => DataTransmit<String>(data: path)).toList();
          break;
        case FileSource.bytes:
          contentFromBytes = await Future.wait(pathImages.map((path) async => DataTransmit<List<int>>(data: await getFileBytes(path))));
          break;
        default:
      }

      List<CResponse<CloudflareImage?>> responses = await cloudflare.imageAPI.uploadMultiple(
        contentFromPaths: contentFromPaths,
        contentFromBytes: contentFromBytes,
      );

      for (var response in responses) {
        if (response.isSuccessful && response.body != null) {
          cloudflareImages.add(response.body!);
        } else {
          if(response.error is ErrorResponse && (response.error as ErrorResponse).messages.isNotEmpty) {
            errorMessage = (response.error as ErrorResponse).messages.first;
          } else {
            errorMessage = response.error?.toString();
          }
        }
      }
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> upload() async {
    showLoading();
    return doMultipleUpload();
  }

  Future<void> doMultipleDelete() async {

    List<CResponse> responses = await cloudflare.imageAPI.deleteMultiple(images: cloudflareImages,);

    errorMessage = null;
    List<CloudflareImage> imagesCouldNotDelete = [];
    for (int i = 0; i < responses.length; ++i ) {
      final response = responses[i];
      if (!response.isSuccessful) {
        imagesCouldNotDelete.add(cloudflareImages[i]);
        if(response.error is ErrorResponse && (response.error as ErrorResponse).messages.isNotEmpty) {
          errorMessage = (response.error as ErrorResponse).messages.first;
        } else {
          errorMessage = response.error?.toString();
        }
      }
    }

    if(imagesCouldNotDelete.isNotEmpty) {
      errorMessage = 'Not all images could be deleted: $errorMessage';
    }
    cloudflareImages.removeWhere((image) => !imagesCouldNotDelete.contains(image));
    setState(() {});
  }

  Future<void> delete() async {
    return doMultipleDelete();
  }

  void onClick(int id) async {
    errorMessage = null;
    try {
      switch (id) {
        case loadImage:
          AlertUtils.showImagePickerModal(
            context: context,
            onImageFromCamera: () async {
              onNewImages(await handleImagePickerResponse(
                  ImageUtils.takePhoto(cameraDevice: CameraDevice.rear)));
            },
            onImageFromGallery: () async {
              onNewImages(await handleImagePickerResponse(
                  ImageUtils.pickImageFromGallery()));
            },
          );
          break;
        case uploadImages:
          await upload();
          break;
        case deleteUploadedImages:
          await delete();
          break;
      }
    } catch (e) {
      print(e);
      loading = false;
      setState(() => errorMessage = e.toString());
    } finally {
      if (loading) hideLoading();
    }
  }

  showLoading() => setState(() => loading = true);

  hideLoading() => setState(() => loading = false);

  Future<List<String>> handleImagePickerResponse(Future getImageCall) async {
    Map<String, dynamic> resource =
    await (getImageCall as FutureOr<Map<String, dynamic>>);
    if (resource.isEmpty) return [];
    switch (resource['status']) {
      case 'SUCCESS':
        Navigator.pop(context);
        return resource['data'];
      default:
        ImageUtils.showPermissionExplanation(
            context: context, message: resource['message']);
        break;
    }
    return [];
  }
}
