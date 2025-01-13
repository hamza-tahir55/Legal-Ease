import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:legal_bot/screens/signin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import flutter_markdown package
import 'package:shared_preferences/shared_preferences.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _messages = [];

  final String chatApiUrl = 'https://legal-ease-g4fjhebbfdbaccet.canadacentral-01.azurewebsites.net/chat'; // For sending messages
  final String uploadApiUrl = 'https://legal-ease-g4fjhebbfdbaccet.canadacentral-01.azurewebsites.net/rpr'; // For uploading PDFs
  bool isTyping = false;
  final ScrollController _scrollController = ScrollController();
  String? _userName; // To store the user's name
  String? _userAvatarUrl; // To store the user's avatar URL
  bool _isUrdu = false;  // To track language preference


  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the screen initializes
    _loadMessages(); // Load chat messages from SharedPreferences
  }

  // Function to load messages from SharedPreferences
  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedMessages = prefs.getString('chatMessages');
    if (savedMessages != null) {
      List<Map<String, String>> loadedMessages = List<Map<String, String>>.from(
          jsonDecode(savedMessages).map((message) => Map<String, String>.from(message))
      );
      setState(() {
        _messages = loadedMessages;
      });
    }
  }

  // Function to save messages to SharedPreferences
  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    String messagesJson = jsonEncode(_messages);
    await prefs.setString('chatMessages', messagesJson);
  }



  void _showCustomSnackBar(String message, Color backgroundColor) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
            color: Colors.white), // White text for readability
      ),
      backgroundColor: backgroundColor,
      // Custom background color
      behavior: SnackBarBehavior.floating,
      // Floating behavior for better visibility
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            10.0), // Rounded corners for a modern look
      ),
      margin: const EdgeInsets.all(10.0),
      // Add margin around the SnackBar
      duration: const Duration(seconds: 2),
      // Display for 4 seconds
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white, // Dismiss text color
        onPressed: () {
          // Optional: Action to dismiss the SnackBar
        },
      ),
    );

    // Show the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Fetch user data (from Supabase or Google Sign-In)
  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser; // Replace with your auth method
    if (user != null) {
      setState(() {
        _userName = user.userMetadata?['name'] ?? 'User'; // Get user's name
        _userAvatarUrl = user.userMetadata?['avatar_url']; // Get user's avatar URL
      });
    }
  }


// Function to send the message and get a response from the API
  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({"sender": "user", "message": message});
      isTyping = true; // Show typing indicator
    });
    _saveMessages();
    // Scroll to the bottom when the user sends a message
    _scrollToBottom();

    try {
      // Simulate a delay to show typing animation (for demonstration purposes)
      await Future.delayed(
          const Duration(seconds: 1)); // Add a small delay for typing animation

      // API Call with language toggle
      final response = await http.post(
        Uri.parse(chatApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'language': _isUrdu ? 'ur' : 'en',  // Add language parameter based on toggle
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _messages.add({"sender": "bot", "message": responseData['response']});
          isTyping = false; // Stop typing indicator
        });
        _saveMessages();
        // Scroll to the bottom after bot's response
        _scrollToBottom();
      } else {
        setState(() {
          _messages.add({
            "sender": "bot",
            "message": "Error: Failed to get response from server"
          });
          isTyping = false; // Stop typing indicator
        });
        _scrollToBottom(); // Scroll even in case of error
      }
    } catch (e) {
      setState(() {
        _messages.add({"sender": "bot", "message": "Error: $e"});
        isTyping = false; // Stop typing indicator
      });
      _scrollToBottom();
    }
  }


  // Function to scroll to the bottom of the chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }


  Future<void> _pickAndUploadPDF() async {
    try {
      // Let the user pick a PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String fileName = result.files.single.name;

        print('Selected file path: $filePath');
        print('Selected file name: $fileName');

        // Show the file in the chat immediately
        setState(() {
          _messages.add({
            "sender": "user",
            "message": "PDF: $fileName",
            // Add message to represent the PDF file
            "filePath": filePath
            // Include file path for future use if needed
          });
        });

        _scrollToBottom(); // Scroll to the bottom after showing the PDF message

        // Show a loading indicator while uploading the file
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
          const Center(child: CircularProgressIndicator()),
        );

        try {
          // Create multipart request to uploadApiUrl
          var request = http.MultipartRequest('POST', Uri.parse(uploadApiUrl));
          request.fields['message'] = 'Uploaded a PDF file'; // Adjust as needed
          request.files.add(await http.MultipartFile.fromPath(
              'file', filePath, filename: fileName));

          print('Multipart request created with fields: ${request.fields}');
          print('Number of files in request: ${request.files.length}');
          print('File details: ${request.files.first.filename}, ${request.files
              .first.length} bytes');

          // Send the request
          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);

          Navigator.of(context).pop(); // Remove the loading indicator

          print('Upload Response status: ${response.statusCode}');
          print('Upload Response body: ${response.body}');

          if (response.statusCode == 200) {
            // Optionally, inform the user about the successful upload
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF uploaded successfully.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error uploading PDF: ${response.body}')),
            );
          }
        } catch (e) {
          Navigator.of(context).pop(); // Remove the loading indicator
          print('Error uploading PDF: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading PDF: $e')),
          );
        }
      } else {
        // User canceled the picker
        print('File picking canceled.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File picking canceled.')),
        );
      }
    } catch (e) {
      // Handle errors, possibly show a dialog or a snackbar
      print('Error picking/uploading PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking/uploading PDF: $e')),
      );
    }
  }

  void _signOut() async {
    await Supabase.instance.client.auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chatMessages');

    // Clear the current messages in the state
    setState(() {
      _messages.clear();
    });



    print('User signed out');

    // Navigate to the SignInScreen after signing out
    Future.delayed(const Duration(seconds: 0), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    });

    // Show a SnackBar to confirm the user has signed out
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'User signed out',
          style: TextStyle(
              color: Colors.white), // White text for better readability
        ),
        backgroundColor: Colors.red,
        // Red background for sign-out notification
        behavior: SnackBarBehavior.floating,
        // Floating appearance
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              10.0), // Rounded corners for modern appearance
        ),
        margin: const EdgeInsets.all(10.0),
        // Margin for spacing
        duration: const Duration(seconds: 3),
        // Custom display duration
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            // Optional: Action to dismiss the SnackBar
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.blue.withOpacity(0.9),
        title: const Text(
          "Legal AI",
          style: TextStyle(
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.bold
          ),
        ),
        leading: PopupMenuButton<int>(
          icon: const Icon(Icons.account_circle_rounded, color: Colors.white), // Use an icon for the dropdown
          onSelected: (value) {
            if (value == 1) {
              _signOut();  // Call sign out function when selected
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("English", style: TextStyle(fontSize: 14)),  // Left side label (Urdu)
                  Switch(
                    value: _isUrdu,
                    onChanged: (value) {
                      setState(() {
                        _isUrdu = value;  // Update the language preference
                      });
                      Navigator.pop(context);  // Close the dropdown when toggled
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.withOpacity(0.5),
                    activeTrackColor: Colors.green.withOpacity(0.5),
                  ),
                  const Text("Urdu", style: TextStyle(fontSize: 14)),  // Right side label (English)
                ],
              ),
            ),
            const PopupMenuDivider(),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_image.png'),
            // Set the path of your background image
            fit: BoxFit.cover,
            // Make sure the image covers the whole screen
            opacity: 0.2, // Optional: control the opacity of the background image
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && isTyping) {
                        return Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundImage: AssetImage(
                                    'assets/images/bot.png'), // Bot image
                                radius: 20,
                              ),
                              const SizedBox(width: 8),
                              SpinKitThreeBounce(
                                  color: Colors.grey, size: 20.0),
                            ],
                          ),
                        );
                      }
                      final message = _messages[index];
                      return Container(
                        alignment: message['sender'] == 'user' ? Alignment
                            .centerRight : Alignment.centerLeft,
                        padding: const EdgeInsets.all(0),
                        child: Bubble(
                          message: message['message']!,
                          isUserMessage: message['sender'] == 'user',
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.blue.withOpacity(0.9),
                            hintText: "Enter your message",
                            hintStyle: TextStyle(
                                color: Colors.white.withOpacity(1)),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 20.0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              // Rounded corners when enabled
                              borderSide: BorderSide.none, // No border
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              // Rounded corners when focused
                              borderSide: BorderSide.none, // No border
                            ),
                          ),
                          onTap: () {
                            _scrollToBottom();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: _pickAndUploadPDF, // Upload PDF button
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          final message = _messageController.text;
                          if (message.isNotEmpty) {
                            _sendMessage(message);
                            _messageController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  }
class Bubble extends StatelessWidget {
  final String message;
  final bool isUserMessage;
  final String? filePath;  // Add file path to handle PDF

  const Bubble({
    Key? key,
    required this.message,
    required this.isUserMessage,
    this.filePath,  // File path for PDF
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isPdfMessage = message.startsWith('PDF: '); // Check if the message is a PDF

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUserMessage) ...[
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/bot.png'),
            radius: 20,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isUserMessage ? Colors.blueAccent : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: isUserMessage ? Radius.circular(16) : Radius.zero,
                bottomRight: isUserMessage ? Radius.zero : Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: isPdfMessage
                ? Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red), // PDF icon
                const SizedBox(width: 8),
                Text(
                  message.replaceFirst('PDF: ', ''), // Display file name
                  style: TextStyle(
                    color: isUserMessage ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            )
                : MarkdownBody(
              data: message,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: isUserMessage ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
