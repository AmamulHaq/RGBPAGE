import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'package:http/http.dart' as http;
import 'newPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late String _iframeElementId;
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _rgbController = TextEditingController();
  Color _selectedColor = const Color.fromRGBO(0, 0, 0, 1.0);
  html.IFrameElement? _iframeElement;

  @override
  void initState() {
    super.initState();
    _iframeElementId = 'webview-${DateTime.now().millisecondsSinceEpoch}';

    // Register the iframe with Flutter platform view
    ui.platformViewRegistry.registerViewFactory(
      _iframeElementId,
      (int viewId) {
        _iframeElement = html.IFrameElement()
          ..src = 'assets/rgb_cube_3d.html'
          ..style.border = 'none'
          ..allowFullscreen = true
          ..allow =
              'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture'
          ..setAttribute('sandbox', 'allow-scripts allow-same-origin');
        return _iframeElement!;
      },
    );

    // Set initial RGB value to (0,0,0)
    _updateColorFromRGB('(0,0,0)');
  }

  Future<void> _sendRGBToServer(String rgb, String type) async {
    final url = Uri.parse('http://192.168.31.8:5002/log_color'); // Flask server URL
    final body = json.encode({"value": rgb, "type": type});

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        print('$rgb is sent to generate_rgb_cube.py');
        _reloadWebView(); // Reload WebView after successful server update
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error sending RGB data to server: $e');
    }
  }

  void _reloadWebView() {
    setState(() {
      _iframeElement?.src =
          'assets/rgb_cube_3d.html?timestamp=${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  void _updateColor(Color color) {
    setState(() {
      _selectedColor = color;
      _hexController.text =
          '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
      _rgbController.text = '(${color.red},${color.green},${color.blue})';
    });

    final rgb = "${color.red},${color.green},${color.blue}";
    _sendRGBToServer('($rgb)', 'rgb');
  }

  void _updateColorFromHex() {
    String hex = _hexController.text.trim().toUpperCase();
    if (RegExp(r'^#[A-Fa-f0-9]{6}$').hasMatch(hex)) {
      try {
        Color color = Color(int.parse('0xFF${hex.substring(1)}'));
        _updateColor(color);
        _sendRGBToServer(hex, 'hex');
      } catch (_) {
        _showError('Invalid Hex Code Format!');
      }
    } else {
      _showError('Hex Code should be in the format #RRGGBB!');
    }
  }

  void _updateColorFromRGB([String? initialRgb]) {
    String rgb = initialRgb ?? _rgbController.text.trim();
    final regex = RegExp(r'^\(\d{1,3},\d{1,3},\d{1,3}\)$');
    if (regex.hasMatch(rgb)) {
      rgb = rgb.substring(1, rgb.length - 1);
      List<int> rgbValues = rgb.split(',').map(int.parse).toList();
      if (rgbValues.every((value) => value >= 0 && value <= 255)) {
        _updateColor(
            Color.fromRGBO(rgbValues[0], rgbValues[1], rgbValues[2], 1.0));
      } else {
        _showError('RGB values must be between 0 and 255!');
      }
    } else {
      _showError('RGB Format should be (R,G,B)!');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _navigateToNewPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("3D RGB Cube"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.black12,
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
              child: HtmlElementView(viewType: _iframeElementId),
            ),
            const SizedBox(height: 3), // Reduced vertical space
            Padding(
              padding: const EdgeInsets.all(8.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    color: _selectedColor,
                    margin: const EdgeInsets.only(bottom: 3), // Reduced bottom margin
                  ),
                  TextField(
                    controller: _hexController,
                    decoration: const InputDecoration(
                      labelText: 'Hex Code',
                      hintText: '#RRGGBB',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _updateColorFromHex(),
                  ),
                  const SizedBox(height: 3), // Reduced vertical space
                  TextField(
                    controller: _rgbController,
                    decoration: const InputDecoration(
                      labelText: 'RGB Coordinates',
                      hintText: '(R,G,B)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _updateColorFromRGB(),
                  ),
                  const SizedBox(height: 3), // Reduced vertical space
                  ElevatedButton(
                    onPressed: _navigateToNewPage,
                    child: const Text('Go to New Page'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
