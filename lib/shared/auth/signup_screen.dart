import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/country_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final CountryService _countryService = CountryService();

  String? _gender;
  String? _country;
  DateTime? _dob;
  List<String> _countries = [];
  bool _loadingCountries = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final countries = await _countryService.getCountries();
    if (!mounted) return;
    setState(() {
      _countries = countries;
      _loadingCountries = false;
    });
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  String _formatDob(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _authService.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      firstname: _firstnameController.text,
      lastname: _lastnameController.text,
      country: _country,
      gender: _gender,
      dob: _dob == null ? null : _formatDob(_dob!),
    );
    if (!mounted) return;
    if (result == null) {
      // Signup successful, StreamBuilder in auth gate will navigate automatically
      Navigator.pop(context);
    } else {
      setState(() {
        _loading = false;
        _error = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _firstnameController,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastnameController,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password (min 6 characters)'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _loadingCountries
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Loading countries...'),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _country,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Country (optional)'),
                        items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (value) => setState(() => _country = value),
                      ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender (optional)'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickDob,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth (optional)',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(_dob == null ? 'Select date' : _formatDob(_dob!)),
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
