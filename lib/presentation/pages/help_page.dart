import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';
import '../../core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:flutter/services.dart'; // for rootBundle
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // Pre-fill with logged-in user's email (hidden field)
  final _emailController = TextEditingController(
    text: SupabaseService.currentUser?.email ?? '',
  );
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _showForm = false; // whether contact form is expanded

  @override
  void initState() {
    super.initState();
    // No longer needed to load FAQ in initState because we use FutureBuilder
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        // Invoke Supabase Edge Function to send the contact email
        final _ = await Supabase.instance.client.functions.invoke(
          'send-mail',
          body: {
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'subject': _subjectController.text.trim(),
            'message': _messageController.text.trim(),
          },
        );
        // If the function returns an error, it will throw.
        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccessDialog();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur d\'envoi : $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  Future<List<FaqItem>> _loadFaqFromAssets() async {
    // Get the locale before the async call to avoid using BuildContext across async gap
    final locale = AppLocalizations.of(context)?.locale.languageCode ?? 'en';
    final String raw = await rootBundle.loadString('assets/faq.json');
    final Map<String, dynamic> jsonData = json.decode(raw);
    final String langKey = locale == 'fr' ? 'fr' : 'en';
    final List<dynamic> faqList = jsonData[langKey];
    return faqList
        .map(
          (item) => FaqItem(
            question: item['question'] as String,
            answer: item['answer'] as String,
          ),
        )
        .toList();
  }

  Widget _buildFAQList(
    AppLocalizations? loc,
    bool isDark,
    Color heading,
    Color muted,
  ) {
    return FutureBuilder<List<FaqItem>>(
      future: _loadFaqFromAssets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading FAQ: ${snapshot.error}'));
        }
        final faqItems = snapshot.data ?? [];
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: faqItems.length,
          itemBuilder: (context, index) {
            final item = faqItems[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  item.question,
                  style: TextStyle(fontWeight: FontWeight.w600, color: heading),
                ),
                backgroundColor: Theme.of(
                  context,
                ).cardColor.withValues(alpha: 0.05),
                childrenPadding: EdgeInsets.zero,
                collapsedBackgroundColor: Theme.of(
                  context,
                ).cardColor.withValues(alpha: 0.02),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(item.answer, style: TextStyle(color: muted)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactFormHeader(
    AppLocalizations? loc,
    bool isDark,
    Color heading,
    Color muted,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _showForm = !_showForm;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Write us button
            PrimaryButton(
              text: loc?.get('write_us') ?? 'Write to us',
              onPressed: () {
                setState(() {
                  _showForm = !_showForm;
                });
              },
              isLoading: false,
            ),
            const SizedBox(height: 12),
            // Description text
            Text(
              loc?.get('support_description') ??
                  'A question or an issue? Our team answers by email.',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactFormBody(
    AppLocalizations? loc,
    bool isDark,
    Color heading,
    Color muted,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // ---- NAME ----
            CustomTextField(
              controller: _nameController,
              label: loc?.get('name') ?? 'Name',
              hintText: loc?.get('name_hint') ?? 'Enter your name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc?.get('error_field_required') ??
                      'This field is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // ---- EMAIL (HIDDEN) ----
            // We keep the controller but do NOT render a field.
            // Uncomment the block below if you ever need to show it for debugging.
            /*
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
            */
            const SizedBox(height: 16),
            // ---- SUBJECT ----
            CustomTextField(
              controller: _subjectController,
              label: loc?.get('subject') ?? 'Subject',
              hintText: loc?.get('subject_hint') ?? 'Enter subject',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc?.get('error_field_required') ??
                      'This field is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // ---- MESSAGE ----
            CustomTextField(
              controller: _messageController,
              label: loc?.get('message') ?? 'Message',
              hintText: loc?.get('message_hint') ?? 'Enter your message',
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc?.get('error_field_required') ??
                      'This field is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // ---- SEND BUTTON (label from localisation) ----
            PrimaryButton(
              text: loc?.get('send_button') ?? 'Send',
              onPressed: _submitForm,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color heading = isDark
        ? const Color(0xFFECF0F1)
        : const Color(0xFF102A56);
    final Color muted = isDark
        ? const Color(0xFFBDC3C7)
        : const Color(0xFF5A7194);

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
            // Contact form header (always visible)
            _buildContactFormHeader(loc, isDark, heading, muted),
            // Animated form body
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showForm
                  ? _buildContactFormBody(loc, isDark, heading, muted)
                  : Container(), // empty container when collapsed
            ),
            const SizedBox(height: 24),
            // FAQ title
            Text(
              loc?.get('faq') ?? 'FAQ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: heading,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQList(loc, isDark, heading, muted),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
