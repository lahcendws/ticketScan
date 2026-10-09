import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/app_localizations.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      // Here you would typically send the form data to your backend
      // For now, we'll just show a success message
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc?.get('support_title') ?? 'Contact support'),
        content: Text(
          loc?.get('success_message_sent') ??
              'Your message has been sent successfully. We will respond shortly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc?.get('ok') ?? 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchFAQ() async {
    const url = 'https://ticketscan.eu/faq.php';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc?.get('error_launch_url') ?? 'Could not launch URL',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color heading = isDark
        ? const Color(0xFFECF0F1)
        : const Color(0xFF102A56);
    final Color muted = isDark ? const Color(0xFFBDC3C7) : const Color(0xFF5A7194);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: heading,
        elevation: 0,
        title: Text(
          loc?.get('support_title') ?? 'Contact support',
          style: TextStyle(fontWeight: FontWeight.w800, color: heading),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildContactForm(loc, isDark, heading, muted),
            const SizedBox(height: 24),
            _buildFAQSection(loc, isDark, heading, muted),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm(
      AppLocalizations? loc, bool isDark, Color heading, Color muted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc?.get('write_us') ?? 'Write to us',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: heading,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc?.get('support_description') ??
                'A question or an issue? Our team answers by email.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: loc?.get('name') ?? 'Name',
                  hintText: loc?.get('name_hint') ?? 'Enter your name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc?.get('error_field_required') ?? 'This field is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: loc?.get('email') ?? 'Email',
                  hintText: loc?.get('email_hint') ?? 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc?.get('error_field_required') ?? 'This field is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return loc?.get('error_invalid_email') ?? 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _subjectController,
                  label: loc?.get('subject') ?? 'Subject',
                  hintText: loc?.get('subject_hint') ?? 'Enter subject',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc?.get('error_field_required') ?? 'This field is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _messageController,
                  label: loc?.get('message') ?? 'Message',
                  hintText: loc?.get('message_hint') ?? 'Enter your message',
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return loc?.get('error_field_required') ?? 'This field is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: loc?.get('contact_support_button') ?? 'Contact Support',
                  onPressed: _submitForm,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(
      AppLocalizations? loc, bool isDark, Color heading, Color muted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc?.get('faq') ?? 'FAQ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: heading,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc?.get('faq_description') ??
                'Find answers to common questions on our FAQ page.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: loc?.get('faq_button') ?? 'Visit FAQ Page',
            onPressed: _launchFAQ,
            icon: const Icon(Icons.question_answer),
          ),
        ],
      ),
    );
  }
}
