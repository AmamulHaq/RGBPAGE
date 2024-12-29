import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
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
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _iframeElementId = 'webview-${DateTime.now().millisecondsSinceEpoch}';

    ui.platformViewRegistry.registerViewFactory(
      _iframeElementId,
      (int viewId) => html.IFrameElement()
        ..src = 'assets/rgb_cube_3d.html'
        ..style.border = 'none'
        ..allowFullscreen = true
        ..allow = 'accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture'
        ..setAttribute('sandbox', 'allow-scripts allow-same-origin'),
    );
  }

  void _updateColor(Color color) {
    setState(() {
      _selectedColor = color;
      _hexController.text = '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
      _rgbController.text = '(${color.red},${color.green},${color.blue})';
    });
  }

  void _updateColorFromHex() {
    String hex = _hexController.text.trim().toUpperCase();
    if (hex.isNotEmpty && hex.startsWith('#') && hex.length == 7) {
      try {
        Color color = Color(int.parse('0xFF${hex.substring(1)}'));
        _updateColor(color);
      } catch (_) {
        _showError('Invalid Hex Code Format!');
      }
    } else {
      _showError('Hex Code should be in the format #RRGGBB!');
    }
  }

  void _updateColorFromRGB() {
    String rgb = _rgbController.text.trim();
    final regex = RegExp(r'^\(\d{1,3},\d{1,3},\d{1,3}\)$');
    if (regex.hasMatch(rgb)) {
      rgb = rgb.substring(1, rgb.length - 1);
      List<String> rgbValues = rgb.split(',');
      try {
        int r = int.parse(rgbValues[0]);
        int g = int.parse(rgbValues[1]);
        int b = int.parse(rgbValues[2]);
        if (r >= 0 && r <= 255 && g >= 0 && g <= 255 && b >= 0 && b <= 255) {
          _updateColor(Color.fromRGBO(r, g, b, 1.0));
        }
      } catch (_) {
        _showError('Invalid RGB Format!');
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.black12,
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
              child: HtmlElementView(viewType: _iframeElementId),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    color: _selectedColor,
                    margin: const EdgeInsets.only(bottom: 16),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _rgbController,
                    decoration: const InputDecoration(
                      labelText: 'RGB Coordinates',
                      hintText: '(R,G,B)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _updateColorFromRGB(),
                  ),
                  const SizedBox(height: 16),
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
