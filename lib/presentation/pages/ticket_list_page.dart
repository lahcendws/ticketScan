import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_localizations.dart';
import '../../data/models/ticket_provider.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_page.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  static const _primary = Color(0xFF147DFF);
  static const _navy = Color(0xFF102A56);
  static const _muted = Color(0xFF5A7194);
  static const _background = Color(0xFFF8FBFF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketProvider>().loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final provider = context.watch<TicketProvider>();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: Text(
          localizations?.get('my_tickets') ?? 'Mes tickets',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: provider.loadTickets,
        child: _buildBody(provider, localizations),
      ),
    );
  }

  Widget _buildBody(TicketProvider provider, AppLocalizations? localizations) {
    if (provider.isLoading && provider.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    if (provider.tickets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          const Icon(
            Icons.confirmation_number_outlined,
            size: 52,
            color: Color(0xFF9DB4D1),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              localizations?.get('no_tickets') ?? 'Aucun ticket enregistré',
              style: const TextStyle(color: _muted, fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      itemCount: provider.tickets.length,
      itemBuilder: (context, index) {
        final ticket = provider.tickets[index];
        return TicketCard(
          ticket: ticket,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TicketDetailPage(ticket: ticket)),
          ),
          onDelete: () => provider.deleteTicket(ticket.id!),
        );
      },
    );
  }
}
