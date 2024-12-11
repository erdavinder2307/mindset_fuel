// import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:mindset_fuel/services/mindset_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:wallpaper/wallpaper.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<String> _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = MindsetService().fetchRandomImageUrl();
  }

  Future<void> _setWallpaper(String url) async {
    try {
      // Request storage permissions
      final status = await Permission.manageExternalStorage.status;
      if (status.isGranted) {
        //if(1==1){
        // Get the temporary directory of the device
        final directory = await getDownloadsDirectory();
        final imageName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${directory?.path}/$imageName';

        // Download the image
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('Failed to download image');
        }

        // Decode the image
        final image = img.decodeImage(response.bodyBytes);
        if (image == null) {
          throw Exception('Failed to decode image');
        }

        // Get the device's screen dimensions
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width.toInt();
        final screenHeight = screenSize.height.toInt();

        // Resize the image to fit the screen dimensions while maintaining aspect ratio
        final resizedImage = img.copyResize(image,
            width: screenWidth,
            height: screenHeight,
            interpolation: img.Interpolation.cubic);

        // Create a new image with padding to fit the screen dimensions
        final paddedImage = img.Image(width: screenWidth, height: screenHeight);
        img.fill(paddedImage,
            color: img.ColorInt16.rgb(255, 255, 255)); // Fill with white color

        // Calculate padding to center the image
        final xOffset = (screenWidth - resizedImage.width) ~/ 2;
        final yOffset = (screenHeight - resizedImage.height) ~/ 2;

        // Composite the resized image onto the padded image
        img.compositeImage(paddedImage, resizedImage, dstX: xOffset, dstY: yOffset,center: true);

        // Save the processed image to the file
        final file = File(filePath);
        await file.writeAsBytes(img.encodeJpg(paddedImage));

        // int location = WallpaperManager.BOTH_SCREEN; //can be Home/Lock Screen
        // bool result = await WallpaperManager.setWallpaperFromFile(filePath, location); //provide image path
        // await AsyncWallpaper.setWallpaperFromFile(
        //   filePath: file.path,
        //   wallpaperLocation: AsyncWallpaper.BOTH_SCREENS,
        //   goToHome: false,
        //   toastDetails: ToastDetails.success(),
        //   errorToastDetails: ToastDetails.error(),
        // );

        // Set the wallpaper
        // final Stream<String> progressString = Wallpaper.imageDownloadProgress(url);
        // progressString.listen((data) {
        //   print("Progress: $data");
        // }, onDone: () async {
        if (Theme.of(context).platform == TargetPlatform.iOS) {
          // iOS implementation (if needed)
        } else {
          // Use wallpaper plugin for Android
          //  final String result = await Wallpaper.bothScreen(
          //     imageName: filePath,
          //     options: RequestSizeOptions.resizeFit,
          //   );
          final result = await AsyncWallpaper.setWallpaperFromFile(
            filePath: file.path,
            wallpaperLocation: AsyncWallpaper.BOTH_SCREENS,
            goToHome: false,
            toastDetails: ToastDetails.success(),
            errorToastDetails: ToastDetails.error(),
          );
          if (result) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wallpaper set successfully')),
            );
          } else {
            throw Exception('Failed to set wallpaper');
          }
        }
        // });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage permission denied'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () async {
                await Permission.storage.request();
              },
            ),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (e.code == 'FILE_NOT_FOUND') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The specified file was not found')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set wallpaper: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set wallpaper: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Home'),
            ),
            child: Center(
              child: FutureBuilder<String>(
                future: _imageUrl,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CupertinoActivityIndicator();
                  } else if (snapshot.hasError) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error loading image'),
                        CupertinoButton(
                          child: const Text('Retry'),
                          onPressed: () {
                            setState(() {
                              _imageUrl =
                                  MindsetService().fetchRandomImageUrl();
                            });
                          },
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(snapshot.data!),
                        CupertinoButton(
                          child: const Text('Set as Wallpaper'),
                          onPressed: () => _setWallpaper(snapshot.data!),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Home'),
            ),
            body: Center(
              child: FutureBuilder<String>(
                future: _imageUrl,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error loading image'),
                        ElevatedButton(
                          child: const Text('Retry'),
                          onPressed: () {
                            setState(() {
                              _imageUrl =
                                  MindsetService().fetchRandomImageUrl();
                            });
                          },
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(snapshot.data!),
                        ElevatedButton(
                          child: const Text('Set as Wallpaper'),
                          onPressed: () => _setWallpaper(snapshot.data!),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          );
  }
}
