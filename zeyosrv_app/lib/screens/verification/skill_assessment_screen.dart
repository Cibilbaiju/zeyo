import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:zeyosrv_app/core/constants/api_constants.dart';
import 'package:zeyosrv_app/core/theme/app_theme.dart';

class SkillAssessmentScreen extends StatefulWidget {
  final List<dynamic> services; // [{id, name, is_verified}, ...]
  final String? status; // Global match status
  
  const SkillAssessmentScreen({super.key, required this.services, this.status});

  @override
  State<SkillAssessmentScreen> createState() => _SkillAssessmentScreenState();
}

class _SkillAssessmentScreenState extends State<SkillAssessmentScreen> {
  Map<String, List<dynamic>> _questionsByService = {};
  bool _isLoading = true;
  // Answers: { serviceId: { questionId: answerIndex } }
  final Map<String, Map<String, int>> _answers = {}; 
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchBatchQuestions();
  }

  Future<void> _fetchBatchQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final serviceIds = widget.services.map((s) => s['id']).toList();

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/verification/questions/batch'),
        headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
        },
        body: json.encode({'serviceIds': serviceIds}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _questionsByService = Map<String, List<dynamic>>.from(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitAssessment() async {
    // Basic validation
    // Ensure at least one answer per service? Or all?
    // Let's enforce answering ALL questions for now.
    
    for (var serviceId in _questionsByService.keys) {
        final qs = _questionsByService[serviceId]!;
        for (var q in qs) {
            if (_answers[serviceId]?[q['id']] == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please answer all questions for ${widget.services.firstWhere((s) => s['id'] == serviceId)['name']}')),
                );
                return;
            }
        }
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/verification/submit-assessment/batch'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'submissions': _answers, 
        }),
      );

      final result = json.decode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        if (mounted) {
           // Show summary dialog
           final results = result['results'] as Map<String, dynamic>;
           final passedCount = results.values.where((r) => r['passed'] == true).length;
           
           _showResultDialog(
               passedCount > 0 ? 'Assessment Complete' : 'Assessment Failed', 
               'You passed $passedCount out of ${widget.services.length} skills.',
               passedCount > 0
           );
        }
      } else {
        throw Exception('${result['error'] ?? 'Submission failed'}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showResultDialog(String title, String message, bool somePassed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.pop(context); // Go back to status screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Skill Assessment', style: GoogleFonts.inter(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ...widget.services.map((service) {
                    final sId = service['id'];
                    final sName = service['name'];
                    final questions = _questionsByService[sId] ?? [];

                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(sName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ),
                            if (questions.isEmpty) 
                                const Text("No questions available."),
                                
                            ...List.generate(questions.length, (index) {
                                final q = questions[index];
                                final qId = q['id'];
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Q${index + 1}. ${q['question_text']}',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                                        ),
                                        const SizedBox(height: 12),
                                        ...List<Widget>.generate((q['options'] as List).length, (optIndex) {
                                          final option = q['options'][optIndex];
                                          return RadioListTile<int>(
                                            title: Text(option),
                                            value: optIndex,
                                            groupValue: _answers[sId]?[qId],
                                            onChanged: (val) {
                                                setState(() {
                                                    if (_answers[sId] == null) _answers[sId] = {};
                                                    _answers[sId]![qId] = val!;
                                                });
                                            },
                                            contentPadding: EdgeInsets.zero,
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                            }),
                            const Divider(height: 30),
                        ],
                    );
                }).toList(),

                Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAssessment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Submit All Assessments', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
              ],
            ),
    );
  }
}
