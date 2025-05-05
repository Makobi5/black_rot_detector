import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

// Replace with your actual Gemini API key
const String apiKey = 'AIzaSyBU0nYJ79vuTX5CbJReS43Ygz96l_zrpgs'; 
const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(CabbageHealthApp(cameras: cameras));
}

class CabbageHealthApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const CabbageHealthApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabbage Health Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
      ),
      themeMode: ThemeMode.system,
      home: HomePage(cameras: cameras),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  
  const HomePage({Key? key, required this.cameras}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;
  bool _predictionMade = false;
  String _analysisDetails = '';
  List<String> _recommendations = [];
  bool _isCabbageImage = true;
  String _errorMessage = '';
  double _diseaseSeverity = 0.0; // 0-100 scale for disease severity
  String _diseaseType = ''; // Will store the detected disease type

  @override
  void initState() {
    super.initState();
  }

  Future pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _predictionMade = false;
        _isCabbageImage = true;
        _errorMessage = '';
        validateAndAnalyzeImage(_image!);
      }
    });
  }

  Future<void> validateAndAnalyzeImage(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First, validate that the image contains cabbage
      final validationResult = await validateCabbageImage(imageFile);
      
      if (validationResult.isValid) {
        // If valid, proceed to analyze for black rot
        await analyzeImageForBlackRot(imageFile);
      } else {
        setState(() {
          _isLoading = false;
          _predictionMade = true;
          _isCabbageImage = false;
          _errorMessage = validationResult.message;
        });
      }
    } catch (e) {
      print("Error processing image: $e");
      setState(() {
        _isLoading = false;
        _predictionMade = true;
        _isCabbageImage = false;
        _errorMessage = "An error occurred while processing the image. Please try again.";
      });
    }
  }

  Future<ValidationResult> validateCabbageImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Prepare the request payload for validation
      final payload = {
        "contents": [
          {
            "parts": [
              {
                "text": "This is an image validation task. Answer only YES or NO: Does this image contain cabbage plants or leaves? If no, briefly explain what is shown instead. Keep your response short and direct."
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.2,
          "topK": 32,
          "topP": 1,
          "maxOutputTokens": 1024,
        }
      };

      // Send request to Gemini API
      final response = await http.post(
        Uri.parse('$geminiEndpoint?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final generatedContent = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        
        // Check if the response indicates a valid cabbage image
        if (generatedContent.trim().toLowerCase().startsWith('yes')) {
          return ValidationResult(true, "");
        } else {
          // Extract explanation if available
          String explanation = generatedContent.replaceAll(RegExp(r'^no[.:,\s]*', caseSensitive: false), '').trim();
          if (explanation.isEmpty) {
            explanation = "This doesn't appear to be a cabbage plant image.";
          }
          return ValidationResult(false, "Invalid image: $explanation Please take a clear photo of cabbage plants or leaves.");
        }
      } else {
        print("API Error during validation: ${response.statusCode} - ${response.body}");
        return ValidationResult(false, "Couldn't validate the image. Please try again.");
      }
    } catch (e) {
      print("Error validating image: $e");
      return ValidationResult(false, "Error validating the image. Please try again.");
    }
  }

Future<void> analyzeImageForBlackRot(File imageFile) async {
  try {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    final payload = {
      "contents": [
        {
          "parts": [
            {
              "text": "Analyze this cabbage image for black rot disease. Provide a JSON response with these exact keys: "
                  "\n1. 'is_healthy' (boolean)"
                  "\n2. 'disease_name' (string or null)"
                  "\n3. 'confidence' (number 0-100)"
                  "\n4. 'key_symptoms' (array of 3 strings max)"
                  "\n5. 'treatment_plan' (array of 5 strings max)"
                  "\nReturn ONLY valid JSON with no additional text."
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.2,  // Lower for more deterministic responses
        "maxOutputTokens": 300,
      }
    };

    final response = await http.post(
      Uri.parse('$geminiEndpoint?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      final result = jsonDecode(content);

      setState(() {
        _isLoading = false;
        _predictionMade = true;
        _isCabbageImage = true;
        
        if (result['is_healthy'] == true) {
          _diseaseType = "Healthy";
          _diseaseSeverity = 0;
          _analysisDetails = "No signs of disease detected";
          _recommendations = [
            "Continue regular monitoring",
            "Maintain proper plant spacing",
            "Water at the base of plants",
            "Practice crop rotation",
            "Inspect weekly for early signs"
          ];
        } else {
          _diseaseType = result['disease_name'] ?? "Unknown Disease";
          _diseaseSeverity = (result['confidence'] ?? 0).toDouble();
          _analysisDetails = (result['key_symptoms'] as List).join('\n• ');
          _recommendations = List<String>.from(result['treatment_plan']);
        }
      });
    } else {
      throw Exception('API request failed');
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
      _predictionMade = true;
      _errorMessage = "Analysis failed. Please try again.";
    });
  }
}

// Simplified recommendation generator (fallback)
List<String> _getFallbackRecommendations(bool isHealthy) {
  return isHealthy
      ? [
          "Maintain current care routine",
          "Monitor for early symptoms",
          "Ensure proper soil drainage",
          "Remove weeds regularly",
          "Use balanced fertilizer"
        ]
      : [
          "Isolate affected plants",
          "Remove severely infected leaves",
          "Apply recommended fungicide",
          "Avoid overhead watering",
          "Sterilize tools after use"
        ];
}

  Widget buildResultCard() {
    if (!_isCabbageImage) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Invalid Image',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Another Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    Color cardColor = _diseaseSeverity == 0 
        ? Colors.green 
        : (_diseaseSeverity < 50 ? Colors.orange : Colors.red);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  _diseaseSeverity == 0 
                      ? Icons.check_circle 
                      : (_diseaseSeverity < 50 ? Icons.info : Icons.warning),
                  color: cardColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Detected: $_diseaseType',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_diseaseSeverity > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Severity: ${_diseaseSeverity.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  color: cardColor,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _diseaseSeverity / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            
            if (_analysisDetails.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Symptoms:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _analysisDetails,
                style: const TextStyle(fontSize: 15),
              ),
            ],
            
            const SizedBox(height: 20),
            const Text(
              'Recommendations:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._recommendations.map((tip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tip, style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cabbage Health Scanner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabbage image display area
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Analyzing for diseases...',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : _image == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_search,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Take or select a photo of cabbage plants or leaves',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.cover,
                            ),
                          ),
              ),
              const SizedBox(height: 24),
              
              // Camera and gallery buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // AI Powered badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'AI-Powered Disease Detection',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Results section
              if (_predictionMade) buildResultCard(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class ValidationResult {
  final bool isValid;
  final String message;
  
  ValidationResult(this.isValid, this.message);
}