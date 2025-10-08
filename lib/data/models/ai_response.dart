class AIResponse {
  final String answer;
  final String chatId;

  AIResponse({required this.answer, required this.chatId});

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      answer: json['answer'] ?? 'No answer received',
      chatId: json['chatId'] ?? '',
    );
  }
}
