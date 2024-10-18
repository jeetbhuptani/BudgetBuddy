import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/mood_tarcker_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';

void main() async{
  try{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );}catch(e){
  print(e);
}

 /* FirebaseAnalytics analytics = FirebaseAnalytics.instance;
   await analytics.logEvent(
       name: 'test_event',
       parameters: {'status': 'Firebase setup successful'},

   );*/
  print('Project initiated successfully');

  runApp(const MeriDiaryApp());
}

class MeriDiaryApp extends StatelessWidget {
  const MeriDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BudgetBuddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login', // Set the initial route to the Login screen
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/goals': (context) => GoalsScreen(),
        '/expenses': (context) => const ExpensesScreen(),
        '/moodTracker': (context) => MoodTrackerScreen(),
      },
    );
  }
}
