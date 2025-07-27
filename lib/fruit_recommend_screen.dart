import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'fruit_predictor_page.dart'; // Make sure the path is correct

class FruitRecommendScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const FruitRecommendScreen({super.key, required this.profile});

  @override
  State<FruitRecommendScreen> createState() => _FruitRecommendScreenState();
}

class _FruitRecommendScreenState extends State<FruitRecommendScreen> {
  List<Map<String, dynamic>> recommendations = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    print("Profile sent to backend: ${widget.profile}");

    if (widget.profile.containsKey('recommendations')) {
      setState(() {
        recommendations = List<Map<String, dynamic>>.from(
          widget.profile['recommendations'],
        );
        isLoading = false;
      });
      return;
    }

    Map<String, dynamic> profileData;
    if (widget.profile.containsKey('profile')) {
      profileData = widget.profile['profile'];
    } else {
      profileData = widget.profile;
    }

    if (!profileData.containsKey('name') ||
        profileData['name'].toString().trim().isEmpty) {
      setState(() {
        hasError = true;
        errorMessage = 'Profile is missing a name.';
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('http://192.168.8.139:5001/recommend_fruits');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('recommendations')) {
          setState(() {
            recommendations = List<Map<String, dynamic>>.from(
              data['recommendations'],
            );
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            errorMessage = 'No recommendations found.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          errorMessage = 'Error: ${response.statusCode} - ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Failed to connect to the server: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Fruit Recommendations'),
        backgroundColor: Colors.green[600],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : hasError
                    ? _buildErrorUI()
                    : recommendations.isEmpty
                    ? const Center(child: Text('No recommendations available'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: recommendations.length,
                      itemBuilder: (context, index) {
                        final rec = recommendations[index];
                        final nutrition = rec['nutrition'] ?? {};
                        final benefits = rec['nutritional_benefits'] ?? [];

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rec['fruit'] ?? 'Unknown Fruit',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildNutritionItem(
                                      "Calories",
                                      nutrition['calories'],
                                    ),
                                    _buildNutritionItem(
                                      "Sugar",
                                      "${nutrition['sugar']}g",
                                    ),
                                    _buildNutritionItem(
                                      "Vitamin C",
                                      "${nutrition['vitaminC']}mg",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Reason: ${rec['reason'] ?? 'No reason provided'}",
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "Nutritional Benefits:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...benefits.map<Widget>(
                                  (b) => Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      bottom: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          "• ",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        Expanded(child: Text(b)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FruitPredictorPage(),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Predict Fruit from Image"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, dynamic value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value != null ? value.toString() : 'N/A',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                _fetchRecommendations();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
