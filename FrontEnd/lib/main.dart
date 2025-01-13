import 'package:flutter/material.dart';
import 'package:legal_bot/screens/welcome_screen.dart';
import 'package:legal_bot/theme/theme.dart';
import 'package:legal_bot/widgets/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: 'https://mkidluozbwouqgifpxph.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1raWRsdW96YndvdXFnaWZweHBoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjcxMTc4OTcsImV4cCI6MjA0MjY5Mzg5N30.fdeLI11C7MPKrXjA4C7_Uq_Ru0wdQiVT9yl_PWcIXQo',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: lightMode,
      home: SplashScreen(),
    );
  }
}

