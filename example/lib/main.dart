import 'package:example/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_background_remover/image_background_remover.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ValueNotifier<Uint8List?> outImg = ValueNotifier<Uint8List?>(null);

  @override
  void initState() {
    BackgroundRemover.instance.initializeOrt();
    super.initState();
  }

  @override
  void dispose() {
    BackgroundRemover.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEFDFF),
      appBar: AppBar(
        title: const Text('Background Remover'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: ImagePickerService.pickedFile,
          builder: (context, image, _) {
            return GestureDetector(
              onTap: () async {
                await ImagePickerService.pickImage();
              },
              child: Container(
                alignment: Alignment.center,
                child: image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 100,
                          ),
                          Text('No image selected.'),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            Image.file(image),
                            const SizedBox(
                              height: 20,
                            ),
                            TextButton(
                              onPressed: () async {
                                outImg.value = await BackgroundRemover.instance
                                    .removeBg(image.readAsBytesSync());
                              },
                              child: const Text('Remove Background'),
                            ),
                            TextButton(
                              onPressed: () async {
                                outImg.value = await BackgroundRemover.instance
                                    .removeBGAddStroke(image.readAsBytesSync(), stokeWidth: 5, stokeColor: Colors.blue, secondaryStrokeWidth: 5);
                              },
                              child: const Text('Remove Background With Stroke'),
                            ),
                            ValueListenableBuilder(
                              valueListenable: outImg,
                              builder: (context, img, _) {
                                return img == null
                                    ? const SizedBox()
                                    : Image.memory(img);
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
