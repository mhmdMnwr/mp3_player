import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:mp3_player_v2/core/theme/app_colors.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  final Function(int) onTabChanged;
  final int currentIndex;

  const BottomNavigationBarWidget({
    super.key,
    required this.onTabChanged,
    this.currentIndex = 0,
  });

  @override
  State<BottomNavigationBarWidget> createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.onTabChanged(index);
  }

  @override
  void didUpdateWidget(covariant BottomNavigationBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _selectedIndex = widget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: GNav(
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
              rippleColor: AppColors.textPrimary.withValues(alpha: 0.12),
              hoverColor: AppColors.textPrimary.withValues(alpha: 0.12),
              haptic: true,
              tabBorderRadius: 16,
              tabBackgroundColor: AppColors.accent.withValues(alpha: 0.14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              gap: 8,
              color: AppColors.iconInactive,
              activeColor: AppColors.accent,
              iconSize: 22,
              textStyle: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                GButton(icon: Icons.home_rounded, text: 'Home'),
                GButton(icon: Icons.music_note_rounded, text: 'Audios'),
                GButton(icon: Icons.favorite_rounded, text: 'Favorites'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
