import 'package:flutter/material.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/job_offer.dart';
import '../../services/database_messaging_service.dart';
import '../../services/realtime_messaging_service.dart';
import '../../services/job_offer_service.dart';
import '../../services/location_service.dart';
import '../../widgets/messaging/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final String currentUserId;
  final bool returnToConversationsList;

  const ChatScreen({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.returnToConversationsList = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  List<JobOffer> _jobOffers = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isShareLocation = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadJobOffers();
    _markMessagesAsRead();
    _startRealtimePolling();
  }

  Future<void> _loadJobOffers() async {
    try {
      final offers = await JobOfferService.getJobOffersForConversation(
        widget.conversation.id,
      );
      if (mounted) {
        setState(() {
          _jobOffers = offers;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mark messages as read when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    RealtimeMessagingService.stopMessagePolling();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await DatabaseMessagingService.getConversationMessages(
        widget.conversation.id,
      );

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startRealtimePolling() {
    RealtimeMessagingService.startMessagePolling(
      conversationId: widget.conversation.id,
      onMessagesUpdated: _onMessagesUpdated,
    );
  }

  void _onMessagesUpdated(List<Message> messages) {
    if (mounted) {
      final shouldScrollToBottom = _isAtBottom();
      final oldMessageCount = _messages.length;
      final newMessageCount = messages.length;

      setState(() {
        _messages = messages;
      });

      // Auto-scroll to bottom if user was already at bottom or if there are new messages
      if (shouldScrollToBottom || newMessageCount > oldMessageCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      // If new messages arrived, mark them as read immediately since user is in chat
      if (newMessageCount > oldMessageCount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _markMessagesAsRead();
        });
      }
    }
  }

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return (maxScroll - currentScroll) < 100.0; // Within 100 pixels of bottom
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await DatabaseMessagingService.markMessagesAsRead(
        widget.conversation.id,
        widget.currentUserId,
      );
      // Force refresh conversations to update unread counts immediately
      RealtimeMessagingService.refreshConversations();
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = await DatabaseMessagingService.sendMessage(
        conversationId: widget.conversation.id,
        content: content,
      );

      _messageController.clear();

      if (mounted) {
        setState(() {
          _messages.add(message);
          _isSending = false;
        });

        _scrollToBottom();

        // Force refresh to ensure real-time polling updates
        RealtimeMessagingService.refreshMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error sending message: $e');
    }
  }

  Future<void> _shareCurrentLocation() async {
    if (_isShareLocation) return;

    setState(() {
      _isShareLocation = true;
    });

    try {
      // Check if location permission is already granted
      final hasPermission = await LocationService.hasLocationPermission();

      if (!hasPermission) {
        // Show permission dialog
        final shouldRequest = await _showLocationPermissionDialog();
        if (!shouldRequest) {
          if (mounted) {
            setState(() {
              _isShareLocation = false;
            });
          }
          return;
        }
      }

      // Get current location
      final locationData = await LocationService.getCurrentLocation();

      if (locationData == null) {
        throw Exception('Unable to get current location');
      }

      // Send location message
      final message = await DatabaseMessagingService.sendLocationMessage(
        conversationId: widget.conversation.id,
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        address: locationData.address,
      );

      if (mounted) {
        setState(() {
          _messages.add(message);
          _isShareLocation = false;
        });

        _scrollToBottom();

        // Force refresh to ensure real-time polling updates
        RealtimeMessagingService.refreshMessages();

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Location shared successfully'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isShareLocation = false;
        });

        String errorMessage = 'Failed to share location';

        if (e.toString().contains('permissions')) {
          errorMessage =
              'Location permission denied. Please enable location access in settings.';
        } else if (e.toString().contains('disabled')) {
          errorMessage = 'Location services are disabled. Please enable GPS.';
        } else {
          errorMessage = 'Failed to get location: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: e.toString().contains('permissions')
                ? SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () {
                      LocationService.openAppSettings();
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  Future<bool> _showLocationPermissionDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFFE53E3E)),
                SizedBox(width: 8),
                Text('Share Location'),
              ],
            ),
            content: const Text(
              'WeCare needs location access to share your current location with the other person. This helps them find the exact work location.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                ),
                child: const Text('Allow'),
              ),
            ],
          ),
        ) ??
        false;
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

  @override
  Widget build(BuildContext context) {
    final participantName = widget.conversation.getParticipantName(
      widget.currentUserId,
    );
    final participantType = widget.conversation.getParticipantType(
      widget.currentUserId,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: widget.returnToConversationsList
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) =>
                        route.settings.name == '/conversations' ||
                        route.isFirst,
                  );
                },
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: participantType == 'Helper'
                    ? const Color(0xFFFF8A50).withValues(alpha: 0.1)
                    : const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                participantType == 'Helper' ? Icons.handyman : Icons.business,
                color: participantType == 'Helper'
                    ? const Color(0xFFFF8A50)
                    : const Color(0xFF1565C0),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.conversation.jobTitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black12,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty && _jobOffers.isEmpty
                  ? _buildEmptyMessages()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _messages.length + _jobOffers.length,
                      itemBuilder: (context, index) {
                        // First show job offers, then messages
                        if (index < _jobOffers.length) {
                          final jobOffer = _jobOffers[index];
                          return _buildJobOfferCard(jobOffer);
                        } else {
                          final messageIndex = index - _jobOffers.length;
                          final message = _messages[messageIndex];
                          final isCurrentUser =
                              message.senderId == widget.currentUserId;

                          return MessageBubble(
                            message: message,
                            isCurrentUser: isCurrentUser,
                            showSenderName: !isCurrentUser,
                          );
                        }
                      },
                    ),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Location share button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isShareLocation
                            ? const Color(0xFFE53E3E).withValues(alpha: 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isShareLocation
                              ? const Color(0xFFE53E3E).withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: _isShareLocation
                            ? null
                            : _shareCurrentLocation,
                        icon: _isShareLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFE53E3E),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.location_on,
                                color: Color(0xFFE53E3E),
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.chat_outlined,
                size: 40,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start the conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to begin chatting about the job.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobOfferCard(JobOffer jobOffer) {
    final isFromCurrentUser = jobOffer.employerId == widget.currentUserId;
    final canRespond = !isFromCurrentUser && jobOffer.isPending;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.work,
                    color: jobOffer.isAccepted
                        ? Colors.green
                        : jobOffer.isRejected
                        ? Colors.red
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Job Offer: ${jobOffer.title}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: jobOffer.isAccepted
                          ? Colors.green.shade100
                          : jobOffer.isRejected
                          ? Colors.red.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      jobOffer.statusDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: jobOffer.isAccepted
                            ? Colors.green.shade700
                            : jobOffer.isRejected
                            ? Colors.red.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Job details
              Text(jobOffer.description, style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Salary: ${jobOffer.formattedSalary}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  Text(
                    jobOffer.paymentFrequency,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Location: ${jobOffer.location}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),

              // Action buttons for helpers
              if (canRespond) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectJobOffer(jobOffer),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptJobOffer(jobOffer),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptJobOffer(JobOffer jobOffer) async {
    try {
      await JobOfferService.acceptJobOffer(jobOffer.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Job offer accepted! Your service posting has been paused.',
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }

      // Refresh job offers
      _loadJobOffers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept job offer. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error accepting job offer: $e');
    }
  }

  Future<void> _rejectJobOffer(JobOffer jobOffer) async {
    String reasonText = '';

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Job Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Why are you declining this offer?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Optional reason...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => reasonText = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              reasonText.isEmpty ? 'No reason provided' : reasonText,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await JobOfferService.rejectJobOffer(jobOffer.id, reason);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Job offer declined.')));
        }

        // Refresh job offers
        _loadJobOffers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to decline job offer. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('Error declining job offer: $e');
      }
    }
  }
}
