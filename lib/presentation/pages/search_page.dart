import 'package:flutter/material.dart';
import '../../data/models/ticket_model.dart';
// import '../../core/services/firebase_service.dart';
import '../../core/services/supabase_service.dart';
import '../widgets/ticket_card.dart';

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
      // final documents = await FirebaseService.searchTickets(query);
      final documents = await SupabaseService.searchTickets(query);
      final tickets = documents
          .map((data) => TicketModel.fromMap(data))
          .toList();

      setState(() {
        _searchResults = tickets;
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la recherche');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Champ de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Rechercher un ticket...',
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

          // Suggestions de recherche rapide
          if (!_hasSearched) _buildSearchSuggestions(),

          // Résultats de recherche
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final suggestions = [
      {'icon': Icons.store, 'text': 'Magasins'},
      {'icon': Icons.shopping_cart, 'text': 'Produits'},
      {'icon': Icons.calendar_today, 'text': 'Date'},
      {'icon': Icons.euro, 'text': 'Montant'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recherche rapide',
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
          
          // Tickets récents
          Text(
            'Recherches récentes',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // TODO: Implémenter les recherches récentes
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
                  'Aucune recherche récente',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
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
              'Aucun résultat trouvé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
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
            // Navigation vers le détail du ticket
            print('Navigate to ticket: ${ticket.id}');
          },
        );
      },
    );
  }
}
