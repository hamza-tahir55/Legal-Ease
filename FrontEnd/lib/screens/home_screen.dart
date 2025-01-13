import 'package:flutter/material.dart';
import 'package:legal_bot/screens/chat_screen.dart'; // For normal conversation screen
import 'package:legal_bot/screens/guidance_screen.dart'; // For guidance screen
import 'package:legal_bot/screens/pdf_list_screen.dart'; // For saved PDF management screen
import 'package:legal_bot/screens/lawyer_list_screen.dart'; // For lawyer directory screen
import 'package:legal_bot/screens/signin_screen.dart'; // For sign-in screen
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'CommunityScreen.dart'; // Import supabase for user data

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: false,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          FutureBuilder(
            future: _fetchUserData(), // Fetch user data (name and avatar)
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(); // Show a loader while fetching data
              }

              final user = snapshot.data as Map<String, String>?;

              if (user == null) {
                return const SizedBox.shrink(); // Return nothing if user data is not available
              }

              String? userName = user['name'];
              String? userAvatarUrl = user['avatar_url'];

              return Row(
                children: [
                  if (userName != null)
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  const SizedBox(width: 8), // Space between text and avatar
                  CircleAvatar(
                    backgroundImage: userAvatarUrl != null
                        ? NetworkImage(userAvatarUrl)  // User's avatar image
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    radius: 20,
                  ),
                  const SizedBox(width: 16), // Space on the right
                ],
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer header with the user's avatar and name
            FutureBuilder(
              future: _fetchUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const DrawerHeader(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final user = snapshot.data as Map<String, String>?;
                if (user == null) {
                  return const DrawerHeader(
                    child: Center(child: Text('User not logged in')),
                  );
                }

                String userName = user['name'] ?? 'User';
                String? userAvatarUrl = user['avatar_url'];

                return DrawerHeader(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: userAvatarUrl != null
                            ? NetworkImage(userAvatarUrl)
                            : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        radius: 30,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Community option in the drawer
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Community'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommunityScreen()), // Navigate to the Community screen
                );
              },
            ),
            // ListTile for "Sign Out"
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Sign Out'),
              onTap: () async {
                // Sign out logic
                await Supabase.instance.client.auth.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()), // Navigate to sign-in screen
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/paper_background.png'),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Welcome to Legal AI',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 50),

              // Option 1: Normal Conversation with PDF Context
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 6,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: const [
                          Icon(Icons.chat, size: 40, color: Colors.blueAccent),
                          SizedBox(height: 10),
                          Text(
                            'Normal Conversation with PDF Context',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Option 2: Guidance for Victims and Case Management
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 6,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GuidanceScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: const [
                          Icon(Icons.gavel, size: 40, color: Colors.greenAccent),
                          SizedBox(height: 10),
                          Text(
                            'Guidance for Victims and Case Management',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Option 3: View and Manage Saved PDFs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 6,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PDFListScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: const [
                          Icon(Icons.folder, size: 40, color: Colors.orangeAccent),
                          SizedBox(height: 10),
                          Text(
                            'View and Manage Saved PDFs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Option 4: Contact Lawyers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 6,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LawyerListScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: const [
                          Icon(Icons.account_balance, size: 40, color: Colors.purpleAccent),
                          SizedBox(height: 10),
                          Text(
                            'Contact Lawyers',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, String>?> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      return {
        'name': user.userMetadata?['name'] ?? 'User',
        'avatar_url': user.userMetadata?['avatar_url'],
      };
    }
    return null;
  }
}
