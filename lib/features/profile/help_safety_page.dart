import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/constants.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class HelpSafetyPage extends StatelessWidget {
  const HelpSafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(locale.helpSafetyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: locale.faqTitle,
              prefixIcon: const Icon(Icons.search_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Safety Tips
          FlatmatesSectionHeader(title: locale.safetyTips),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _ExpandableCard(
                  icon: Icons.people_outline,
                  title: 'Meet in public',
                  body: 'Always schedule your first flatmate meetup or property visit in a public place. '
                      'Choose a cafe, society gate, or any well-lit area with people around.',
                ),
                const Divider(height: 1),
                _ExpandableCard(
                  icon: Icons.lock_outline,
                  title: "Don't share financial info",
                  body: 'Never share your bank details, UPI PIN, or passwords with anyone on the platform. '
                      'All payments should go through verified channels only.',
                ),
                const Divider(height: 1),
                _ExpandableCard(
                  icon: Icons.verified_outlined,
                  title: 'Verify listings',
                  body: 'Before signing any agreement, verify the property details in person. '
                      'Check the property documents and ensure the listing owner is authorized to rent.',
                ),
                const Divider(height: 1),
                _ExpandableCard(
                  icon: Icons.report_outlined,
                  title: 'Report suspicious behavior',
                  body: 'If someone asks for money upfront, pressures you, or behaves inappropriately, '
                      'report them immediately. We take all reports seriously and act quickly.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FAQ
          FlatmatesSectionHeader(title: locale.faqTitle),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _ExpandableCard(
                  icon: Icons.help_outline,
                  title: 'How does 360 FlatMates work?',
                  body: 'Create a profile, browse flatmates and listings, swipe or express interest, '
                      'chat with matches, schedule visits, and move in. Our compatibility engine helps '
                      'you find flatmates who share your lifestyle.',
                ),
                const Divider(height: 1),
                _ExpandableCard(
                  icon: Icons.help_outline,
                  title: 'Is my profile visible to everyone?',
                  body: 'Your profile is only visible to other verified flatmates on the platform. '
                      'You can control what information is shown by adjusting your privacy settings.',
                ),
                const Divider(height: 1),
                _ExpandableCard(
                  icon: Icons.help_outline,
                  title: 'How do I post a listing?',
                  body: 'Go to the "Post" tab in the bottom navigation, fill in your property details '
                      'including rent, room type, and photos, then publish. Your listing will be reviewed '
                      'within 24 hours before going live.',
                ),
                const Divider(height: 1),
                _ExpandableCard(
                  icon: Icons.help_outline,
                  title: 'What does the compatibility score mean?',
                  body: 'The compatibility score compares your lifestyle preferences (sleep schedule, '
                      'cleanliness, food habits, etc.) with potential flatmates. A higher score means '
                      'a better lifestyle match.',
                ),
                const Divider(height: 1),
                _ExpandableCard(
                  icon: Icons.help_outline,
                  title: 'How do visits work?',
                  body: 'Once you match with a listing, you can schedule a visit through the app. '
                      'The listing owner will confirm the time, and you will receive a notification '
                      'when the visit is confirmed.',
                ),
                const Divider(height: 1),
                _ExpandableCard(
                  icon: Icons.help_outline,
                  title: 'Can I block or report someone?',
                  body: 'Yes. Open any chat, tap the menu, and choose "Block" or "Report". '
                      'Blocked users cannot see your profile or contact you. Reports are reviewed '
                      'by our team within 24 hours.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Report a Problem
          FlatmatesSectionHeader(title: locale.reportProblem),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(locale.reportProblem),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showReportDialog(context, locale),
            ),
          ),
          const SizedBox(height: 24),

          // Contact Support
          FlatmatesSectionHeader(title: locale.contactSupport),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: Icon(
                Icons.email_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(kSupportEmail),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => launchUrl(Uri.parse('mailto:$kSupportEmail')),
            ),
          ),
          const SizedBox(height: 24),

          // Community Guidelines
          FlatmatesSectionHeader(title: locale.communityGuidelines),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: Icon(
                Icons.groups_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(locale.communityGuidelines),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => launchUrl(Uri.parse('https://the360ghar.com/community-guidelines')),
            ),
          ),
          const SizedBox(height: 24),

          // Privacy Policy
          FlatmatesSectionHeader(title: locale.privacyPolicy),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: Icon(
                Icons.policy_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(locale.privacyPolicy),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl)),
            ),
          ),
          const SizedBox(height: 24),

          // Terms of Service
          FlatmatesSectionHeader(title: locale.termsOfService),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: Icon(
                Icons.description_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(locale.termsOfService),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => launchUrl(Uri.parse(kTermsOfServiceUrl)),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, AppLocalizations locale) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.reportProblem),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.cancelCta),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(locale.reportSubmitted)),
              );
            },
            child: Text(locale.reportCta),
          ),
        ],
      ),
    );
  }
}

class _ExpandableCard extends StatefulWidget {
  const _ExpandableCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isExpanded ? 0.5 : 0,
                  child: const Icon(Icons.expand_more_rounded, size: 20),
                ),
              ],
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  widget.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
