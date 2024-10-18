import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Add InvitationScreen class here
class InvitationScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> _handleInvitation(String invitationId, String groupId, bool accept) async {
    WriteBatch batch = _firestore.batch();

    if (accept) {
      batch.update(
          _firestore.collection('groups').doc(groupId),
          {
            'members': FieldValue.arrayUnion([user!.email]),
            'pendingMembers': FieldValue.arrayRemove([user!.email])
          }
      );
    }

    batch.update(
        _firestore.collection('invitations').doc(invitationId),
        {
          'status': accept ? 'accepted' : 'declined',
          'respondedAt': FieldValue.serverTimestamp(),
        }
    );

    await batch.commit();

    final invitation = await _firestore.collection('invitations').doc(invitationId).get();
    final fromEmail = invitation.data()?['fromEmail'];

    await _firestore.collection('notifications').add({
      'toEmail': fromEmail,
      'fromEmail': user!.email,
      'type': accept ? 'invitation_accepted' : 'invitation_declined',
      'groupId': groupId,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Invitations'),
        centerTitle: true,
        backgroundColor: Colors.cyan,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('invitations')
            .where('toEmail', isEqualTo: user!.email)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching invitations'));
          }

          final invitations = snapshot.data!.docs;

          if (invitations.isEmpty) {
            return Center(child: Text('No pending invitations'));
          }

          return ListView.builder(
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final invitationData = invitation.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('groups')
                    .doc(invitationData['groupId'])
                    .get(),
                builder: (context, groupSnapshot) {
                  if (!groupSnapshot.hasData) {
                    return ListTile(title: Text('Loading...'));
                  }

                  final groupData = groupSnapshot.data!.data() as Map<String, dynamic>;

                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group: ${groupData['name']}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'From: ${invitationData['fromEmail']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _handleInvitation(
                                  invitation.id,
                                  invitationData['groupId'],
                                  false,
                                ),
                                child: Text(
                                  'Decline',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () => _handleInvitation(
                                  invitation.id,
                                  invitationData['groupId'],
                                  true,
                                ),
                                child: Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}