import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:meridiary_v2/screens/login_screen.dart';
import 'diary_entry_screen.dart';
import 'invitation_screen.dart';
import 'profile_screen.dart';
import 'goals_screen.dart';
import 'expenses_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _hoveredCardDate;
  List<Map<String, dynamic>> _diaryEntries = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy':
        return Colors.yellow;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date); // Format date
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchDiaryEntries() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print("Current user ID: ${user.uid}"); // Debugging output

      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('diary_entries') // Updated collection name
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true)
            .get();

        print("Fetched ${snapshot.docs.length} diary entries."); // Debugging output

        setState(() {
          _diaryEntries = snapshot.docs.map((doc) {
            return {
              'date': (doc['date'] as Timestamp).toDate(),
              'mood': doc['mood'],
              'title': doc['title'],
              'content': doc['content'],
            };
          }).toList();
        });
      } catch (e) {
        print("Error fetching diary entries: $e"); // Print any error that occurs
      }
    } else {
      print("No user is currently logged in."); // Debugging output if no user is logged in
    }
  }



  @override
  void initState() {
    super.initState();
    _fetchDiaryEntries(); // Fetch diary entries on init
  }

  @override
  Widget build(BuildContext context) {
    Widget _getSelectedPage() {
      switch (_selectedIndex) {
        case 0:
          return _diaryEntries.isNotEmpty
              ? ListView.builder(
            itemCount: _diaryEntries.length,
            itemBuilder: (context, index) {
              final entry = _diaryEntries[index];
              final isHovered = _hoveredCardDate == _formatDate(entry['date']);
              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredCardDate = _formatDate(entry['date'])),
                onExit: (_) => setState(() => _hoveredCardDate = null),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
                  transformAlignment: Alignment.center,
                  child: Card(
                    color: _getMoodColor(entry['mood']),
                    margin: EdgeInsets.all(8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0), // Rounded edges
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      title: Text('\u{20B9} ${entry['title']}', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${_formatDate(entry['date'])}\n${entry['content']}'),
                      isThreeLine: true,
                      onTap: () {
                        // Show a dialog with more details
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('\u{20B9} ${entry['title']}'),
                              content: Text('${_formatDate(entry['date'])}\n${entry['content']}\n\n Feeling : ${entry['mood']}'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Close'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          )
              : Center(
            child: Text(
              'Add your first diary entry now using the button below...',
              style: TextStyle(
                fontSize: 20, // Increased font size for better visibility
                fontWeight: FontWeight.bold, // Bold text for emphasis
                color: Colors.black87, // Dark gray color for good contrast

              ),
              textAlign: TextAlign.center, // Center align the text
            ),
          );


        case 1:
          return ProfileScreen();
        case 2:
          return GoalsScreen();
        case 3:
          return ExpensesScreen();
        // case 4:
        //   return MoodTrackerScreen();
        default:
          return Center(child: Text('Page not found'));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('BudgetBuddy'),
        backgroundColor: Colors.cyan,
        actions: [
          // Add Invitation notification icon
          if (_selectedIndex == 3) // Only show for ExpensesScreen
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('invitations')
                  .where('toEmail', isEqualTo: user?.email)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                int invitationCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.mail),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InvitationScreen(),
                          ),
                        );
                      },
                    ),
                    if (invitationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$invitationCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            icon: Icon(Icons.logout),
          )
        ],
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: _selectedIndex == 0 ? Colors.lightBlue : Colors.grey),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: _selectedIndex == 1 ? Colors.lightBlue : Colors.grey),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag, color: _selectedIndex == 2 ? Colors.lightBlue : Colors.grey),
            label: 'My Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money, color: _selectedIndex == 3 ? Colors.lightBlue : Colors.grey),
            label: 'My Expenses',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.cyan,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DiaryEntryScreen()),
          ).then((_) {
            _fetchDiaryEntries();
          });
        },
        backgroundColor: Colors.cyan,
        icon: Icon(Icons.add),
        label: Text(
          'Add New Entry',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
