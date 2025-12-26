class Message {
  final int id;
  final String content;
  final int senderId; // L'ID de celui qui a envoyé
  final DateTime createdAt;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      // Le backend renvoie "sender": { "id": 1, ... }
      senderId: json['sender']['id'], 
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}