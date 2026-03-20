// lib/screens/chatbot_screen.dart
// ====================================
// Aawaj Mental Health Chatbot Screen
// Full-featured chat UI matching the Aawaj dark theme.
//
// Features:
//   - Animated message bubbles (user + bot)
//   - Crisis alert banner with helpline numbers
//   - Breathing exercise card with step-by-step view
//   - Typing indicator
//   - Quick reply chips
//   - Markdown-style bold rendering

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/chatbot_service.dart';

// ── Theme constants (matches Aawaj dark theme from screenshots) ──────────
class _AppTheme {
  static const Color background    = Color(0xFF0D0D1A);
  static const Color surface       = Color(0xFF1A1A2E);
  static const Color surfaceLight  = Color(0xFF16213E);
  static const Color primary       = Color(0xFFE94560);   // Aawaj red/pink
  static const Color primaryDark   = Color(0xFFC23152);
  static const Color accent        = Color(0xFF7B2FBE);
  static const Color botBubble     = Color(0xFF1E1E3A);
  static const Color userBubble    = Color(0xFFE94560);
  static const Color textPrimary   = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF9E9EC8);
  static const Color crisisColor   = Color(0xFFFF6B35);
  static const Color breathingColor= Color(0xFF4CAF50);
  static const Color divider       = Color(0xFF2A2A4A);
}

// ── Entry point widget ────────────────────────────────────────────────────
class ChatbotScreen extends StatefulWidget {
  final String deviceId;

  const ChatbotScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final _service        = ChatbotService();
  final _messages       = <ChatMessage>[];
  final _controller     = TextEditingController();
  final _scrollCtrl     = ScrollController();
  final _focusNode      = FocusNode();

  int?  _sessionId;
  bool  _isTyping      = false;
  bool  _isLoading     = true;
  bool  _hasError      = false;

  late AnimationController _typingAnimCtrl;

  // Quick reply suggestions
  final List<String> _quickReplies = [
    "I feel anxious 😰",
    "Help me breathe 🌬️",
    "I feel so sad 💙",
    "I need resources 📋",
    "I feel alone 🌙",
    "I'm overwhelmed 😔",
  ];

  @override
  void initState() {
    super.initState();
    _typingAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _initSession();
  }

  @override
  void dispose() {
    _typingAnimCtrl.dispose();
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _service.dispose();
    super.dispose();
  }

  // ── Session init ────────────────────────────────────────────────────
  Future<void> _initSession() async {
    setState(() { _isLoading = true; _hasError = false; });

    final response = await _service.startSession(widget.deviceId);

    if (response != null) {
      setState(() {
        _sessionId = response.sessionId;
        _messages.add(ChatMessage(
          role:      'bot',
          content:   response.message,
          intent:    response.intent,
          isCrisis:  response.isCrisis,
          timestamp: response.timestamp,
        ));
        _isLoading = false;
      });
    } else {
      // Offline fallback greeting
      setState(() {
        _messages.add(ChatMessage(
          role:    'bot',
          content: "Hello 💙 I'm Aawaj Support. I'm here to listen. How are you feeling today?",
          intent:  'greeting',
        ));
        _isLoading = false;
        _hasError  = true;
      });
    }
    _scrollToBottom();
  }

  // ── Send message ────────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _controller.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: trimmed));
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate slight typing delay
    await Future.delayed(const Duration(milliseconds: 600));

    final response = await _service.sendMessage(
      deviceId:  widget.deviceId,
      message:   trimmed,
      sessionId: _sessionId,
    );

    setState(() {
      _isTyping = false;

      if (response != null) {
        _sessionId = response.sessionId;
        _messages.add(ChatMessage(
          role:       'bot',
          content:    response.message,
          intent:     response.intent,
          confidence: response.confidence,
          isCrisis:   response.isCrisis,
          exercise:   response.exercise,
          timestamp:  response.timestamp,
        ));
      } else {
        _messages.add(ChatMessage(
          role:    'bot',
          content: "I'm having trouble connecting right now. Please try again in a moment. If you're in crisis, call Sathi Sewa: **1166**. 💙",
          intent:  'fallback',
        ));
      }
    });
    _scrollToBottom(delay: 100);
  }

  void _scrollToBottom({int delay = 0}) {
    Future.delayed(Duration(milliseconds: 100 + delay), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppTheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_hasError) _buildOfflineBanner(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _buildMessageList(),
          ),
          _buildQuickReplies(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: _AppTheme.textPrimary, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_AppTheme.primary, _AppTheme.accent],
              ),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aawaj Support',
                style: TextStyle(
                  color: _AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Always here for you',
                    style: TextStyle(color: _AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: _AppTheme.textSecondary, size: 20),
          onPressed: () {
            setState(() { _messages.clear(); _sessionId = null; });
            _initSession();
          },
          tooltip: 'New session',
        ),
      ],
    );
  }

  // ── Offline banner ───────────────────────────────────────────────────
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _AppTheme.crisisColor.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: _AppTheme.crisisColor, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Offline mode — responses may be limited',
            style: TextStyle(color: _AppTheme.crisisColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Loading state ────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_AppTheme.primary, _AppTheme.accent],
              ),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aawaj Support is preparing…',
            style: TextStyle(color: _AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (_isTyping && i == _messages.length) {
          return _buildTypingIndicator();
        }
        final msg = _messages[i];
        return _MessageBubble(
          message:   msg,
          onCrisisTap: _showCrisisDialog,
        );
      },
    );
  }

  // ── Typing indicator ─────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _AppTheme.botBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => AnimatedBuilder(
                animation: _typingAnimCtrl,
                builder: (_, __) {
                  final offset = (i * 0.3).clamp(0.0, 1.0);
                  final opacity = (_typingAnimCtrl.value - offset).clamp(0.2, 1.0);
                  return Container(
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: _AppTheme.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick replies ────────────────────────────────────────────────────
  Widget _buildQuickReplies() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => _sendMessage(_quickReplies[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _AppTheme.surface,
              border: Border.all(color: _AppTheme.divider),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _quickReplies[i],
              style: const TextStyle(
                color: _AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: _AppTheme.surface,
        border: Border(top: BorderSide(color: _AppTheme.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _AppTheme.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _AppTheme.divider),
              ),
              child: TextField(
                controller:  _controller,
                focusNode:   _focusNode,
                style: const TextStyle(color: _AppTheme.textPrimary, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:        'Type your message…',
                  hintStyle:       TextStyle(color: _AppTheme.textSecondary),
                  border:          InputBorder.none,
                  contentPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_AppTheme.primary, _AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Crisis dialog ────────────────────────────────────────────────────
  void _showCrisisDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emergency, color: _AppTheme.crisisColor),
            SizedBox(width: 8),
            Text('Emergency Contacts', style: TextStyle(color: _AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _HelplineRow(name: 'Sathi Sewa (Nepal)', number: '1166'),
            _HelplineRow(name: 'TPO Nepal', number: '01-4460084'),
            _HelplineRow(name: 'Umang Helpline', number: '9840021600'),
            _HelplineRow(name: 'Nepal Police', number: '100'),
            _HelplineRow(name: 'TUTH Psychiatry', number: '01-4412404'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: _AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _botAvatar() {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_AppTheme.primary, _AppTheme.accent],
        ),
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 14),
    );
  }
}

// ── Message bubble widget ─────────────────────────────────────────────────
class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onCrisisTap;

  const _MessageBubble({required this.message, required this.onCrisisTap});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: Offset(widget.message.isUser ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg    = widget.message;
    final isUser = msg.isUser;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _botAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Crisis banner
                    if (!isUser && msg.isCrisis)
                      _CrisisBanner(onTap: widget.onCrisisTap),

                    // Bubble
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isUser ? _AppTheme.userBubble : _AppTheme.botBubble,
                        borderRadius: BorderRadius.only(
                          topLeft:     const Radius.circular(18),
                          topRight:    const Radius.circular(18),
                          bottomLeft:  Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildBubbleContent(msg),
                    ),

                    // Breathing exercise card
                    if (!isUser && msg.exercise != null)
                      _BreathingExerciseCard(exercise: msg.exercise!),

                    // Timestamp
                    Padding(
                      padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                      child: Text(
                        _formatTime(msg.timestamp),
                        style: const TextStyle(
                          color: _AppTheme.textSecondary,
                          fontSize: 10,
                        ),
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

  Widget _buildBubbleContent(ChatMessage msg) {
    // Simple bold markdown: **text** → bold
    final spans = _parseBold(msg.content);
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: _AppTheme.textPrimary,
          fontSize: 14,
          height: 1.45,
        ),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseBold(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return spans;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _botAvatar() {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_AppTheme.primary, _AppTheme.accent],
        ),
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 14),
    );
  }
}

// ── Crisis banner ─────────────────────────────────────────────────────────
class _CrisisBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _CrisisBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _AppTheme.crisisColor.withOpacity(0.15),
          border: Border.all(color: _AppTheme.crisisColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.emergency, color: _AppTheme.crisisColor, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tap to see emergency helplines',
                style: TextStyle(
                  color: _AppTheme.crisisColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: _AppTheme.crisisColor, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Breathing exercise card ───────────────────────────────────────────────
class _BreathingExerciseCard extends StatefulWidget {
  final BreathingExercise exercise;
  const _BreathingExerciseCard({required this.exercise});

  @override
  State<_BreathingExerciseCard> createState() => _BreathingExerciseCardState();
}

class _BreathingExerciseCardState extends State<_BreathingExerciseCard> {
  int  _currentStep = 0;
  bool _expanded    = true;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppTheme.breathingColor.withOpacity(0.08),
        border: Border.all(color: _AppTheme.breathingColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.air, color: _AppTheme.breathingColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ex.name,
                    style: const TextStyle(
                      color: _AppTheme.breathingColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: _AppTheme.breathingColor, size: 18,
                ),
              ],
            ),
          ),

          if (_expanded) ...[
            const SizedBox(height: 10),
            // Steps
            ...List.generate(ex.steps.length, (i) {
              final isActive = i == _currentStep;
              return GestureDetector(
                onTap: () => setState(() => _currentStep = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _AppTheme.breathingColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isActive
                        ? Border.all(color: _AppTheme.breathingColor.withOpacity(0.4))
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? _AppTheme.breathingColor
                              : _AppTheme.breathingColor.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : _AppTheme.breathingColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ex.steps[i].replaceAll('**', ''),
                          style: TextStyle(
                            color: isActive ? _AppTheme.textPrimary : _AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('← Prev',
                        style: TextStyle(color: _AppTheme.breathingColor, fontSize: 12)),
                  ),
                if (_currentStep < ex.steps.length - 1)
                  TextButton(
                    onPressed: () => setState(() => _currentStep++),
                    child: const Text('Next →',
                        style: TextStyle(color: _AppTheme.breathingColor, fontSize: 12)),
                  ),
                if (_currentStep == ex.steps.length - 1)
                  TextButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    child: const Text('🔄 Restart',
                        style: TextStyle(color: _AppTheme.breathingColor, fontSize: 12)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helpline row ──────────────────────────────────────────────────────────
class _HelplineRow extends StatelessWidget {
  final String name;
  final String number;
  const _HelplineRow({required this.name, required this.number});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.phone, color: _AppTheme.crisisColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: _AppTheme.textPrimary, fontSize: 13)),
                GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: number)),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: _AppTheme.crisisColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: _AppTheme.textSecondary, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: number));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$number copied to clipboard'),
                  backgroundColor: _AppTheme.surface,
                  duration: const Duration(seconds: 2),
                ),
              );
            },

          ),
        ],
      ),
    );
  }
}
