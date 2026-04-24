import 'package:flutter/material.dart';

import '../shared/presentation/flatmates_ui.dart';

class MatchCelebrationScreen extends StatefulWidget {
  const MatchCelebrationScreen({
    required this.userName,
    required this.userImageUrl,
    required this.peerName,
    required this.peerImageUrl,
    required this.onOpenChat,
    required this.onKeepSwiping,
    super.key,
  });

  final String userName;
  final String? userImageUrl;
  final String peerName;
  final String? peerImageUrl;
  final VoidCallback onOpenChat;
  final VoidCallback onKeepSwiping;

  @override
  State<MatchCelebrationScreen> createState() => _MatchCelebrationScreenState();
}

class _MatchCelebrationScreenState extends State<MatchCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  '🎉',
                  style: const TextStyle(fontSize: 64),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  "It's a Match!",
                  style: theme.textTheme.headlineLarge?.copyWith(fontSize: 36),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You and ${widget.peerName} liked each other',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MatchAvatar(name: widget.userName, imageUrl: widget.userImageUrl),
                    const SizedBox(width: 20),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    _MatchAvatar(name: widget.peerName, imageUrl: widget.peerImageUrl),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('match_open_chat'),
                        onPressed: widget.onOpenChat,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Send a message'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('match_keep_swiping'),
                        onPressed: widget.onKeepSwiping,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Keep swiping'),
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
}

class _MatchAvatar extends StatelessWidget {
  const _MatchAvatar({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary, width: 3),
        gradient: hasImage
            ? null
            : LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.9),
                  theme.colorScheme.primary.withValues(alpha: 0.5),
                ],
              ),
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _AvatarInitials(name: name),
              ),
            )
          : _AvatarInitials(name: name),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  const _AvatarInitials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initialsFromName(name),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
      ),
    );
  }
}
