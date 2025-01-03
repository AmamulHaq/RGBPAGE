import 'dart:convert';
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
  Color _selectedColor = const Color.fromRGBO(123, 240, 154, 1.0);
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
  }

  void _updateColor(Color color) {
    setState(() {
      _selectedColor = color;
      _hexController.text =
          '#${color.value.toRadixString(16).toUpperCase().substring(2)}';
      _rgbController.text = '(${color.red},${color.green},${color.blue})';
    });

    // Print only the RGB values in the format "123,45,65"
    print("${color.red},${color.green},${color.blue}");
  }

  void _updateColorFromHex() {
    String hex = _hexController.text.trim().toUpperCase();
    if (RegExp(r'^#[A-Fa-f0-9]{6}$').hasMatch(hex)) {
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
