import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class GuidanceScreen extends StatefulWidget {
  const GuidanceScreen({Key? key}) : super(key: key);

  @override
  _GuidanceScreenState createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _messages = [];
  String? conversationId;
  String currentQuestion = "";
  int currentIndex = 0;
  bool isTyping = false;
  String? finalCaseSummary;

  final ScrollController _scrollController = ScrollController();

  // API Endpoints
  final String startConversationApiUrl = 'https://legal-ease-g4fjhebbfdbaccet.canadacentral-01.azurewebsites.net/start-conversation';
  final String answerQuestionApiUrl = 'https://legal-ease-g4fjhebbfdbaccet.canadacentral-01.azurewebsites.net/answer-question';
  final String generateResponseApiUrl = 'https://legal-ease-g4fjhebbfdbaccet.canadacentral-01.azurewebsites.net/generate-response';
  final String followUpApiUrl = 'https://legal-ease-g4fjhebbfdbaccet.canadacentral-01.azurewebsites.net/follow-up';

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({"sender": "user", "message": message});
      isTyping = true;
    });

    _scrollToBottom();

    try {
      if (conversationId == null) {
        // Start a new conversation
        final response = await http.post(
          Uri.parse(startConversationApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message}),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          setState(() {
            conversationId = responseData["conversation_id"];
            currentQuestion = responseData["message"];
            currentIndex = responseData["current_index"] ?? 0;
            _messages.add({"sender": "bot", "message": responseData["message"]});
          });
        } else {
          _showCustomSnackBar("Error: ${response.body}", Colors.red);
        }
      } else if (currentQuestion.toLowerCase().contains("all questions answered")) {
        // Handle follow-up questions
        final followUpResponse = await http.post(
          Uri.parse(followUpApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'question': message, 'conversation_id': conversationId}),
        );
        if (followUpResponse.statusCode == 200) {
          final responseData = jsonDecode(followUpResponse.body);
          setState(() {
            _messages.add({"sender": "bot", "message": responseData["response"]});
          });
        } else {
          _showCustomSnackBar("Error: ${followUpResponse.body}", Colors.red);
        }
      } else {
        // Answer a question
        final response = await http.post(
          Uri.parse(answerQuestionApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'answer': message,
            'current_index': currentIndex,
            'conversation_id': conversationId
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final botMessage = responseData["message"];

          setState(() {
            currentQuestion = responseData["message"];
            currentIndex = responseData["current_index"] ?? currentIndex;
            _messages.add({"sender": "bot", "message": botMessage});
          });

          if (botMessage.toLowerCase().contains("case data gathered")) {
            await _generateResponse();
          }
        } else {
          _showCustomSnackBar("Error: ${response.body}", Colors.red);
        }
      }
    } catch (e) {
      _showCustomSnackBar("Error: $e", Colors.red);
    }

    setState(() {
      isTyping = false;
    });
    _scrollToBottom();
  }

  Future<void> _generateResponse() async {
    try {
      final response = await http.post(
        Uri.parse(generateResponseApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'conversation_id': conversationId}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          finalCaseSummary = responseData["response"];
          _messages.add({"sender": "bot", "message": responseData["response"]});
        });
      } else {
        _showCustomSnackBar("Error: ${response.body}", Colors.red);
      }
    } catch (e) {
      _showCustomSnackBar("Error: $e", Colors.red);
    }
  }

  Future<void> _saveCaseSummary() async {
    if (finalCaseSummary == null) {
      _showCustomSnackBar("No case summary available to save.", Colors.red);
      return;
    }

    try {
      // Generate the PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Text(
              finalCaseSummary!,
              style: pw.TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      // Extract meaningful data for the file name
      final location = _extractCaseDetail('Location');
      final person = _extractCaseDetail('Person Involved');
      final date = _extractCaseDetail('Incident Date');

      // Sanitize and build the file name
      final sanitizedLocation = location.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final sanitizedPerson = person.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final sanitizedDate = date.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');

      final fileName = (sanitizedLocation != 'Unknown' || sanitizedPerson != 'Unknown' || sanitizedDate != 'Unknown')
          ? 'Case_${sanitizedLocation}_${sanitizedPerson}_${sanitizedDate}.pdf'
          : 'Case_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Save the file to the application's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(await pdf.save());

      _showCustomSnackBar("Case saved as $fileName.", Colors.green);
    } catch (e) {
      _showCustomSnackBar("Error saving case: $e", Colors.red);
    }
  }

  void _startNewCase() {
    setState(() {
      // Clear messages and any relevant data to start fresh
      _messages.clear();
      finalCaseSummary = "";  // Reset the case summary
      isTyping = false;  // Reset the typing status
    });
    // Optionally, show a message or navigate to another screen if needed
    print("Starting a new case...");
  }

  String _extractCaseDetail(String detailKey) {
    if (finalCaseSummary == null) return 'Unknown';

    // Match details in the format "Key: Value"
    final regex = RegExp('$detailKey:\\s*(.+?)(\\n|\\Z)');
    final match = regex.firstMatch(finalCaseSummary!);

    return match != null && match.group(1) != null && match.group(1)!.isNotEmpty
        ? match.group(1)!.trim()
        : 'Unknown';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showCustomSnackBar(String message, Color backgroundColor) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: const EdgeInsets.all(10.0),
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.blue.withOpacity(0.9),
        title: const Text(
          "Guidance",
          style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/background_image.png'),
            fit: BoxFit.cover,
            opacity: 0.2,
          ),
        ),
        child: Column(
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
                            backgroundImage: AssetImage('assets/images/bot.png'),
                            radius: 20,
                          ),
                          const SizedBox(width: 8),
                          SpinKitThreeBounce(color: Colors.grey, size: 20.0),
                        ],
                      ),
                    );
                  }
                  final message = _messages[index];
                  return Container(
                    alignment: message["sender"] == "user" ? Alignment.centerRight : Alignment.centerLeft,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: message["sender"] == "user"
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Bubble(
                          message: message["message"]!,
                          isUserMessage: message["sender"] == "user",
                        ),
                        if (message["message"] == finalCaseSummary)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0), // Add some space above the buttons
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,  // Center the buttons horizontally
                              children: [
                                ElevatedButton(
                                  onPressed: _saveCaseSummary,
                                  child: const Text("Save Case"),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),  // Rounded corners for a modern look
                                    ),  // Set a color for the button
                                  ),
                                ),
                                const SizedBox(width: 20), // Add space between the buttons
                                ElevatedButton(
                                  onPressed: _startNewCase,  // Replace with the start new case function
                                  child: const Text("Start New Case"),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),  // Rounded corners
                                    ),  // Different color for visual differentiation
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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
                        hintStyle: TextStyle(color: Colors.white.withOpacity(1)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onTap: _scrollToBottom,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final message = _messageController.text.trim();
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
        ),
      ),
    );
  }
}

class Bubble extends StatelessWidget {
  final String message;
  final bool isUserMessage;

  const Bubble({
    Key? key,
    required this.message,
    required this.isUserMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
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
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: MarkdownBody(
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
