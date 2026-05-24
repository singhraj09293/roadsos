import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';

class UserSetupScreen extends ConsumerStatefulWidget {
  const UserSetupScreen({super.key});

  @override
  ConsumerState<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends ConsumerState<UserSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final String _selectedBloodGroup = 'O+';
  final List<Map<String, String>> _contacts = [];
  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];
  String _bloodGroup = 'O+';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
Future<void> _saveUser() async {
  setState(() => _isLoading = true);
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text.trim());
    await prefs.setString('userPhone', _phoneController.text.trim());
    await prefs.setString('bloodGroup', _bloodGroup);
    await prefs.setBool('isOnboarded', true);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        title: const Text(
          'Setup Your Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _saveUser();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          // Step 1 - Personal Info
          Step(
            title: const Text(
              'Personal Info',
              style: TextStyle(color: Colors.white),
            ),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Full Name', Icons.person),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Phone Number', Icons.phone),
                ),
              ],
            ),
          ),

          // Step 2 - Medical Info
          Step(
            title: const Text(
              'Medical Info',
              style: TextStyle(color: Colors.white),
            ),
            isActive: _currentStep >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Blood Group',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _bloodGroups.map((bg) {
                    final isSelected = _bloodGroup == bg;
                    return GestureDetector(
                      onTap: () => setState(() => _bloodGroup = bg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryRed
                              : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryRed
                                : Colors.white24,
                          ),
                        ),
                        child: Text(
                          bg,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Step 3 - Emergency Contacts
          Step(
            title: const Text(
              'Emergency Contacts',
              style: TextStyle(color: Colors.white),
            ),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                ..._contacts.map((c) => ListTile(
                      title: Text(
                        c['name']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${c['phone']} • ${c['relation']}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            setState(() => _contacts.remove(c)),
                      ),
                    )),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.primaryRed),
                  ),
                  icon: const Icon(Icons.add, color: AppTheme.primaryRed),
                  label: const Text(
                    'Add Contact',
                    style: TextStyle(color: AppTheme.primaryRed),
                  ),
                  onPressed: _showAddContactDialog,
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: AppTheme.primaryRed),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white38),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryRed),
      ),
    );
  }

  void _showAddContactDialog() {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final relationC = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Add Emergency Contact',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Name', Icons.person),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneC,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('Phone', Icons.phone),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationC,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Relation (e.g. Mom)', Icons.people),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _contacts.add({
                  'name': nameC.text.trim(),
                  'phone': phoneC.text.trim(),
                  'relation': relationC.text.trim(),
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}