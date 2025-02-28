import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var messages = [].obs;

  String get currentUserId => _auth.currentUser!.uid;

  /// Fetch Messages & Update Seen Status
  void getMessages(String receiverId) {
    String chatId = getChatId(currentUserId, receiverId);

    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      messages.value = snapshot.docs.map((doc) => doc.data()).toList();

      //  Mark messages as "Seen" when opened
      for (var doc in snapshot.docs) {
        if (doc['receiverId'] == currentUserId && doc['status'] != 'seen') {
          doc.reference.update({'status': 'seen'});
        }
      }
    });
  }


  void sendMessage(String receiverId, String message) async {
    String currentUserId = _auth.currentUser!.uid;
    String chatId = getChatId(currentUserId, receiverId);

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });

    //  Fetch receiver's FCM Token
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(receiverId).get();
    String? fcmToken = userDoc['fcmToken'];

    if (fcmToken != null) {
      _sendPushNotification(fcmToken, "New Message", message);
    }
  }

//  Send Push Notification via Firebase Cloud Messaging
  void _sendPushNotification(String token, String title, String body) async {
    await FirebaseMessaging.instance.sendMessage(
      to: token,
      data: {'title': title, 'body': body},
    );
  }


  /// Generate Unique Chat ID
  String getChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode ? "$user1\_$user2" : "$user2\_$user1";
  }
}
