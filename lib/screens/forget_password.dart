import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgetPasswordScreen extends StatefulWidget {
  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (_formKey.currentState!.validate()) {
      try {
        await supabase.auth.resetPasswordForEmail(email);
        _showDialog(
            'Reset Email Sent', 'Check your email to reset your password.');
      } catch (error) {
        _showDialog('Error', error.toString());
      }
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Center( // Center the form
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Minimize the space taken by the column
              mainAxisAlignment: MainAxisAlignment.center,
              // Center content vertically
              crossAxisAlignment: CrossAxisAlignment.center,
              // Center content horizontally
              children: <Widget>[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(), // Added border for better visibility
                  ),
                  validator: (value) {
                    if (value!.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Space between text field and button
                SizedBox(
                  width: double.infinity, // Make the button take full width
                  child: ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text('Send Reset Email'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}