import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meridiary_v2/screens/home_screen.dart';
// Import your home page

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLogin = true;
  String? email;
  String? password;
  String? errorMessage;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Function to switch between Login and Signup
  void switchAuthMode() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = null; // Reset error message when switching
    });
  }

  // Function to handle login
  Future<void> login() async {
    final form = _formKey.currentState;
    if (form!.validate()) {
      form.save();
      try {
        await _auth.signInWithEmailAndPassword(email: email!, password: password!);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (error) {
        setState(() {
          errorMessage = error.toString().split('] ')[1]; // Better error formatting
        });
      }
    }
  }

  // Function to handle signup
  Future<void> signup() async {
    final form = _formKey.currentState;
    if (form!.validate()) {
      form.save();
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email!, password: password!);
        User? user = userCredential.user;

        // Save user info to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'email': email,
          'displayName': user.displayName ?? 'User',
          // Initialize other fields as necessary, e.g., birthdate
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (error) {
        setState(() {
          errorMessage = error.toString().split('] ')[1]; // Better error formatting
        });
      }
    }
  }

  // Function to handle Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);
        User? user = userCredential.user;

        // Check if user data exists in Firestore, if not, create it
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (!doc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'email': user.email,
            'displayName': user.displayName ?? 'User',
            // Initialize other fields as necessary, e.g., birthdate
          });
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (error) {
      setState(() {
        errorMessage = "Google sign-in failed: $error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Login' : 'Sign Up'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
            color: Colors.white54
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      email = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      password = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLogin ? login : signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white60,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),

                    ),
                    child: Text(isLogin ? 'Login' : 'Sign Up',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: signInWithGoogle,
                    icon: const Icon(Icons.login,
                      size: 30.0,
                      color: Colors.white
                      ,),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    label: const Text('Sign in with Google',
                      style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: switchAuthMode,
                    child: Text(
                      isLogin
                          ? 'Don\'t have an account? Sign Up'
                          : 'Already have an account? Login',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue[500],
                      ),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}