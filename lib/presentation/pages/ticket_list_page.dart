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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          localizations?.get('my_tickets') ?? 'Mes tickets',
        ),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).primaryColor,
        onRefresh: provider.loadTickets,
        child: _buildBody(provider, localizations),
      ),
    );
  }

  Widget _buildBody(TicketProvider provider, AppLocalizations? localizations) {
    if (provider.isLoading && provider.tickets.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    if (provider.tickets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          Icon(
            Icons.confirmation_number_outlined,
            size: 52,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              localizations?.get('no_tickets') ?? 'Aucun ticket enregistré',
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16),
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
