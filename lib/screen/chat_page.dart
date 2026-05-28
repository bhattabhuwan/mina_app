import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/video_call_page.dart';
import 'package:mina_app/services/notification_service.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final String participantId;
  final String participantName;
  final String participantRole; // 'doctor' or 'patient'
  final String participantAvatar; // optional initials or icon
  final int? appointmentId;

  const ChatPage({
    super.key,
    required this.participantId,
    required this.participantName,
    required this.participantRole,
    this.participantAvatar = '?',
    this.appointmentId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  final Set<String> _notifiedCallMessageIds = {};
  Timer? _messageRefreshTimer;
  bool _loading = true;
  bool _sending = false;
  bool _startingCall = false;
  bool _refreshingMessages = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _messageRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadConversation(silent: true),
    );
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _loadConversation({bool silent = false}) async {
    if (_refreshingMessages) return;
    _refreshingMessages = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final messages = await _apiService.getConversation(
        widget.participantId,
        appointmentId: widget.appointmentId,
      );
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final unreadIncomingMessageIds = messages
          .where((message) =>
              message['receiver_id'] == userProvider.userId &&
              message['is_read'] != true)
          .map((message) => message['id'])
          .where((id) => id != null);
      final incomingCallMessages = messages.where((message) =>
          message['receiver_id'] == userProvider.userId &&
          message['is_read'] != true &&
          (message['content'] ?? message['message'] ?? '')
              .toString()
              .toLowerCase()
              .contains('incoming video call'));
      final shouldScroll = messages.length != _messages.length;
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });
      for (final message in incomingCallMessages) {
        final messageId = (message['id'] ?? message['created_at'] ?? message.hashCode).toString();
        if (_notifiedCallMessageIds.add(messageId)) {
          await NotificationService.showImmediateNotification(
            'Incoming video call',
            'Open the chat and tap Join Call to answer.',
          );
        }
      }
      await _apiService.markMessagesAsRead(unreadIncomingMessageIds);
      if (shouldScroll) _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    } finally {
      _refreshingMessages = false;
    }
  }

  String _formatNepalTime(String? rawTimestamp) {
    if (rawTimestamp == null || rawTimestamp.isEmpty) return '';
    final parsed = DateTime.tryParse(rawTimestamp);
    if (parsed == null) return '';
    final hasTimezone = rawTimestamp.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(rawTimestamp);
    final utc = hasTimezone
        ? parsed.toUtc()
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          );
    final nepalTime = utc.add(const Duration(hours: 5, minutes: 45));
    return '${DateFormat('MMM d, h:mm a').format(nepalTime)} NPT';
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => _sending = true);
    try {
      await _apiService.sendMessage(
        recipientId: widget.participantId,
        recipientType: widget.participantRole,
        message: messageText,
        appointmentId: widget.appointmentId,
      );
      // Reload conversation to get updated messages
      await _loadConversation();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _messageController.text = messageText;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startVideoCall() async {
    setState(() => _startingCall = true);
    try {
      final appointmentId = widget.appointmentId ??
          await _apiService.findAppointmentIdWithParticipant(widget.participantId);
      if (appointmentId == null) {
        throw Exception('Book an appointment before starting a call.');
      }
      await _apiService.sendCallInvitation(
        recipientId: widget.participantId,
        appointmentId: appointmentId,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallPage(
            appointmentId: appointmentId,
            title: 'Call with ${widget.participantName}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _startingCall = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.participantName),
            Text(
              widget.participantRole == 'doctor' ? 'Doctor' : 'Patient',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5C5FFF),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: userProvider.role.toLowerCase() == 'doctor'
            ? [
                IconButton(
                  tooltip: 'Video call',
                  icon: _startingCall
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.videocam),
                  onPressed: _startingCall ? null : _startVideoCall,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadConversation,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text('No messages yet. Start a conversation!'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isSentByMe = message['sender_id'] == userProvider.userId;
                              final content = message['content'] ?? message['message'] ?? '';
                              final appointmentId = message['appointment_id'] ?? widget.appointmentId;
                              final isCallInvite = content
                                  .toString()
                                  .toLowerCase()
                                  .contains('incoming video call');
                              final formattedTime = _formatNepalTime(
                                message['created_at']?.toString(),
                              );

                              return Align(
                                alignment: isSentByMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSentByMe
                                        ? const Color(0xFF5C5FFF)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isSentByMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        content.toString(),
                                        style: TextStyle(
                                          color: isSentByMe ? Colors.white : Colors.black,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (isCallInvite && !isSentByMe && appointmentId != null) ...[
                                        const SizedBox(height: 10),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => VideoCallPage(
                                                  appointmentId: appointmentId,
                                                  title: 'Call with ${widget.participantName}',
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.call),
                                          label: const Text('Join Call'),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          color: isSentByMe
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.emoji_emotions,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    maxLines: null,
                    enabled: !_sending,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C5FFF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _sending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageRefreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ==================== Conversations List Page ====================
class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final conversations = await _apiService.getConversations();
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF5C5FFF),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadConversations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No conversations yet'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Start a conversation'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conv = _conversations[index];
                          final participantName =
                              conv['partner_name'] ?? conv['participant_name'] ?? 'Unknown';
                          final lastMessage = conv['last_message'] ?? '';
                          final unreadCount = conv['unread_count'] ?? 0;
                          final lastMessageTime =
                              DateTime.tryParse(conv['last_message_time'] ?? '');
                          final formattedTime = lastMessageTime != null
                              ? '${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}'
                              : '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: unreadCount > 0
                                  ? Colors.red
                                  : const Color(0xFF5C5FFF),
                              child: Text(
                                participantName.isNotEmpty
                                    ? participantName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(participantName),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formattedTime,
                                    style: const TextStyle(fontSize: 12)),
                                if (unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    participantId: (conv['partner_id'] ?? conv['participant_id']).toString(),
                                    participantName: participantName,
                                    participantRole: conv['partner_role'] ?? conv['participant_role'] ?? 'doctor',
                                    appointmentId: conv['appointment_id'],
                                  ),
                                ),
                              ).then((_) => _loadConversations());
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
