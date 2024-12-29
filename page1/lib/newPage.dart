import 'package:flutter/material.dart';

class NewPage extends StatefulWidget {
  const NewPage({super.key});

  @override
  _NewPageState createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  TextEditingController _imageController = TextEditingController(); // Controller for image URL input
  String? _imagePath; // Variable to hold the image path or URL
  Color _color = Colors.red; // Default color for the color box

  @override
  void dispose() {
    _imageController.dispose(); // Dispose the controller when no longer needed
    super.dispose();
  }

  // Function to update image path from input
  void _updateImagePath() {
    setState(() {
      _imagePath = _imageController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 30,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: TextField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter image URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _updateImagePath,
                    child: const Text('Update'),
                  ),
                ],
              ),

              // 256x256 container for the image (First one)
              _imagePath == null || _imagePath!.isEmpty
                  ? Container(
                      width: 256,
                      height: 256,
                      color: Colors.grey.shade300, // Placeholder color
                      alignment: Alignment.center,
                      child: const Text('No Image'),
                    )
                  : Container(
                      width: 256,
                      height: 256,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        image: DecorationImage(
                          image: NetworkImage(_imagePath!), // Load image from URL
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                    ),

              // RGB, Hex display with color box aligned horizontally
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    color: _color, // Example color, replace with dynamic color later
                  ),
                  const SizedBox(width: 8), // Space between color box and text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'RGB: (255, 99, 71)', // Example RGB value
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Hex: #FF6347', // Example Hex code
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),

              // 256x256 container for the image (Second one)
              Container(
                width: 256,
                height: 256,
                color: Colors.grey.shade300, // Placeholder color
                alignment: Alignment.center,
                child: const Text('No Image'), // Default "No Image" text
              ),
            ],
          ),
        ),
      ),
    );
  }
}