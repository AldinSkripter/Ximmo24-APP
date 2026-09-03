import 'dart:async';

import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/cubits/system/fetch_language_cubit.dart';
import 'package:ebroker/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:ebroker/data/cubits/system/language_cubit.dart';
import 'package:ebroker/data/cubits/system/update_language_cubit.dart';
import 'package:ebroker/data/helper/widgets.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:ebroker/utils/language_change_helper.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class PremiumOnboardingVisual extends StatefulWidget {
  const PremiumOnboardingVisual({required this.page, super.key});

  final int page;

  @override
  State<PremiumOnboardingVisual> createState() =>
      _PremiumOnboardingVisualState();
}

class _PremiumOnboardingVisualState extends State<PremiumOnboardingVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.color.tertiaryColor;
    return IgnorePointer(
      child: SizedBox(
        width: 360.rw(context),
        height: 330.rh(context),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final motion = Curves.easeInOut.transform(_controller.value);
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Transform.scale(
                  scale: 0.96 + motion * 0.05,
                  child: Container(
                    width: 250.rw(context),
                    height: 250.rh(context),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.22),
                          accent.withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 18.rw(context),
                  top: 58.rh(context) + motion * 8,
                  child: Transform.rotate(
                    angle: -0.08,
                    child: _floatingCard(
                      context,
                      icon: Icons.apartment_rounded,
                      size: const Size(112, 92),
                      opacity: 0.78,
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: 14.rw(context),
                  bottom: 52.rh(context) + (1 - motion) * 9,
                  child: Transform.rotate(
                    angle: 0.07,
                    child: _floatingCard(
                      context,
                      icon: widget.page == 2
                          ? Icons.verified_user_rounded
                          : Icons.location_on_rounded,
                      size: const Size(108, 88),
                      opacity: 0.72,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -5 + motion * 10),
                  child: _phoneFrame(context, motion),
                ),
                if (widget.page == 0)
                  PositionedDirectional(
                    end: 44.rw(context),
                    top: 48.rh(context) - motion * 5,
                    child: _accentBubble(
                      context,
                      Icons.key_rounded,
                      52,
                    ),
                  ),
                if (widget.page == 1)
                  PositionedDirectional(
                    end: 38.rw(context),
                    top: 50.rh(context) - motion * 6,
                    child: _accentBubble(
                      context,
                      Icons.favorite_rounded,
                      54,
                    ),
                  ),
                if (widget.page == 2)
                  PositionedDirectional(
                    end: 40.rw(context),
                    top: 48.rh(context) - motion * 6,
                    child: _accentBubble(
                      context,
                      Icons.forum_rounded,
                      54,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _phoneFrame(BuildContext context, double motion) {
    final accent = context.color.tertiaryColor;
    return Container(
      width: 174.rw(context),
      height: 270.rh(context),
      padding: EdgeInsets.all(9.rw(context)),
      decoration: BoxDecoration(
        color: context.color.textColorDark,
        borderRadius: BorderRadius.circular(34.rw(context)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 30,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26.rw(context)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.color.secondaryColor,
                accent.withValues(alpha: 0.10),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.rw(context)),
            child: _phoneContent(context, motion),
          ),
        ),
      ),
    );
  }

  Widget _phoneContent(BuildContext context, double motion) {
    final accent = context.color.tertiaryColor;
    if (widget.page == 1) {
      return Column(
        children: [
          Container(
            height: 32.rh(context),
            decoration: BoxDecoration(
              color: context.color.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(width: 9.rw(context)),
                Icon(Icons.search_rounded, size: 16, color: accent),
                const Spacer(),
                Icon(Icons.tune_rounded, size: 16, color: accent),
                SizedBox(width: 9.rw(context)),
              ],
            ),
          ),
          SizedBox(height: 12.rh(context)),
          for (var i = 0; i < 2; i++) ...[
            Expanded(
              child: Transform.translate(
                offset: Offset((i == 0 ? -1 : 1) * motion * 2, 0),
                child: _listingPreview(context, i),
              ),
            ),
            if (i == 0) SizedBox(height: 9.rh(context)),
          ],
        ],
      );
    }
    if (widget.page == 2) {
      return Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: accent),
              SizedBox(width: 8.rw(context)),
              Expanded(child: _line(context, 8, 0.55)),
            ],
          ),
          SizedBox(height: 22.rh(context)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _messageBubble(context, false, 0.82),
          ),
          SizedBox(height: 12.rh(context)),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _messageBubble(context, true, 0.68),
          ),
          SizedBox(height: 12.rh(context)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _messageBubble(context, false, 0.58),
          ),
          const Spacer(),
          Container(
            height: 32.rh(context),
            decoration: BoxDecoration(
              color: context.color.primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 24,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 54.rw(context),
              child: _line(context, 7, 1),
            ),
            const Spacer(),
            Icon(Icons.notifications_none_rounded, size: 18, color: accent),
          ],
        ),
        SizedBox(height: 14.rh(context)),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.58)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.villa_rounded,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 62,
                  ),
                ),
                PositionedDirectional(
                  end: 10,
                  top: 10,
                  child: Icon(
                    Icons.favorite_border_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.rh(context)),
        _line(context, 9, 0.82),
        SizedBox(height: 7.rh(context)),
        _line(context, 7, 0.54),
        SizedBox(height: 12.rh(context)),
        Row(
          children: [
            Icon(Icons.location_on_rounded, size: 15, color: accent),
            SizedBox(width: 5.rw(context)),
            Expanded(child: _line(context, 6, 1)),
          ],
        ),
      ],
    );
  }

  Widget _listingPreview(BuildContext context, int index) {
    final accent = context.color.tertiaryColor;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.color.primaryColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42.rw(context),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: index == 0 ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.home_work_rounded, color: accent, size: 23),
          ),
          SizedBox(width: 8.rw(context)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(context, 7, 0.9),
                const SizedBox(height: 6),
                _line(context, 6, 0.62),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble(BuildContext context, bool accentBubble, double width) {
    return FractionallySizedBox(
      widthFactor: width,
      child: Container(
        height: 34.rh(context),
        decoration: BoxDecoration(
          color: accentBubble
              ? context.color.tertiaryColor
              : context.color.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(13),
            topRight: const Radius.circular(13),
            bottomLeft: Radius.circular(accentBubble ? 13 : 4),
            bottomRight: Radius.circular(accentBubble ? 4 : 13),
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, double height, double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height.rh(context),
        decoration: BoxDecoration(
          color: context.color.textLightColor.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _floatingCard(
    BuildContext context, {
    required IconData icon,
    required Size size,
    required double opacity,
  }) {
    return Container(
      width: size.width.rw(context),
      height: size.height.rh(context),
      decoration: BoxDecoration(
        color: context.color.secondaryColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(22.rw(context)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.52)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: context.color.tertiaryColor, size: 30),
    );
  }

  Widget _accentBubble(BuildContext context, IconData icon, double size) {
    return Container(
      width: size.rw(context),
      height: size.rh(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.color.tertiaryColor,
            context.color.tertiaryColor.withValues(alpha: 0.68),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: context.color.tertiaryColor.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPageIndex = 0;
  late int totalPages;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slidersList = <Map<String, dynamic>>[
      {
        'title': 'onboarding_1_title'.translate(context),
        'description': 'onboarding_1_description'.translate(context),
      },
      {
        'title': 'onboarding_2_title'.translate(context),
        'description': 'onboarding_2_description'.translate(context),
      },
      {
        'title': 'onboarding_3_title'.translate(context),
        'description': 'onboarding_3_description'.translate(context),
      },
    ];

    totalPages = slidersList.length;
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.color.tertiaryColor.withValues(alpha: 0.18),
                context.color.backgroundColor,
                context.color.tertiaryColor.withValues(alpha: 0.06),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18.rw(context),
                    10.rh(context),
                    18.rw(context),
                    0,
                  ),
                  child: Row(
                    children: [
                      MultiBlocListener(
                listeners: [
                  BlocListener<FetchLanguageCubit, FetchLanguageState>(
                    listener: (context, state) async {
                      if (state is FetchLanguageInProgress) {
                        unawaited(Widgets.showLoader(context));
                      }
                      if (state is FetchLanguageFailure) {
                        Widgets.hideLoder(context);
                        HelperUtils.showSnackBarMessage(
                          context,
                          state.errorMessage,
                          type: .error,
                        );
                      }
                      if (state is FetchLanguageSuccess) {
                        Widgets.hideLoder(context);
                        final map = state.toMap();
                        final data = map['file_name'];
                        map['data'] = data;

                        map.remove('file_name');
                        await HiveUtils.storeLanguage(map);
                        context.read<LanguageCubit>().emitLanguageLoader(
                          code: state.code,
                          isRtl: state.isRTL,
                        );
                        // Update all data after language change
                        await _syncLanguageChange(context, state.code);
                      }
                    },
                  ),
                  BlocListener<UpdateLanguageCubit, UpdateLanguageState>(
                    listener: (context, state) async {
                      if (state is UpdateLanguageInProgress) {
                        unawaited(Widgets.showLoader(context));
                      } else if (state is UpdateLanguageFailure) {
                        Widgets.hideLoder(context);
                        HelperUtils.showSnackBarMessage(
                          context,
                          state.errorMessage,
                          type: .error,
                        );
                      } else if (state is UpdateLanguageSuccess ||
                          state is UpdateLanguageSkipped) {
                        Widgets.hideLoder(context);
                      }
                    },
                  ),
                ],
                        child: _buildLanguageDropdown(),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await Navigator.pushReplacementNamed(
                            context,
                            Routes.login,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.rw(context),
                            vertical: 9.rh(context),
                          ),
                          decoration: BoxDecoration(
                            color: context.color.secondaryColor.withValues(
                              alpha: 0.72,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          child: CustomText(
                            'skip'.translate(context),
                            color: context.color.textColorDark,
                            fontSize: context.font.sm,
                            fontWeight: .w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: Constant.scrollPhysics,
                    onPageChanged: (index) =>
                        setState(() => currentPageIndex = index),
                    itemCount: slidersList.length,
                    itemBuilder: (context, index) => Center(
                      child: PremiumOnboardingVisual(
                        key: ValueKey('premium-visual-$index'),
                        page: index,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    14.rw(context),
                    0,
                    14.rw(context),
                    12.rh(context),
                  ),
                  child: _buildOnboardingCard(context, slidersList),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingCard(
    BuildContext context,
    List<Map<String, dynamic>> slidersList,
  ) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 260.rh(context)),
      padding: EdgeInsets.fromLTRB(
        24.rw(context),
        28.rh(context),
        24.rw(context),
        20.rh(context),
      ),
      decoration: BoxDecoration(
        color: context.color.secondaryColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(36.rw(context)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 38,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(currentPageIndex),
              children: [
                CustomText(
                  slidersList[currentPageIndex]['title']?.toString() ?? '',
                  fontWeight: .w700,
                  fontSize: context.font.xxl,
                  color: context.color.textColorDark,
                  textAlign: .center,
                ),
                SizedBox(height: 12.rh(context)),
                CustomText(
                  slidersList[currentPageIndex]['description']?.toString() ??
                      '',
                  maxLines: 4,
                  textAlign: .center,
                  fontSize: context.font.md,
                  color: context.color.textLightColor,
                  fontWeight: .w500,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.rh(context)),
          Row(
            children: [
              for (var i = 0; i < slidersList.length; i++)
                buildIndicator(context, selected: i == currentPageIndex),
              const Spacer(),
              GestureDetector(
                key: const ValueKey('next_screen'),
                onTap: _goToNextOnboardingPage,
                child: Container(
                  width: 58.rw(context),
                  height: 58.rh(context),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.color.tertiaryColor,
                        context.color.tertiaryColor.withValues(alpha: 0.72),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.rw(context)),
                    boxShadow: [
                      BoxShadow(
                        color: context.color.tertiaryColor.withValues(
                          alpha: 0.32,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CustomImage(
                    matchTextDirection: true,
                    imageUrl: AppIcons.arrowRight,
                    fit: .contain,
                    color: context.color.buttonColor,
                    width: 24.rw(context),
                    height: 24.rh(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _goToNextOnboardingPage() async {
    if (currentPageIndex < totalPages - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await Navigator.of(context).pushNamedAndRemoveUntil(
      Routes.login,
      (route) => false,
    );
  }

  Widget buildIndicator(BuildContext context, {required bool selected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsetsDirectional.only(end: 10),
      width: selected ? 28.rw(context) : 8.rw(context),
      height: 8.rh(context),
      decoration: BoxDecoration(
        borderRadius: selected
            ? BorderRadius.circular(7)
            : BorderRadius.circular(100),
        color: selected ? context.color.tertiaryColor : Colors.transparent,
        border: selected
            ? null
            : Border.all(color: context.color.textColorDark),
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    final languageSettings =
        context.watch<FetchSystemSettingsCubit>().getSetting(
              SystemSetting.languageType,
            )
            as List?;

    if (languageSettings == null || languageSettings.isEmpty) {
      return Container();
    }

    final languageState = context.watch<LanguageCubit>().state;
    var currentLanguageCode = '';
    var currentLanguageName = '';

    if (languageState is LanguageLoader) {
      currentLanguageCode = languageState.languageCode.toString();
      // Find the current language name
      final currentLang = languageSettings.firstWhere(
        (lang) => lang['code'].toString() == currentLanguageCode,
        orElse: () => languageSettings.first,
      );
      currentLanguageName = currentLang['name'].toString().firstUpperCase();
    }

    return PopupMenuButton<String>(
      color: context.color.secondaryColor,
      position: PopupMenuPosition.under,
      offset: Offset(-8.rw(context), 8.rh(context)),
      elevation: 4,
      padding: .zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.color.borderColor),
        borderRadius: .circular(12.rw(context)),
      ),
      menuPadding: .all(8.rw(context)),
      onSelected: (newLanguageCode) async {
        if (newLanguageCode != currentLanguageCode) {
          await context.read<FetchLanguageCubit>().getLanguage(newLanguageCode);
        }
      },
      itemBuilder: (context) {
        return languageSettings.map<PopupMenuEntry<String>>((language) {
          final languageCode = language['code'].toString();
          final languageName = language['name'].toString();
          final isSelected = languageCode == currentLanguageCode;

          return PopupMenuItem<String>(
            value: languageCode,
            padding: .zero,
            height: 32.rh(context),
            child: Container(
              padding: .symmetric(
                horizontal: 12.rw(context),
                vertical: 8.rh(context),
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.color.tertiaryColor.withValues(alpha: 0.1)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomText(
                    languageName.firstUpperCase(),
                    color: isSelected
                        ? context.color.tertiaryColor
                        : context.color.textColorDark,
                    fontSize: context.font.md,
                    fontWeight: isSelected ? .bold : .w600,
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    Icon(
                      Icons.check,
                      color: context.color.tertiaryColor,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Row(
        mainAxisSize: .min,
        children: [
          CustomText(
            currentLanguageName,
            color: context.color.textColorDark,
            fontSize: context.font.md,
            fontWeight: .w600,
          ),
          SizedBox(width: 4.rw(context)),
          Icon(
            Icons.keyboard_arrow_down_outlined,
            color: context.color.textColorDark,
            size: 24,
          ),
        ],
      ),
    );
  }

  Future<void> _syncLanguageChange(
    BuildContext context,
    String languageCode,
  ) async {
    await context.read<UpdateLanguageCubit>().updateLanguage(
      languageCode: languageCode,
    );
    LanguageChangeHelper.refreshAppData(context);
  }
}
