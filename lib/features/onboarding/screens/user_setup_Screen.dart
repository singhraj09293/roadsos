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
  final List<Map<String, String>> _contacts = [];
  String _bloodGroup = 'O+';
  bool _isLoading = false;
  int _page = 0;

  final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text.trim());
    await prefs.setString('userPhone', _phoneController.text.trim());
    await prefs.setString('bloodGroup', _bloodGroup);
    await prefs.setBool('isOnboarded', true);
    await prefs.setStringList(
      'emergencyContacts',
      _contacts
          .map((c) => '${c['name']}|${c['phone']}|${c['relation']}')
          .toList(),
    );
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _next() {
    if (_page == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    if (_page < 2)
      setState(() => _page++);
    else
      _saveUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(page: _page),
            Expanded(
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: [
                    _Page1(nameC: _nameController, phoneC: _phoneController),
                    _Page2(
                      bloodGroup: _bloodGroup,
                      bloodGroups: _bloodGroups,
                      onSelect: (bg) => setState(() => _bloodGroup = bg),
                    ),
                    _Page3(
                      contacts: _contacts,
                      onAdd: (c) => setState(() => _contacts.add(c)),
                      onRemove: (c) => setState(() => _contacts.remove(c)),
                      inputDecoration: _inputDec,
                    ),
                  ][_page],
                ),
              ),
            ),
            _BottomBar(
              page: _page,
              isLoading: _isLoading,
              onBack: _page > 0 ? () => setState(() => _page--) : null,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryRed),
        ),
      );
}

// ── Top progress bar ──────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int page;
  const _TopBar({required this.page});

  @override
  Widget build(BuildContext context) {
    final titles = ['Personal Info', 'Medical Info', 'Emergency Contacts'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
                3,
                (i) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              i <= page ? AppTheme.primaryRed : Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
          ),
          const SizedBox(height: 24),
          Text(
            'Step ${page + 1} of 3',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            titles[page],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle(page),
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _subtitle(int p) => [
        'Tell us a bit about yourself',
        'This helps rescuers assist you better',
        'They will be alerted in an emergency',
      ][p];
}

// ── Bottom bar ────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int page;
  final bool isLoading;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const _BottomBar(
      {required this.page,
      required this.isLoading,
      required this.onBack,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (onBack != null) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onBack,
                child:
                    const Text('Back', style: TextStyle(color: Colors.white54)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isLoading ? null : onNext,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      page < 2 ? 'Continue →' : 'Get Started',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 1: Personal Info ─────────────────────────────────────────
class _Page1 extends StatelessWidget {
  final TextEditingController nameC, phoneC;
  const _Page1({required this.nameC, required this.phoneC});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryRed.withOpacity(0.1),
            ),
            child:
                const Icon(Icons.person, color: AppTheme.primaryRed, size: 48),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: nameC,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Full Name',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.person_outline, color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryRed)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneC,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Phone Number',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.phone_outlined, color: Colors.white38),
              prefixText: '+91  ',
              prefixStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.primaryRed)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Blood Group ───────────────────────────────────────────
class _Page2 extends StatelessWidget {
  final String bloodGroup;
  final List<String> bloodGroups;
  final ValueChanged<String> onSelect;
  const _Page2(
      {required this.bloodGroup,
      required this.bloodGroups,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryRed.withOpacity(0.1),
            ),
            child: const Icon(Icons.bloodtype,
                color: AppTheme.primaryRed, size: 48),
          ),
          const SizedBox(height: 40),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: bloodGroups.map((bg) {
              final selected = bloodGroup == bg;
              return GestureDetector(
                onTap: () => onSelect(bg),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryRed
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? AppTheme.primaryRed : Colors.white12),
                  ),
                  child: Center(
                    child: Text(
                      bg,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Emergency Contacts ────────────────────────────────────
class _Page3 extends StatelessWidget {
  final List<Map<String, String>> contacts;
  final ValueChanged<Map<String, String>> onAdd;
  final ValueChanged<Map<String, String>> onRemove;
  final InputDecoration Function(String, IconData) inputDecoration;
  const _Page3(
      {required this.contacts,
      required this.onAdd,
      required this.onRemove,
      required this.inputDecoration});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...contacts.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person,
                          color: AppTheme.primaryRed, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['name']!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          Text('${c['phone']} • ${c['relation']}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white38, size: 20),
                      onPressed: () => onRemove(c),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showAddDialog(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.primaryRed.withOpacity(0.5),
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppTheme.primaryRed),
                  SizedBox(width: 8),
                  Text('Add Emergency Contact',
                      style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final relationC = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Contact', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(nameC, 'Name', Icons.person_outline),
            const SizedBox(height: 12),
            _field(phoneC, 'Phone', Icons.phone_outlined, TextInputType.phone),
            const SizedBox(height: 12),
            _field(relationC, 'Relation (e.g. Mom)', Icons.people_outline),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
            onPressed: () {
              if (nameC.text.isNotEmpty && phoneC.text.isNotEmpty) {
                onAdd({
                  'name': nameC.text.trim(),
                  'phone': phoneC.text.trim(),
                  'relation': relationC.text.trim()
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      [TextInputType? type]) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}
