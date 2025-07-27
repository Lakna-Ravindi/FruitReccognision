import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FruitPredictorPage extends StatefulWidget {
  const FruitPredictorPage({Key? key}) : super(key: key);

  @override
  State<FruitPredictorPage> createState() => _FruitPredictorPageState();
}

class _FruitPredictorPageState extends State<FruitPredictorPage> {
  File? _image;
  XFile? _webImage;
  String? _predictedFruit;
  Map<String, String>? _nutrition;
  bool _loading = false;
  final String _baseUrl = 'http://127.0.0.1:5001'; // Change if needed

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (kIsWeb) {
          _webImage = picked;
          _image = null;
        } else {
          _image = File(picked.path);
          _webImage = null;
        }
        _predictedFruit = null;
        _nutrition = null;
      });
      await _predictFruit(picked);
    }
  }

  Future<void> _predictFruit(dynamic picked) async {
    setState(() => _loading = true);
    try {
      http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: picked.name),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', picked.path),
        );
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = json.decode(respStr);
        if (data['fruit'] != null) {
          final beautified = _beautifyLabel(data['fruit'].toString());
          setState(() => _predictedFruit = beautified);
          await _fetchNutrition(data['fruit'].toString());
        } else {
          _showErrorSnackBar('No fruit predicted');
        }
      } else {
        _showErrorSnackBar('Prediction failed: $respStr');
      }
    } catch (e) {
      _showErrorSnackBar('Prediction failed');
    }
    setState(() => _loading = false);
  }

  Future<void> _fetchNutrition(String rawFruitLabel) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/nutrition'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'fruit': rawFruitLabel}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(
        () =>
            _nutrition = {
              'Calories': '${data['calories']} kcal',
              'Sugar': '${data['sugarContent']} g',
              'Vitamin C': '${data['vitaminC']} mg',
            },
      );
    } else {
      _showErrorSnackBar('Nutrition info not found');
    }
  }

  String _beautifyLabel(String label) {
    final parts = label.split('_');
    if (parts.length == 2) {
      return '${parts[0][0].toUpperCase()}${parts[0].substring(1)} (${parts[1][0].toUpperCase()}${parts[1].substring(1)})';
    }
    return label;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _reset() {
    setState(() {
      _image = null;
      _webImage = null;
      _predictedFruit = null;
      _nutrition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fruit Nutrition Predictor'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Center(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _image != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _image!,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                          : _webImage != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _webImage!.path,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                          : Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.image,
                                  size: 80,
                                  color: Colors.green,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No image selected',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick Image from Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_loading) const CircularProgressIndicator(),
                      if (_predictedFruit != null && !_loading) ...[
                        const Text(
                          'Predicted Fruit:',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _predictedFruit!,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Another'),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_nutrition != null && !_loading)
                        Card(
                          color: Colors.green[50],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nutrition Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._nutrition!.entries.map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          e.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          e.value,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_loading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
