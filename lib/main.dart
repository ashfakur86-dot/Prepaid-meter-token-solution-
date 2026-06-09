import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NumberScannerScreen(),
    );
  }
}

class NumberScannerScreen extends StatefulWidget {
  const NumberScannerScreen({super.key});

  @override
  State<NumberScannerScreen> createState() => _NumberScannerScreenState();
}

class _NumberScannerScreenState extends State<NumberScannerScreen> {
  String _processedResult = "";
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _processImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _processedResult = "";
    });

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String allNumbers = recognizedText.text.replaceAll(RegExp(r'[^0-9]'), '');

      StringBuffer formattedText = StringBuffer();
      int digitCount = 0;

      for (int i = 0; i < allNumbers.length; i++) {
        formattedText.write(allNumbers[i]);
        digitCount++;

        if (digitCount % 4 == 0 && digitCount % 20 != 0) {
          formattedText.write(" ");
        }

        if (digitCount % 20 == 0 && i != allNumbers.length - 1) {
          formattedText.write("\n");
        }
      }

      setState(() {
        _processedResult = formattedText.toString();
      });

      textRecognizer.close();
    } catch (e) {
      setState(() {
        _processedResult = "Error scanning image: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prepaid Token Formatter'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _processImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('ক্যামেরা'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _processImage(ImageSource.gallery),
                  icon: const Icon(Icons.image),
                  label: const Text('গ্যালারি'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: SelectableText(
                          _processedResult.isEmpty
                              ? "টোকেনের ছবি তুলুন বা গ্যালারি থেকে সিলেক্ট করুন।"
                              : _processedResult,
                          style: const TextStyle(
                            fontSize: 20, 
                            fontFamily: 'monospace', 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            if (_processedResult.isNotEmpty && !_isLoading)
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _processedResult));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('টোকেন কপি করা হয়েছে!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text('সব টোকেন কপি করুন', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
