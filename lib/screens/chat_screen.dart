import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';

class ChatScreen extends StatelessWidget {
  final String receiverId;
  final String receiverName;
  final ChatController chatController = Get.put(ChatController());
  final TextEditingController messageController = TextEditingController();

  ChatScreen({required this.receiverId, required this.receiverName});
  RxBool isReceiverTyping = false.obs;
  @override
  Widget build(BuildContext context) {
    chatController.getMessages(receiverId);

    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return ListView.builder(
                reverse: true,
                padding: EdgeInsets.all(12),
                itemCount: chatController.messages.length,
                itemBuilder: (context, index) {
                  var message = chatController.messages[index];
                  bool isSender = message['senderId'] == chatController.currentUserId;

                  return Align(
                    alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSender ? Colors.teal : Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['message'],
                            style: TextStyle(color: isSender ? Colors.white : Colors.black),
                          ),
                          SizedBox(height: 4),

                          // 🔹 Message Status Indicator
                          if (isSender) _getStatusIcon(message['status']),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // 🔹 Message Input Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    String message = messageController.text.trim();
                    if (message.isNotEmpty) {
                      chatController.sendMessage(receiverId, message);
                      messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Message Status Icon
  Widget _getStatusIcon(String status) {
    if (status == 'sent') {
      return Icon(Icons.check, size: 14, color: Colors.white); // ✅ Sent
    } else if (status == 'delivered') {
      return Icon(Icons.done_all, size: 14, color: Colors.white); // ✅✅ Delivered
    } else if (status == 'seen') {
      return Icon(Icons.visibility, size: 14, color: Colors.blueAccent); // 👀 Seen
    }
    return SizedBox(); // No icon if status is missing
  }
}
