import 'dart:isolate';
import 'dart:ui' as ui;

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
      appBar: AppBar(
        title: const Text('Background Remover'),
      ),
      body: ValueListenableBuilder(
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
                              Uint8List bytes = await image.readAsBytes();
                              outImg.value = await  BackgroundRemover.instance.removeBg(bytes);
                            },
                            child: const Text('Remove Background'),
                          ),

                          ValueListenableBuilder(
                            valueListenable: outImg,
                            builder: (context, img, _) {
                              return img == null
                                  ? const SizedBox()
                                  : Column(
                                children: [
                                  Image.memory(img),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<Uint8List?> removeBgInIsolate(Uint8List imageBytes) async {
    final responsePort = ReceivePort();
    await Isolate.spawn(_isolateEntry, [responsePort.sendPort, imageBytes]);
    final result = await responsePort.first as Uint8List;
    return result;
  }

  void _isolateEntry(List<dynamic> message) async {
    final SendPort sendPort = message[0];
    final Uint8List imageBytes = message[1];
    debugPrint('_isolateEntry start');
    try {
      final Uint8List result =
      await BackgroundRemover.instance.removeBg(imageBytes);
      sendPort.send(result);
      debugPrint('_isolateEntry result');
    } catch (e) {
      sendPort.send(null); // or handle error differently
      debugPrint('_isolateEntry null');

    }
  }
}
