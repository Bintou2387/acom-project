import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'message_model.dart';

class ChatPage extends StatefulWidget {
  final int contactId; // Avec qui on parle ?
  final String contactName; // Son nom (pour le titre)

  const ChatPage({super.key, required this.contactId, required this.contactName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _api = ApiService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  int? _myId;
  Timer? _timer; // Pour rafraîchir automatiquement

  @override
  void initState() {
    super.initState();
    _loadMyId();
    _refreshMessages();
    
    // Rafraîchir toutes les 3 secondes (Simulation temps réel)
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) => _refreshMessages());
  }

  @override
  void dispose() {
    _timer?.cancel(); // Arrêter le timer quand on quitte la page
    super.dispose();
  }

  void _loadMyId() async {
    final prefs = await SharedPreferences.getInstance();
    // On suppose que l'ID est stocké en String, on le convertit
    String? idStr = prefs.getString('user_id');
    if (idStr != null) {
      setState(() {
        _myId = int.parse(idStr);
      });
    }
  }

  void _refreshMessages() async {
    List<Message> freshMessages = await _api.getConversation(widget.contactId);
    if (mounted) {
      setState(() {
        _messages = freshMessages;
      });
      // Optionnel : Scroll automatique vers le bas si nouveau message
    }
  }

  void _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    String content = _msgCtrl.text;
    _msgCtrl.clear(); // Vider le champ direct pour l'UX

    bool success = await _api.sendMessage(widget.contactId, content);
    if (success) {
      _refreshMessages(); // Recharger pour voir mon message
      // Scroll tout en bas
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Text(widget.contactName, style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFE5E5E5), // Couleur fond WhatsApp
      body: Column(
        children: [
          // 1. LA LISTE DES MESSAGES
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg.senderId == _myId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFFDCF8C6) : Colors.white, // Vert WhatsApp ou Blanc
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg.content, style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          "${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. ZONE DE SAISIE
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: "Message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFF003580),
                    child: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}