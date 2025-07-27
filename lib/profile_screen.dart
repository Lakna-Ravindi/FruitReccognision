import 'package:flutter/material.dart';
import 'fruit_recommend_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  int age = 0;
  String gender = 'Female';
  String fitnessGoal = 'None';
  String dietaryPreference = 'None';
  List<String> healthConditions = [];

  final List<String> healthOptions = ['Diabetes', 'Allergies', 'Hypertension'];

  void _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = {
        "name": name,
        "age": age,
        "gender": gender,
        "dietaryPreference": dietaryPreference,
        "healthConditions": healthConditions,
        "fitnessGoal": fitnessGoal,
      };

      final url = Uri.parse(
        'http://127.0.0.1:5001/api/profile',
      ); // Replace <YOUR-IP>

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(profile),
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FruitRecommendScreen(profile: responseData),
            ),
          );
        } else {
          final errorData = json.decode(response.body);
          _showErrorDialog(errorData['error'] ?? 'Something went wrong');
        }
      } catch (e) {
        _showErrorDialog('Failed to connect to the server');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text("Error"),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FCEB),
      appBar: AppBar(
        title: const Text("Create Profile"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCard(
                children: [
                  _buildSectionTitle("Basic Information", Icons.person),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: _inputDecoration("Name"),
                    onChanged: (val) => name = val,
                    validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
  decoration: _inputDecoration("Age"),
  keyboardType: TextInputType.number,
  onChanged: (val) {
    final parsed = int.tryParse(val);
    if (parsed != null && parsed > 0) {
      age = parsed;
    } else {
      age = 0; // fallback
    }
  },
  validator: (val) {
    if (val == null || val.isEmpty) return 'Enter your age';
    final parsed = int.tryParse(val);
    if (parsed == null || parsed <= 0) return 'Enter a valid age';
    return null;
  },
),

                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: _inputDecoration("Gender"),
                    items:
                        ['Female', 'Male', 'Other']
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => gender = val!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCard(
                children: [
                  _buildSectionTitle("Preferences", Icons.favorite),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: dietaryPreference,
                    decoration: _inputDecoration("Dietary Preference"),
                    items:
                        ['None', 'Vegan', 'Keto', 'Vegetarian']
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)),
                            )
                            .toList(),
                    onChanged:
                        (val) => setState(() => dietaryPreference = val!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: fitnessGoal,
                    decoration: _inputDecoration("Fitness Goal"),
                    items:
                        ['None', 'Weight Loss', 'Muscle Gain']
                            .map(
                              (f) => DropdownMenuItem(value: f, child: Text(f)),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => fitnessGoal = val!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCard(
                children: [
                  _buildSectionTitle(
                    "Health Conditions",
                    Icons.health_and_safety,
                  ),
                  const SizedBox(height: 8),
                  ...healthOptions.map((condition) {
                    return CheckboxListTile(
                      title: Text(condition),
                      activeColor: Colors.green.shade700,
                      value: healthConditions.contains(condition),
                      onChanged: (selected) {
                        setState(() {
                          if (selected!) {
                            healthConditions.add(condition);
                          } else {
                            healthConditions.remove(condition);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text("Continue", style: TextStyle(fontSize: 16)),
                  onPressed: _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.green.shade200,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: children),
      ),
    );
  }
}
