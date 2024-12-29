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
  Offset? _pointerPosition;  // Track pointer position for the black dot

  // Load the image by sending its URL to the backend
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
      print('Image loaded successfully');
    } else {
      print('Failed to load image: ${response.body}');
      setState(() {
        _errorMessage = 'Failed to load image: ${response.body}';
      });
    }
  }

  // Fetch pixel information when the pointer hovers over the image
  Future<void> _fetchPixelInfo(Offset localPosition) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      final offset = box.globalToLocal(localPosition);

      // Map the pointer position to a 256x256 grid, ensuring it's within bounds
      final x = (offset.dx / box.size.width * 256).toInt();
      final y = (offset.dy / box.size.height * 256).toInt();

      // Ensure coordinates are within bounds (0 <= x, y < 256)
      if (x >= 0 && x < 256 && y >= 0 && y < 256) {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/get_pixel_info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'x': x, 'y': y}),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RGB Color Picker'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Image URL',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _loadImage,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Load Image'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_imageLoaded)
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pointerPosition = details.localPosition;
                  });
                  _fetchPixelInfo(details.localPosition);
                },
                child: Stack(
                  children: [
                    Container(
                      width: 256,  // Fixed container size for clear image display
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
                    if (_pointerPosition != null)
                      Positioned(
                        left: _pointerPosition!.dx - 5,  // Adjust position for the black dot
                        top: _pointerPosition!.dy - 5,   // Adjust position for the black dot
                        child: const Icon(
                          Icons.circle,
                          size: 10,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
            if (_hoveredPixelInfo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      // Display the hovered color
                      Container(
                        width: 40,
                        height: 40,
                        color: Color(int.parse(_hoveredPixelInfo!['hex'].replaceFirst('#', '0xff'))),
                        margin: const EdgeInsets.only(right: 16.0),
                      ),
                      // RGB and Hex Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RGB: (${_hoveredPixelInfo!['r']}, ${_hoveredPixelInfo!['g']}, ${_hoveredPixelInfo!['b']})',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Hex: ${_hoveredPixelInfo!['hex']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
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
