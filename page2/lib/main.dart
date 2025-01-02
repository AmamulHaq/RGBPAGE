import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RGB Tools',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _cubeUrlController = TextEditingController();
  bool _imageLoaded = false;
  bool _loading = false;
  String? _imageBase64;
  String? _errorMessage;
  String? _colorSample;
  String? _rgbDetails;
  String? _hexDetails;
  String? _positionDetails;
  String? _iframeId;
  String? _iframeUrl;
  bool _showIframe = false;

  @override
  void initState() {
    super.initState();
    _iframeId = 'webview-${DateTime.now().millisecondsSinceEpoch}';
    ui.platformViewRegistry.registerViewFactory(
      _iframeId!,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.height = '100%'
          ..style.width = '100%'
          ..allowFullscreen = true
          ..allow =
              'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture'
          ..setAttribute('sandbox', 'allow-scripts allow-same-origin');

        if (_iframeUrl != null) {
          iframe.src = _iframeUrl!;
        }
        return iframe;
      },
    );
  }

  // Load the image from the backend
  Future<void> _loadImage() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5001/load_image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': _imageUrlController.text.trim()}),
      );

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
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading image: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Function to handle hover over image for RGB and Hex details
  void _handleHover(int x, int y) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5001/get_pixel_info'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'x': x, 'y': y}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _colorSample =
            data['hex']; // colorSample can be used for the color display box
        _rgbDetails = 'RGB(${data['r']}, ${data['g']}, ${data['b']})';
        _hexDetails = 'Hex: ${data['hex']}';
        _positionDetails = 'Position: ($x, $y)';
      });
    }
  }

  // Generate 3D Cube
  Future<void> _generateCube() async {
    final imageUrl = _cubeUrlController.text.trim();
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid image URL')),
      );
      return;
    }

    setState(() {
      _showIframe = false;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/generate_cube'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imageUrl': imageUrl}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final htmlBase64 = responseBody['cubeHtml'];

        if (htmlBase64 != null && htmlBase64 is String) {
          final decodedHtml = utf8.decode(base64Decode(htmlBase64));
          final blob = html.Blob([decodedHtml], 'text/html');
          final url = html.Url.createObjectUrlFromBlob(blob);

          setState(() {
            _iframeUrl = url;
            _showIframe = true;
          });
        } else {
          setState(() {
            _errorMessage = 'Invalid response format from the server.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to generate cube: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RGB Tools')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Color Picker Section
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Image URL for Color Picker',
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),
            if (_imageLoaded)
              MouseRegion(
                onEnter: (_) {
                  _handleHover(128, 128); // Example hover at (128, 128)
                },
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _handleHover(details.localPosition.dx.toInt(),
                          details.localPosition.dy.toInt());
                    });
                  },
                  child: Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(_imageBase64!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Color Details Section
            if (_colorSample != null)
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
                            _positionDetails ?? 'Position: N/A',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            _rgbDetails ?? 'RGB: N/A',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            _hexDetails ?? 'Hex: N/A',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _colorSample != null
                              ? Color(int.parse(
                                  _colorSample!.replaceFirst('#', '0xff')))
                              : Colors.transparent,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 3D Cube Generator Section
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextField(
                controller: _cubeUrlController,
                decoration: const InputDecoration(
                  labelText: 'Enter Image URL for 3D Cube Generator',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _generateCube,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Generate 3D Cube'),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              ),
            if (_showIframe)
              SizedBox(
                width: 256,
                height: 256,
                child: HtmlElementView(viewType: _iframeId!),
              ),
          ],
        ),
      ),
    );
  }
}
