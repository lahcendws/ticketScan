import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A345B91),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                index: 0,
                context: context,
              ),
              _buildNavItem(
                icon: Icons.confirmation_number_outlined,
                selectedIcon: Icons.confirmation_number,
                index: 1,
                context: context,
              ),
              _buildNavItem(
                icon: Icons.notifications_none,
                selectedIcon: Icons.notifications,
                index: 2,
                context: context,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                index: 3,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required int index,
    required BuildContext context,
  }) {
    final bool isSelected = currentIndex == index;

    final Color color = isSelected
        ? Theme.of(context).primaryColor
        : Colors.grey.shade400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                index == 0
                    ? (isSelected ? Icons.home : Icons.home_outlined)
                    : (isSelected ? selectedIcon : icon),
                color: color,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                _labelFor(index, context),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(int index, BuildContext context) {
    final loc = AppLocalizations.of(context);
    switch (index) {
      case 0:
        return loc?.get('home') ?? 'Accueil';
      case 1:
        return loc?.get('my_tickets') ?? 'Mes tickets';
      case 2:
        return loc?.get('alerts') ?? 'Alertes';
      case 3:
        return loc?.get('account') ?? 'Compte';
      default:
        return '';
    }
  }
}
