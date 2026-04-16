import 'package:flutter/material.dart';
import '../../data/models/ticket_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/app_localizations.dart';
import '../widgets/ticket_card.dart';
import 'ticket_detail_page.dart'; // Import ajouté

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<TicketModel> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final documents = await SupabaseService.searchTickets(query);
      final tickets = documents
          .map((data) => TicketModel.fromMap(data))
          .toList();

      setState(() {
        _searchResults = tickets;
      });
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)?.get('generic_error') ?? 'Erreur');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.get('search') ?? 'Rechercher'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: localizations?.get('search_hint') ?? 'Rechercher un ticket...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          if (!_hasSearched) _buildSearchSuggestions(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final localizations = AppLocalizations.of(context);
    final suggestions = [
      {'icon': Icons.store, 'text': localizations?.get('stores') ?? 'Magasins'},
      {'icon': Icons.shopping_cart, 'text': localizations?.get('products') ?? 'Produits'},
      {'icon': Icons.calendar_today, 'text': localizations?.get('date') ?? 'Date'},
      {'icon': Icons.euro, 'text': localizations?.get('total') ?? 'Montant'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations?.get('quick_search') ?? 'Recherche rapide',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return ActionChip(
                avatar: Icon(
                  suggestion['icon'] as IconData,
                  size: 18,
                ),
                label: Text(suggestion['text'] as String),
                onPressed: () {
                  _searchController.text = suggestion['text'] as String;
                  _performSearch(suggestion['text'] as String);
                },
                backgroundColor: Theme.of(context).cardColor,
                side: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            localizations?.get('recent_searches') ?? 'Recherches récentes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 12),
                Text(
                  localizations?.get('no_recent_searches') ?? 'Aucune recherche récente',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final localizations = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasSearched) {
      return const SizedBox.shrink();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.get('no_results') ?? 'Aucun résultat trouvé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.get('try_other_keywords') ?? 'Essayez avec d\'autres mots-clés',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final ticket = _searchResults[index];
        return TicketCard(
          ticket: ticket,
          onTap: () {
            // FIX : Ajout de la navigation vers la page de détails
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketDetailPage(ticket: ticket),
              ),
            );
          },
        );
      },
    );
  }
}
