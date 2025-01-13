import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:legal_bot/screens/home_screen.dart';
import 'package:legal_bot/widgets/custom_scaffold.dart';
import 'package:legal_bot/screens/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/theme.dart';
import 'chat_screen.dart';
import 'forget_password.dart'; // Import the ForgetPasswordScreen

import 'package:google_sign_in/google_sign_in.dart'; // Added this




class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formSignInKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool rememberPassword = true;

  void _showCustomSnackBar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white), // White text for better readability
      ),
      backgroundColor: color, // Custom background color
      behavior: SnackBarBehavior.floating, // Floating appearance
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Rounded corners
      ),
      margin: const EdgeInsets.all(10.0), // Margin for spacing
      duration: const Duration(seconds: 3), // Custom display duration
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          // Optional action for the user to dismiss the SnackBar
        },
      ),
    );

    // Display the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

// Function to handle GitHub Sign-In
  Future<void> _signInWithGitHub() async {
    try {
      // Ensure user is logged out first to prompt the account selection again
      await Supabase.instance.client.auth.signOut();

      // Use OAuthProvider.github for GitHub Sign-In
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.github,  // Correct usage for GitHub OAuth
      );

      if (response != null) {
        _showCustomSnackBar('Sign-in successful with GitHub!', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showCustomSnackBar('GitHub Sign-In Error: Please try again.', Colors.red);
      }
    } catch (e) {
      _showCustomSnackBar('GitHub Sign-In failed: $e', Colors.red);
    }
  }

  // Function to handle Google Sign-In

  Future<void> _signInWithGoogle() async {
    try {
      // Initialize GoogleSignIn with necessary scopes and web client ID
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
        clientId: '741437834313-3nrv5rid6t5iesclck72o1v52i18o0cp.apps.googleusercontent.com', // Replace with actual Web Client ID
      );

      // Force sign out to clear any cached sessions
      await googleSignIn.signOut();

      // Attempt to sign in the user
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in process
        print('Google Sign-In was canceled');
        return;
      }

      // Retrieve Google Sign-In authentication tokens
      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

      // Access tokens
      final accessToken = googleAuth?.accessToken;
      final idToken = googleAuth?.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Failed to retrieve Google authentication tokens';
      }

      // Proceed with your server-side authentication using the tokens
      print('Access Token: $accessToken');
      print('ID Token: $idToken');

      // Sign in to Supabase using the obtained ID token and access token
      final AuthResponse response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        accessToken: accessToken!,
      );

      if (response.session != null) {
        _showCustomSnackBar('Sign-in successful with Google!', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showCustomSnackBar('Google Sign-In Error: Please try again.', Colors.red);
      }

    } catch (e) {
      print('Google Sign-In failed: $e');
    }
  }



  // Function to handle sign-in
  // Updated function to handle Supabase authentication
// Updated function to handle Supabase authentication and navigate on success
  Future<void> _signInWithEmail() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (_formSignInKey.currentState!.validate()) {
      // Show a loading indicator while signing in
      _showCustomSnackBar('Signing in...', Colors.blue);

      try {
        // Attempt to sign in the user
        final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.session != null) {
          // If sign-in is successful, navigate to ChatScreen
          _showCustomSnackBar('Sign-in successful!', Colors.green);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // If there is no session, show an error SnackBar
          _showCustomSnackBar('Sign-In Error: Please try again.', Colors.red);
        }
      } catch (e) {
        // Catch any error and display the error message in a SnackBar
        _showCustomSnackBar('Incorrect email or password. Please try again.', Colors.red);

        // Optionally clear form fields after an error
        _emailController.clear();
        _passwordController.clear();
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(
            flex: 1,
            child: SizedBox(
              height: 10,
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: lightColorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        height: 40.0,
                      ),
                      TextFormField(
                        controller: _emailController, // Added controller for email
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Email'),
                          hintText: 'Enter Email',
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12, // Default border color
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12, // Default border color
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 25.0,
                      ),
                      TextFormField(
                        controller: _passwordController, // Added controller for password
                        obscureText: true,
                        obscuringCharacter: '*',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Password';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Password'),
                          hintText: 'Enter Password',
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12, // Default border color
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12, // Default border color
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 25.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberPassword,
                                onChanged: (bool? value) {
                                  setState(() {
                                    rememberPassword = value!;
                                  });
                                },
                                activeColor: lightColorScheme.primary,
                              ),
                              const Text(
                                'Remember me',
                                style: TextStyle(
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              // Navigate to ForgetPasswordScreen when tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgetPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Forget password?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lightColorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 25.0,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signInWithEmail, // Sign in with Supabase
                          child: const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(
                        height: 25.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                            child: Text(
                              'Sign up with',
                              style: TextStyle(
                                color: Colors.black45,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 25.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: _signInWithGoogle, // Trigger Google Sign-In
                            child: Logo(Logos.google), // Google logo
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 25.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              color: Colors.black45,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (e) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lightColorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
