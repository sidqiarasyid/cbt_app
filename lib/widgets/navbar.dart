import 'package:cbt_app/style/style.dart';
import 'package:flutter/material.dart';

class NavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const NavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnimation;

  static const Color _activeColor = Color(0xFF11B1E2);
  static const Color _inactiveColor = Color(0xFF9E9E9E);
  static const Color _activeBg = Color(0xFFE1F5FE);
  static const double _navHeight = 70;
  static const double _elevatedSize = 56;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'History'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(covariant NavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _navHeight + 20, // extra space for elevated circle
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Nav bar background — matches page background with drop shadow
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: _navHeight,
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: ColorsApp.backgroundColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 28,
                        spreadRadius: 0,
                        offset: const Offset(0, -4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Nav items
              Positioned(
                left: 16,
                right: 16,
                bottom: 8,
                child: SizedBox(
                  height: _navHeight + 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_items.length, (index) {
                      final isActive = widget.selectedIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onItemTapped(index),
                          behavior: HitTestBehavior.opaque,
                          child: _buildNavItem(index, isActive),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isActive) {
    return _NavAnimBuilder(
      animation: _animController,
      builder: (context, child) {
        final isAnimating = widget.selectedIndex == index && _animController.isAnimating;
        final scale = isAnimating ? _bounceAnimation.value : 1.0;

        return SizedBox(
          height: _navHeight + 20,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Icon circle
              Positioned(
                bottom: isActive ? 38 : 22,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: _elevatedSize,
                  height: _elevatedSize,
                  decoration: BoxDecoration(
                    color: isActive ? _activeBg : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(color: Colors.white, width: 4)
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _activeColor.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      _items[index].icon,
                      size: isActive ? 28 : 24,
                      color: isActive ? _activeColor : _inactiveColor,
                    ),
                  ),
                ),
              ),
              // Label
              Positioned(
                bottom: isActive ? 8 : 6,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isActive ? 12 : 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? _activeColor : _inactiveColor,
                  ),
                  child: Text(_items[index].label),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

/// Listenable wrapper for combining AnimationController with widget rebuilds.
class _NavAnimBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;

  const _NavAnimBuilder({
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: animation,
      builder: (context, _) => builder(context, null),
    );
  }
}
