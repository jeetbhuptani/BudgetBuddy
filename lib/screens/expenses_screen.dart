// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GroupExpensesScreenState createState() => _GroupExpensesScreenState();
}

class _GroupExpensesScreenState extends State<ExpensesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _memberEmailController = TextEditingController();
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();

  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Fetch groups where current user is a member
  Stream<QuerySnapshot> _getGroups() {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: user!.email)
        .snapshots();
  }

  // Create a new group
  Future<void> _createGroup(String groupName) async {
    await _firestore.collection('groups').add({
      'name': groupName,
      'creator': user!.email,
      'members': [user!.email],
      'pendingMembers': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Add member to group
  Future<void> _addMemberToGroup(String groupId, String memberEmail) async {
    // Add to pending members and send invitation
    await _firestore.collection('groups').doc(groupId).update({
      'pendingMembers': FieldValue.arrayUnion([memberEmail])
    });

    // Create invitation in separate collection
    await _firestore.collection('invitations').add({
      'groupId': groupId,
      'toEmail': memberEmail,
      'fromEmail': user!.email,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // In real app, you would send email here
    print('Invitation sent to $memberEmail');
  }

  // Add new expense
  Future<void> _addExpense(String groupId, String expenseName, double totalAmount,
      Map<String, double> splits) async {
    final expense = await _firestore.collection('expenses').add({
      'groupId': groupId,
      'name': expenseName,
      'totalAmount': totalAmount,
      'paidBy': user!.email,
      'splits': splits,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Notify all members involved in the split
    for (String memberEmail in splits.keys) {
      if (memberEmail != user!.email) {
        await _firestore.collection('notifications').add({
          'toEmail': memberEmail,
          'fromEmail': user!.email,
          'expenseId': expense.id,
          'type': 'new_expense',
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Mark expense as paid
  Future<void> _markExpensePaid(String expenseId, String payerEmail) async {
    await _firestore.collection('expenses').doc(expenseId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Notify the person who paid initially
    final expense = await _firestore.collection('expenses').doc(expenseId).get();
    final paidBy = expense.data()?['paidBy'];

    if (paidBy != payerEmail) {
      await _firestore.collection('notifications').add({
        'toEmail': paidBy,
        'fromEmail': payerEmail,
        'expenseId': expenseId,
        'type': 'payment_completed',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(labelText: 'Group Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_groupNameController.text.isNotEmpty) {
                await _createGroup(_groupNameController.text);
                _groupNameController.clear();
                // ignore: use_build_context_synchronously
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(String groupId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: _memberEmailController,
          decoration: const InputDecoration(labelText: 'Member Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_memberEmailController.text.isNotEmpty) {
                await _addMemberToGroup(groupId, _memberEmailController.text);
                _memberEmailController.clear();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(String groupId, List<String> members) {
    Map<String, double> splits = {};
    for (var member in members) {
      splits[member] = 0.0;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _expenseNameController,
                  decoration: const InputDecoration(labelText: 'Expense Name'),
                ),
                TextField(
                  controller: _expenseAmountController,
                  decoration: const InputDecoration(labelText: 'Total Amount'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                const Text('Split Amount'),
                ...members.map((member) => Row(
                  children: [
                    Expanded(child: Text(member)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        onChanged: (value) {
                          setState(() {
                            splits[member] = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_expenseNameController.text.isNotEmpty &&
                    _expenseAmountController.text.isNotEmpty) {
                  double totalAmount =
                  double.parse(_expenseAmountController.text);
                  await _addExpense(
                      groupId, _expenseNameController.text, totalAmount, splits);
                  _expenseNameController.clear();
                  _expenseAmountController.clear();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Expenses'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching groups'));
          }

          final groups = snapshot.data!.docs;

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (ctx, index) {
              final group = groups[index];
              final groupData = group.data() as Map<String, dynamic>;

              return ExpansionTile(
                title: Text(groupData['name']),
                children: [
                  ListTile(
                    title: const Text('Members:'),
                    subtitle: Text((groupData['members'] as List<dynamic>).join(', ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () => _showAddMemberDialog(group.id),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('expenses')
                        .where('groupId', isEqualTo: group.id)
                        .snapshots(),
                    builder: (context, expenseSnapshot) {
                      if (!expenseSnapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final expenses = expenseSnapshot.data!.docs;
                      return Column(
                        children: expenses.map((expense) {
                          final expenseData = expense.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(expenseData['name']),
                            subtitle: Text('Amount: \$${expenseData['totalAmount']}'),
                            trailing: expenseData['status'] == 'pending'
                                ? TextButton(
                              onPressed: () => _markExpensePaid(
                                  expense.id, user!.email!),
                              child: const Text('Mark Paid'),
                            )
                                : const Icon(Icons.check_circle, color: Colors.green),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => _showAddExpenseDialog(
                        group.id, List<String>.from(groupData['members'])),
                    child: const Text('Add Expense'),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupDialog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.cyan,
      ),
    );
  }
}