import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:legal_bot/screens/home_screen.dart';
import 'package:legal_bot/widgets/custom_scaffold.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:legal_bot/screens/signin_screen.dart';
import 'package:legal_bot/theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart'; // Import Supabase package

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formSignupKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool agreePersonalData = true;

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

  Future<void> _signUpWithGoogle() async {
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


  Future<void> _signUpWithGitHub() async {
    try {
      // Perform GitHub OAuth sign-up
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'your-app://login-callback',  // Use your app’s deep link
      );

      // If sign-up is successful, navigate to ChatScreen
      if (response != null) {
        _showCustomSnackBar('GitHub Sign-Up successful!', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showCustomSnackBar('GitHub Sign-Up failed. Please try again.', Colors.red);
      }
    } catch (e) {
      _showCustomSnackBar('GitHub Sign-Up failed: $e', Colors.red);
    }
  }



  // Function to handle Supabase sign-up
// Function to handle Supabase sign-up
  Future<void> _signUpWithEmail() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (_formSignupKey.currentState!.validate() && agreePersonalData) {
      try {
        // Show loading indicator SnackBar
        _showCustomSnackBar('Signing up...', Colors.blue);

        final AuthResponse response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user != null) {
          // User registration successful, navigate to SignInScreen
          _showCustomSnackBar('Sign-up successful! Please sign in.', Colors.green);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          );
        } else {
          // Show an error dialog if user is not created
          _showDialog('Sign-Up Error', 'User could not be created. Please try again.');
        }
      } catch (e) {
        // Catch any error and display it using _showDialog
        _showDialog('Sign-Up Failed', 'Error: $e');
      }
    } else if (!agreePersonalData) {
      // Handle case where user hasn't agreed to personal data processing
      _showDialog('Agreement Required', 'Please agree to the processing of personal data.');
    }
  }

// Show custom SnackBar with background color and action
  void _showCustomSnackBar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white), // White text for contrast
      ),
      backgroundColor: color, // Set custom background color
      behavior: SnackBarBehavior.floating, // Make it float
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Rounded corners
      ),
      margin: const EdgeInsets.all(10.0), // Add margin to separate it from the screen edges
      duration: const Duration(seconds: 3), // How long the SnackBar will be visible
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          // User can dismiss the SnackBar
        },
      ),
    );

    // Display the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
                // get started form
                child: Form(
                  key: _formSignupKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: lightColorScheme.primary,
                        ),
                      ),
                      const SizedBox(
                        height: 40.0,
                      ),
                      // Full Name
                      TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Full name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Full Name'),
                          hintText: 'Enter Full Name',
                          hintStyle: const TextStyle(
                            color: Colors.black26,
                          ),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 25.0,
                      ),
                      // Email
                      TextFormField(
                        controller: _emailController,
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
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 25.0,
                      ),
                      // Password
                      TextFormField(
                        controller: _passwordController,
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
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 25.0,
                      ),
                      // Agree to personal data processing
                      Row(
                        children: [
                          Checkbox(
                            value: agreePersonalData,
                            onChanged: (bool? value) {
                              setState(() {
                                agreePersonalData = value!;
                              });
                            },
                            activeColor: lightColorScheme.primary,
                          ),
                          const Text(
                            'I agree to the processing of ',
                            style: TextStyle(
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            'Personal data',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: lightColorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 25.0,
                      ),
                      // Sign up button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signUpWithEmail, // Trigger sign-up function
                          child: const Text('Sign up'),
                        ),
                      ),
                      const SizedBox(
                        height: 30.0,
                      ),
                      // Sign up with social media
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
                        height: 30.0,
                      ),
                      // Social media icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: _signUpWithGoogle, // Google OAuth Sign-Up
                            child: Logo(Logos.google), // Google logo
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 25.0,
                      ),
                      // Already have an account?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Colors.black45,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (e) => const SignInScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign in',
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
