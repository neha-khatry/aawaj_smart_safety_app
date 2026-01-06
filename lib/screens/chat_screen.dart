import 'package:flutter/material.dart';
import 'dart:async';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      id: '1',
      message:
      "Hello! I'm here to support you. You're not alone, and your feelings are valid. How are you feeling today? 💜",
      isUser: false,
    ));
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: text,
        isUser: true,
      ));
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: ChatBotResponses.getResponse(text),
          isUser: false,
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                        ),
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                          ),
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aawaj Support',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green[400],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('Always here for you',
                                style: TextStyle(
                                    color: Colors.green[400], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildQuickResponse('I need someone to talk to'),
                    _buildQuickResponse("I'm feeling anxious"),
                    _buildQuickResponse('I want to feel safe'),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _sendMessage(_controller.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
                ),
              ),
              child:
              const Icon(Icons.favorite, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                    colors: [Color(0xFFec4899), Color(0xFF8b5cf6)])
                    : null,
                color: message.isUser ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFec4899), Color(0xFF8b5cf6)],
            ),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 600 + (index * 200)),
                builder: (context, value, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[400],
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickResponse(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _sendMessage(text),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
