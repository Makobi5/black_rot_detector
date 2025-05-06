import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screens.dart'; // Make sure to import your auth screens
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Replace with your actual Gemini API key
const String apiKey = 'AIzaSyBU0nYJ79vuTX5CbJReS43Ygz96l_zrpgs'; 
const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent';
class SupabaseCredentials {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://xayqdixeownbkwapasss.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhheXFkaXhlb3duYmt3YXBhc3NzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NTY0MDEsImV4cCI6MjA2MjAzMjQwMX0.kLt1Z-WXIUQix3W9jdBJDFQla9dUZzMkMC82DZAFeb4',
    );
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
await SupabaseCredentials.initialize();


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabbage Health Tracker',
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class CabbageHealthApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const CabbageHealthApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cabbage Health Tracker',
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
      home: FutureBuilder<List<CameraDescription>>(
        future: availableCameras(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return HomePage(cameras: snapshot.data ?? []);
        },
      ),
    );
  }
}
class LoginSignupScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginSignupScreen({Key? key, required this.onLogin}) : super(key: key);

  @override
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Login
        final response = await SupabaseCredentials.client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        // Sign up
        final response = await SupabaseCredentials.client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          data: {
            'name': _nameController.text,
          },
        );
        
        // Insert user data into public.users table
        await SupabaseCredentials.client.from('users').insert({
          'id': response.user!.id,
          'email': _emailController.text,
          'name': _nameController.text,
        });
      }
      
      widget.onLogin();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _switchAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/seedscan_logo.png',
                height: 120,
              ),
              const SizedBox(height: 40),
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_isLogin)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person)),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit, // This calls your submit method
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _isLogin ? 'Login' : 'Sign Up',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: _switchAuthMode,
                      child: Text(
                        _isLogin 
                            ? 'Don\'t have an account? Sign Up'
                            : 'Already have an account? Login',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
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
    _errorMessage = ""; // Clear any previous error messages
  });

  try {
    // Skip the validation step and go directly to analysis
    // This is the key change - we're removing the separate validation step
    await analyzeImageForBlackRot(imageFile);
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
Widget _buildAnalysisResults() {
  // Choose colors based on disease status
  final Color statusColor = _diseaseType == "Healthy" 
      ? Colors.green 
      : Colors.red;
  
  final Color bgColor = _diseaseType == "Healthy" 
      ? Colors.green[50]! 
      : Colors.red[50]!;
  
  final Color textColor = _diseaseType == "Healthy" 
      ? Colors.green[700]! 
      : Colors.red[700]!;
  
  final IconData statusIcon = _diseaseType == "Healthy" 
      ? Icons.check_circle 
      : Icons.warning;

  // Create the severity indicator (not shown for healthy plants)
  Widget severityIndicator = _diseaseType == "Healthy" 
      ? Container() 
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(
              "Disease Severity:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: _diseaseSeverity / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _diseaseSeverity < 30 
                    ? Colors.amber 
                    : (_diseaseSeverity < 70 ? Colors.orange : Colors.red),
              ),
              minHeight: 10,
            ),
            SizedBox(height: 4),
            Text(
              "${_diseaseSeverity.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _diseaseSeverity < 30 
                    ? Colors.amber[700] 
                    : (_diseaseSeverity < 70 ? Colors.orange[700] : Colors.red[700]),
              ),
            ),
          ],
        );

  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    margin: EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: statusColor.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status header
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            SizedBox(width: 8),
            Text(
              _diseaseType == "Healthy" ? "Healthy Cabbage" : "Detected: $_diseaseType",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        
        // Severity indicator (only for diseased plants)
        severityIndicator,
        
        // Symptoms
        SizedBox(height: 16),
        Text(
          "Assessment:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          _analysisDetails,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[800],
          ),
        ),
        
        // Recommendations
        SizedBox(height: 16),
        Text(
          "Recommendations:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ..._recommendations.map((rec) => Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.arrow_right, size: 20, color: Colors.grey[700]),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  rec,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  );
}

Widget _buildResultsSection() {
  if (_isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Analyzing image...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  if (!_predictionMade) {
    return Container(); // Empty container if no prediction yet
  }
  
  if (!_isCabbageImage && _errorMessage.isNotEmpty) {
    // Show error message if it's not a cabbage image or there's another error
    return _buildErrorMessage();
  } else {
    // Show the analysis results
    return _buildAnalysisResults();
  }
}

Widget _buildErrorMessage() {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    margin: EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "No cabbage image detected, please take an image of a cabbage and try again",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          _errorMessage,
          style: TextStyle(
            fontSize: 16,
            color: Colors.red[800],
          ),
        ),
      ],
    ),
  );
}

Future<ValidationResult> validateCabbageImage(File imageFile) async {
  try {
    // Convert image to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    // Improved prompt to validate if this is a cabbage plant
    final payload = {
      "contents": [
        {
          "parts": [
            {
              "text": "Is this a clear image of a cabbage plant or cabbage leaves? Answer with only 'Yes' if it's clearly a cabbage plant or cabbage leaves, or 'No' followed by a brief explanation if it's not. Don't describe the plant's condition yet."
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
        "temperature": 0.1,
        "topK": 32,
        "topP": 1,
        "maxOutputTokens": 512,
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
        return ValidationResult(false, "No cabbage detected: $explanation Please take a clear photo of cabbage plants or leaves.");
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
    // First validate if this is a cabbage image
    final validationResult = await validateCabbageImage(imageFile);
    if (!validationResult.isValid) {
      setState(() {
        _isLoading = false;
        _predictionMade = true;
        _isCabbageImage = false;
        _diseaseType = "No Cabbage Detected";
        _diseaseSeverity = 0.0;
        _analysisDetails = validationResult.message;
        _recommendations = [
          "**Take a clear photo:** Ensure the cabbage plant is clearly visible in the frame.",
          "**Use good lighting:** Take photos in natural daylight for best results.",
          "**Get close enough:** Make sure leaves and any symptoms are clearly visible.",
          "**Include multiple angles:** If concerned about disease, take photos of different parts of the plant.",
          "**Try again:** Use the Camera button to take a new photo, or Gallery to select an existing image."
        ];
        _errorMessage = "";
      });
      return;
    }
    
    // Convert image to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    // Improved prompt with better detection of healthy vs. diseased cabbage
    final payload = {
      "contents": [
        {
          "parts": [
            {
              "text": "Analyze this cabbage plant image specifically for black rot disease (Xanthomonas campestris). Follow these exact instructions:\n\n1. PRIMARY FOCUS: You are a black rot detection system, but you must also accurately identify healthy cabbages.\n\n2. If the cabbage appears completely HEALTHY with no symptoms of disease:\n   - The cabbage should look uniform in color (typically green or purple) with no lesions\n   - Leaf edges should be smooth and intact with no yellowing or V-shaped lesions\n   - There should be no blackened veins or wilting\n   - Output 'STATUS: HEALTHY'\n   - Output 'SEVERITY: 0%'\n\n3. If there are CLEAR symptoms of BLACK ROT:\n   - Yellow/brown V-shaped lesions at leaf margins\n   - Blackened veins\n   - Wilting or leaf drop\n   - Output 'STATUS: DETECTED: Black Rot'\n   - Output 'SEVERITY: [40-100]%' based on visible damage\n\n4. VERY IMPORTANT: Do NOT classify healthy cabbages as having black rot. A healthy cabbage with normal variations in color, slight irregularities, or minor imperfections is still HEALTHY.\n\nThis is a critical plant health monitoring system. False positives (claiming disease when plants are healthy) are just as problematic as false negatives."
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
        "temperature": 0.1, // Lower temperature for more consistent responses
        "topK": 32,
        "topP": 1,
        "maxOutputTokens": 2048,
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
      
      // Log the raw response for debugging
      print("Raw Gemini response: $generatedContent");
      
      // Parse the structured response
      String status = '';
      double severity = 0.0;
      String symptoms = '';
      List<String> recommendations = [];
      
      // First, determine if the response indicates a healthy plant
      bool isHealthy = generatedContent.toUpperCase().contains('HEALTHY') && 
                      !generatedContent.toLowerCase().contains('not healthy');
      
      // Extract status
      final statusMatch = RegExp(r'STATUS:\s*(.*?)(?:\n|$)', caseSensitive: false).firstMatch(generatedContent);
      if (statusMatch != null) {
        status = statusMatch.group(1)!.trim();
      } else if (isHealthy) {
        status = "HEALTHY";
      } else if (generatedContent.toUpperCase().contains('BLACK ROT')) {
        status = "DETECTED: Black Rot";
      }
      
      // Extract severity
      final severityMatch = RegExp(r'SEVERITY:\s*(\d+)%', caseSensitive: false).firstMatch(generatedContent);
      if (severityMatch != null) {
        severity = double.parse(severityMatch.group(1)!).clamp(0, 100);
      } else if (isHealthy) {
        severity = 0.0;
      } else if (status.toUpperCase().contains('BLACK ROT')) {
        // Default severity for black rot if not specified
        severity = 65.0;
      }
      
      // Extract symptoms/analysis
      final symptomsMatch = RegExp(r'SYMPTOMS:\s*(.*?)(?=\n\n|\n[A-Z]|$)', multiLine: true, dotAll: true, caseSensitive: false).firstMatch(generatedContent);
      if (symptomsMatch != null) {
        symptoms = symptomsMatch.group(1)!.trim();
      } else {
        // Try to extract symptoms from any descriptive text
        final lines = generatedContent.split('\n');
        for (final line in lines) {
          if (line.toLowerCase().contains('leaf') || 
              line.toLowerCase().contains('appear') || 
              line.toLowerCase().contains('look') || 
              line.toLowerCase().contains('plant')) {
            symptoms += line.trim() + " ";
          }
        }
      }
      
      // If symptoms is still empty, provide default descriptions
      if (symptoms.trim().isEmpty) {
        if (status.toUpperCase().contains('BLACK ROT')) {
          symptoms = "The cabbage leaves show symptoms consistent with black rot infection, including irregular edges, discoloration, and potential V-shaped lesions at leaf margins.";
        } else if (status.toUpperCase().contains('HEALTHY')) {
          symptoms = "The cabbage appears healthy with uniform color, intact leaf edges, and no visible disease symptoms.";
        } else {
          symptoms = "The plant requires further inspection to determine its health status.";
        }
      }
      
      // Ensure symptoms don't contradict the status
      if (status.toUpperCase().contains('HEALTHY') && 
          (symptoms.toLowerCase().contains('disease') || 
           symptoms.toLowerCase().contains('infection') ||
           symptoms.toLowerCase().contains('black rot'))) {
        symptoms = "The cabbage appears healthy with uniform coloration, intact leaf structure, and no visible signs of disease.";
      }
      
      if (status.toUpperCase().contains('BLACK ROT') && 
          (symptoms.toLowerCase().contains('no disease') || 
           symptoms.toLowerCase().contains('healthy') ||
           symptoms.toLowerCase().contains('no sign'))) {
        symptoms = "The cabbage leaves show subtle signs consistent with early black rot infection, including slight irregularities at leaf margins and potential early discoloration.";
      }
      
      // Get appropriate recommendations based on the diagnosis
      String diseaseType = extractDiseaseType(status);
      recommendations = getRecommendationsForCondition(diseaseType, severity);
      
      setState(() {
        _isLoading = false;
        _predictionMade = true;
        _isCabbageImage = true;
        _diseaseSeverity = severity;
        _diseaseType = diseaseType;
        _analysisDetails = symptoms.trim();
        _recommendations = recommendations;
        _errorMessage = ""; // Clear any error messages
      });
      
    } else {
      print("API Error: ${response.statusCode} - ${response.body}");
      setState(() {
        _isLoading = false;
        _predictionMade = true;
        _isCabbageImage = false;
        _errorMessage = "Unable to analyze the cabbage plant. Please try again.";
      });
    }
    
  } catch (e) {
    print("Error analyzing image: $e");
    setState(() {
      _isLoading = false;
      _predictionMade = true;
      _isCabbageImage = false;
      _errorMessage = "Error analyzing the image. Please try again.";
    });
  }
}

// Helper function to extract clean disease type from status
String extractDiseaseType(String status) {
  if (status.toUpperCase().contains('HEALTHY')) {
    return "Healthy";
  } else if (status.toUpperCase().contains('BLACK ROT')) {
    return "Black Rot";
  } else if (status.toUpperCase().contains('INSECT')) {
    return "Insect Damage";
  } else {
    // Extract other disease name if present
    final match = RegExp(r'DETECTED:\s*(.*)', caseSensitive: false).firstMatch(status);
    if (match != null && match.group(1)!.trim().isNotEmpty) {
      return match.group(1)!.trim();
    }
    return "Unknown Issue";
  }
}

List<String> getRecommendationsForCondition(String diseaseType, double severity) {
  if (diseaseType == "No Cabbage Detected") {
    return [
      "Take a clear photo: Ensure the cabbage plant is clearly visible in the frame.",
      "Use good lighting: Take photos in natural daylight for best results.",
      "Get close enough: Make sure leaves and any symptoms are clearly visible.",
      "Include multiple angles: If concerned about disease, take photos of different parts of the plant.",
      "Try again: Use the Camera button to take a new photo, or Gallery to select an existing image."
    ];
  } else if (diseaseType.toLowerCase().contains('black rot')) {
    final recommendations = [
      "Remove infected leaves: Carefully remove and destroy all infected plant parts to prevent spread.",
      "Improve air circulation: Ensure adequate spacing between plants to reduce humidity.",
      "Avoid overhead watering: Water at soil level to keep foliage dry.",
      "Apply copper fungicide: Use copper-based products approved for organic gardening.",
      "Practice crop rotation: Don't plant cabbage or related crops in the same area for 3 years."
    ];
    
    // Add severity-specific recommendations
    if (severity > 70) {
      recommendations.add("Consider removal: Severely infected plants should be completely removed and destroyed.");
    } else if (severity > 40) {
      recommendations.add("Isolate plants: Keep infected plants separated from healthy ones to limit spread.");
    }
    
    return recommendations;
  } else if (diseaseType.toLowerCase() == "healthy") {
    return [
      "Continue monitoring: Regular inspection keeps plants healthy.",
      "Maintain soil health: Add compost or organic matter to soil.",
      "Water consistently: Keep soil evenly moist but not waterlogged.",
      "Practice crop rotation: Prevents disease buildup in soil.",
      "Mulch appropriately: Helps maintain soil moisture and reduce weed competition."
    ];
  } else {
    // Generic recommendations for other issues
    return [
      "Identify specific issue: Consult local extension service for accurate diagnosis.",
      "Improve growing conditions: Ensure proper sunlight, water, and nutrients.",
      "Remove affected parts: Prune and dispose of damaged leaves and stems.",
      "Apply appropriate treatments: Based on specific diagnosis.",
      "Monitor closely: Check plants regularly for signs of improvement or decline."
    ];
  }
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
                      'Not a cabbage image,Take or select a photo of cabbage plants or leaves',
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
          'Cabbage Health Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
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
                              'Analyzing for Blackrot disease...',
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
                        'Black rot Detector',
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