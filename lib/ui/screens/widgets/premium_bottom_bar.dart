import 'dart:ui';

import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/add_listing_button.dart';
import 'package:flutter/material.dart';

class PremiumBottomBar extends StatelessWidget {
  const PremiumBottomBar({
    required this.currentTab,
    required this.onTabTapped,
    required this.addListingController,
    required this.firstLabel,
    super.key,
  });

  final int currentTab;
  final ValueChanged<int> onTabTapped;
  final AddListingController addListingController;
  final String firstLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.color.primaryColor,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(
          left: 12.rw(context),
          right: 12.rw(context),
          bottom: 8.rh(context),
        ),
        child: Container(
          height: 72.rh(context),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.rw(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.color.brightness == Brightness.light
                      ? 0.12
                      : 0.34,
                ),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: context.color.tertiaryColor.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.rw(context)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: [
                            context.color.secondaryColor.withValues(
                              alpha: 0.88,
                            ),
                            context.color.secondaryColor.withValues(
                              alpha: 0.68,
                            ),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24.rw(context)),
                        border: Border.all(
                          color:
                              context.color.brightness == Brightness.light
                              ? Colors.white.withValues(alpha: 0.72)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    _PremiumNavItem(
                      index: 0,
                      currentTab: currentTab,
                      icon: AppIcons.home,
                      activeIcon: AppIcons.homeActive,
                      label: firstLabel,
                      onTap: onTabTapped,
                    ),
                    _PremiumNavItem(
                      index: 1,
                      currentTab: currentTab,
                      icon: AppIcons.chat,
                      activeIcon: AppIcons.chatActive,
                      label: 'chat'.translate(context),
                      onTap: onTabTapped,
                    ),
                    Expanded(
                      child: Transform.translate(
                        offset: Offset(0, -18.rh(context)),
                        child: AddListingButton(
                          controller: addListingController,
                        ),
                      ),
                    ),
                    _PremiumNavItem(
                      index: 3,
                      currentTab: currentTab,
                      icon: AppIcons.properties,
                      activeIcon: AppIcons.propertiesActive,
                      label: 'myListings'.translate(context),
                      onTap: onTabTapped,
                    ),
                    _PremiumNavItem(
                      index: 4,
                      currentTab: currentTab,
                      icon: AppIcons.profileOutlined,
                      activeIcon: AppIcons.profileActive,
                      label: 'profileTab'.translate(context),
                      onTap: onTabTapped,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumNavItem extends StatelessWidget {
  const _PremiumNavItem({
    required this.index,
    required this.currentTab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentTab;
  final String icon;
  final String activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = currentTab == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.symmetric(
              horizontal: 3.rw(context),
              vertical: 8.rh(context),
            ),
            padding: EdgeInsets.symmetric(horizontal: 3.rw(context)),
            decoration: BoxDecoration(
              color: isActive
                  ? context.color.tertiaryColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16.rw(context)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.08 : 1,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: CustomImage(
                    imageUrl: isActive ? activeIcon : icon,
                    width: 23.rw(context),
                    height: 23.rh(context),
                    color: isActive
                        ? context.color.tertiaryColor
                        : context.color.textLightColor,
                  ),
                ),
                SizedBox(height: 4.rh(context)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: CustomText(
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    fontSize: context.font.xxs,
                    fontWeight: isActive
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isActive
                        ? context.color.tertiaryColor
                        : context.color.textLightColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
