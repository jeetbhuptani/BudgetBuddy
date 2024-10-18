import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import Firebase Storage
import 'dart:io'; // Import Dart's File class

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  XFile? _imageFile;

  Future<Map<String, dynamic>?> _getUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String,
            dynamic>?; // Include photoURL in user data
      }
    }
    return null;
  }

  Future<void> _updateName(String name) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update the user's display name in Firebase Auth
      await user.updateProfile(displayName: name);

      // Update the user's name in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': name, // Assuming you have a 'name' field in your Firestore document
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Name updated to $name'),
      ));

      // Trigger a rebuild by calling setState
      setState(() {});
    }
  }


  Future<void> _updateBirthdate(String birthdate) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
          {
            'birthdate': birthdate,
          });
    }
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      String formattedDate = "${selectedDate.toLocal()}".split(
          ' ')[0]; // Format as YYYY-MM-DD
      await _updateBirthdate(formattedDate);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Birthday updated to $formattedDate'),
      ));
      setState(() {}); // Refresh the UI
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = image;
      });

      // Upload the image to Firebase Storage
      await _uploadProfilePicture(image);
    }
  }

  Future<void> _uploadProfilePicture(XFile image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Create a reference to the location where the image will be stored
        Reference storageRef = FirebaseStorage.instance.ref().child(
            'profile_pics/${user.uid}');

        // Upload the image to Firebase Storage
        await storageRef.putFile(File(image.path));

        // Get the download URL to store in Firestore if needed
        String downloadURL = await storageRef.getDownloadURL();

        // Optionally, update the user's profile photo URL in Firestore
        await FirebaseFirestore.instance.collection('users')
            .doc(user.uid)
            .update({
          'photoURL': downloadURL,
          // Update the Firestore document with the new photo URL
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile picture updated successfully.'),
        ));
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload profile picture.'),
        ));
      }
    }
  }

  Future<void> _showUpdateNameDialog(BuildContext context) async {
    TextEditingController _nameController = TextEditingController();

    // Show a dialog to update the name
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Name'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  _updateName(newName);
                }
                Navigator.of(context).pop(); // Close the dialog after updating
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user is logged in'));
    }

    return FutureBuilder<
        Map<String, dynamic>?>( // Fetch user info, including photoURL
      future: _getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching user info'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('User info not found'));
        }

        Map<String, dynamic>? userInfo = snapshot.data;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageFile != null)
                CircleAvatar(
                  backgroundImage: FileImage(File(_imageFile!.path)),
                  radius: 50,
                )
              else
                if (userInfo != null && userInfo['photoURL'] != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(userInfo['photoURL']),
                    radius: 50,
                  ),
              const SizedBox(height: 20),
              Text('Name: ${user.displayName}',
                  style: const TextStyle(fontSize: 18)),
              ElevatedButton(
                onPressed: () {
                  _showUpdateNameDialog(context); // Show dialog to update name
                },
                child: const Text('Update Name'),
              ),
              const SizedBox(height: 10),
              if (userInfo != null && userInfo['birthdate'] != null) ...[
                Text('Birthdate: ${userInfo['birthdate']}',
                    style: const TextStyle(fontSize: 16)),
                ElevatedButton(
                  onPressed: () => _selectBirthdate(context),
                  child: const Text('Update Birthdate'),
                ),
              ] else
                ...[
                  Text('Birthdate not set',
                      style: const TextStyle(fontSize: 16)),
                  ElevatedButton(
                    onPressed: () => _selectBirthdate(context),
                    child: const Text('Set Birthday'),
                  ),
                ],
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Change Profile Picture'),
              ),
            ],
          ),
        );
      },
    );
  }
}