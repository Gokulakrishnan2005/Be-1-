import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  DateTime _selectedDob = DateTime(2000, 1, 1);
  String _selectedGender = '';

  void _complete() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final storage = context.read<StorageService>();
    await storage.setUserName(name);
    await storage.setUserDob(_selectedDob);
    if (_selectedGender.isNotEmpty) {
      await storage.setUserGender(_selectedGender);
    }
    await storage.setOnboardingComplete();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.pureCeramicWhite,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const Text(
                'Welcome.',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.systemBlack,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Let\'s set up your identity.',
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.systemGray,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48),

              // Name field
              const Text('First Name',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.systemGray)),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Enter your first name',
                padding: const EdgeInsets.all(16),
                style:
                    const TextStyle(fontSize: 18, color: AppTheme.systemBlack),
                decoration: BoxDecoration(
                  color: AppTheme.systemGray6,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 32),

              // DOB
              const Text('Date of Birth',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.systemGray)),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDob,
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(1940),
                  onDateTimeChanged: (date) {
                    setState(() => _selectedDob = date);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Gender (optional)
              const Text('Gender (Optional)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.systemGray)),
              const SizedBox(height: 8),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _selectedGender.isEmpty ? null : _selectedGender,
                children: const {
                  'Male': Text('Male', style: TextStyle(fontSize: 14)),
                  'Female': Text('Female', style: TextStyle(fontSize: 14)),
                  'Other': Text('Other', style: TextStyle(fontSize: 14)),
                },
                onValueChanged: (val) {
                  setState(() => _selectedGender = val ?? '');
                },
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _complete,
                  borderRadius: BorderRadius.circular(14),
                  child: const Text('Continue',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
