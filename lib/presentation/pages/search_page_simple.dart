import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Champ de recherche
            TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un ticket...',
                prefixIcon: const Icon(Icons.search),
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
            
            const SizedBox(height: 24),
            
            // Suggestions de recherche
            _buildSearchSuggestions(context),
            
            const SizedBox(height: 24),
            
            // Message d'information
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recherche bientôt disponible',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scannez des tickets pour pouvoir les rechercher',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
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

  Widget _buildSearchSuggestions(BuildContext context) {
    final suggestions = [
      {'icon': Icons.store, 'text': 'Magasins'},
      {'icon': Icons.shopping_cart, 'text': 'Produits'},
      {'icon': Icons.calendar_today, 'text': 'Date'},
      {'icon': Icons.euro, 'text': 'Montant'},
    ];

    return Column(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Recherche "${suggestion['text']}" bientôt disponible')),
                );
              },
              backgroundColor: Theme.of(context).cardColor,
              side: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
