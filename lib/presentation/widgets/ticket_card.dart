import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/ticket_model.dart';

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TicketCard({
    super.key,
    required this.ticket,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom du magasin et options
              Row(
                children: [
                  // Icône du magasin
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.store,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Informations du magasin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.storeName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMMM yyyy', 'fr_FR').format(ticket.date),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge de garantie et menu
                  Row(
                    children: [
                      if (ticket.isWarrantyExpiringSoon())
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Garantie',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(width: 8),
                      
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'delete':
                              onDelete?.call();
                              break;
                            case 'share':
                              _shareTicket(context);
                              break;
                            case 'edit':
                              _editTicket(context);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, size: 20),
                                SizedBox(width: 8),
                                Text('Partager'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Montant total
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${ticket.totalAmount.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Aperçu des produits
              if (ticket.products.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Produits:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...ticket.products.take(3).map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 4,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          product,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
                
                if (ticket.products.length > 3)
                  Text(
                    '+${ticket.products.length - 3} autres produits...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
              
              // Statut de la garantie
              if (ticket.isWarrantyExpired()) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Garantie expirée le ${DateFormat('dd MMMM yyyy', 'fr_FR').format(ticket.warrantyEndDate)}',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (ticket.isWarrantyExpiringSoon()) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Garantie expire dans ${ticket.warrantyEndDate.difference(DateTime.now()).inDays} jours',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _shareTicket(BuildContext context) {
    // TODO: Implémenter le partage de ticket
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage bientôt disponible')),
    );
  }

  void _editTicket(BuildContext context) {
    // TODO: Implémenter l'édition de ticket
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité d\'édition bientôt disponible')),
    );
  }
}
