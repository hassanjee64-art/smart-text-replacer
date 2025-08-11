import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Text Replacer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String detectedText = "";
  final textRecognizer = TextRecognizer();
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      await processImage(File(pickedFile.path));
    }
  }

  Future<void> processImage(File file) async {
    final inputImage = InputImage.fromFile(file);
    final recognisedText = await textRecognizer.processImage(inputImage);

    setState(() {
      detectedText = recognisedText.text;
    });
  }

  Future<void> saveEditedImage(String newText) async {
    if (_image == null) return;

    final bytes = await _image!.readAsBytes();
    img.Image? original = img.decodeImage(bytes);

    // Simple overlay with white background
    img.fill(original!, color: img.getColor(255, 255, 255));

    img.drawString(original, img.arial_24, 10, 10, newText);

    final dir = await getTemporaryDirectory();
    final newPath = '${dir.path}/edited_image.png';
    File(newPath).writeAsBytesSync(img.encodePng(original));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved: $newPath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: detectedText);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Text Replacer')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_image != null) Image.file(_image!),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Pick Image"),
            ),
            if (detectedText.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: textController,
                  maxLines: null,
                ),
              ),
              ElevatedButton(
                onPressed: () => saveEditedImage(textController.text),
                child: const Text("Save Edited Image"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
