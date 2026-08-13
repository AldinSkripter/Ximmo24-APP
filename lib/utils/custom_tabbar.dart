import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/material.dart';

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({
    required this.tabController,
    required this.tabs,
    required this.isScrollable,
    this.onTap,
    this.margin,
    this.tabBackgroundColor,
    super.key,
  });
  final TabController tabController;
  final List<Widget> tabs;
  final bool isScrollable;
  final void Function(int)? onTap;
  final EdgeInsets? margin;
  final Color? tabBackgroundColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.rh(context),
      padding: const EdgeInsets.all(4),
      margin:
          margin ??
          EdgeInsets.symmetric(
            horizontal: 16.rw(context),
            vertical: 16.rh(context),
          ),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.color.borderColor),
      ),

      child: TabBar(
        onTap: onTap ?? (value) {},
        padding: EdgeInsets.zero,
        labelColor: context.color.buttonColor,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        unselectedLabelColor: context.color.textColorDark,
        indicatorSize: .tab,
        physics: isScrollable ? Constant.scrollPhysics : null,
        indicator: BoxDecoration(
          color: tabBackgroundColor ?? context.color.tertiaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        labelStyle: TextStyle(
          fontSize: context.font.sm.rf(context),
          fontWeight: .w500,
          color: context.color.buttonColor,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: context.font.sm.rf(context),
          fontWeight: .w500,
          color: context.color.textColorDark,
        ),
        tabAlignment: isScrollable ? TabAlignment.center : TabAlignment.fill,
        isScrollable: isScrollable,
        controller: tabController,
        tabs: tabs,
      ),
    );
  }
}
