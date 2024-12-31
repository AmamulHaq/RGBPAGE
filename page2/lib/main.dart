import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RGB Color Picker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ImageColorPicker(),
    );
  }
}

class ImageColorPicker extends StatefulWidget {
  const ImageColorPicker({Key? key}) : super(key: key);

  @override
  _ImageColorPickerState createState() => _ImageColorPickerState();
}

class _ImageColorPickerState extends State<ImageColorPicker> {
  final TextEditingController _urlController = TextEditingController();
  bool _imageLoaded = false;
  bool _loading = false;
  String _imageUrl = '';
  String? _imageBase64;
  Map<String, dynamic>? _hoveredPixelInfo;
  String? _errorMessage;
  Offset? _pointerPosition;

  // Load the image from the backend
  Future<void> _loadImage() async {
    setState(() {
      _imageUrl = _urlController.text.trim();
      _loading = true;
      _errorMessage = null;
    });

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/load_image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': _imageUrl}),
    );

    setState(() {
      _loading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        _imageLoaded = true;
        _imageBase64 = jsonDecode(response.body)['image'];
      });
    } else {
      setState(() {
        _errorMessage = 'Failed to load image: ${response.body}';
      });
    }
  }

  // Fetch pixel information from the backend
  Future<void> _fetchPixelInfo(Offset localPosition) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final offset = box.globalToLocal(localPosition);

      // Map pointer position to a 258x258 container
      final x = offset.dx.clamp(0, 258);
      final y = offset.dy.clamp(0, 258);

      // Send clamped coordinates to the backend
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/get_pixel_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'x': x.toInt(), 'y': y.toInt()}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _hoveredPixelInfo = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _hoveredPixelInfo = null;
          _errorMessage = 'Failed to fetch pixel info: ${response.body}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter Image URL',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadImage,
                  child: _loading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text('Load'),
                ),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 8),
            if (_imageLoaded)
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pointerPosition = details.localPosition;
                  });
                  _fetchPixelInfo(details.localPosition);
                },
                child: Container(
                  width: 258,
                  height: 258,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Container(
                      width: 256,
                      height: 256,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1),
                        image: _imageBase64 != null
                            ? DecorationImage(
                                image: MemoryImage(base64Decode(_imageBase64!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            if (_hoveredPixelInfo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Position: (${_hoveredPixelInfo!['x']}, ${_hoveredPixelInfo!['y']})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'RGB: (${_hoveredPixelInfo!['r']}, ${_hoveredPixelInfo!['g']}, ${_hoveredPixelInfo!['b']})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Hex: ${_hoveredPixelInfo!['hex']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(
                            _hoveredPixelInfo!['r'],
                            _hoveredPixelInfo!['g'],
                            _hoveredPixelInfo!['b'],
                            1.0,
                          ),
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
