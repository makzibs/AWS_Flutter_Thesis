import 'package:demo_flutter_aws/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class ConfirmSignUpScreen extends StatefulWidget {
  final String email;
  const ConfirmSignUpScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ConfirmSignUpScreen> createState() => _ConfirmSignUpScreenState();
}

class _ConfirmSignUpScreenState extends State<ConfirmSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await _authController.confirmSignUp(
        email: widget.email,
        confirmationCode: _otpController.text,
        context: context,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.shield_outlined, color: Color(0xFF0D47A1), size: 80),
              const SizedBox(height: 40),
              Text(
                'Enter OTP',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'An OTP has been sent to your email:\n${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 50),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 16),
                decoration: const InputDecoration(
                  hintText: '------',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the OTP';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}