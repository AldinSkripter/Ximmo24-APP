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
import 'package:ebroker/utils/lottie/lottie_editor.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPageIndex = 0;
  late int totalPages;
  late final PageController _pageController;

  final LottieEditor _onBoardingOne = LottieEditor();
  final LottieEditor _onBoardingTwo = LottieEditor();
  final LottieEditor _onBoardingThree = LottieEditor();

  dynamic onBoardingOneData;
  dynamic onBoardingTwoData;
  dynamic onBoardingThreeData;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    Future.delayed(Duration.zero, () async {
      try {
        await _onBoardingOne.openAndLoad('assets/lottie/onbo_a.json');
        await _onBoardingTwo.openAndLoad('assets/lottie/onbo_b.json');
        await _onBoardingThree.openAndLoad('assets/lottie/onbo_c.json');

        if (!mounted) return;

        _onBoardingOne.changeWholeLottieFileColor(
          context.color.tertiaryColor,
        );
        _onBoardingTwo.changeWholeLottieFileColor(
          context.color.tertiaryColor,
        );
        _onBoardingThree.changeWholeLottieFileColor(
          context.color.tertiaryColor,
        );

        onBoardingOneData = _onBoardingOne.convertToUint8List();
        onBoardingTwoData = _onBoardingTwo.convertToUint8List();
        onBoardingThreeData = _onBoardingThree.convertToUint8List();
      } on Exception catch (e) {
        debugPrint('Error loading or processing Lottie files: $e');
        onBoardingOneData = null;
        onBoardingTwoData = null;
        onBoardingThreeData = null;
      }
      if (mounted) setState(() {});
    });
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
        'lottie': onBoardingOneData,
        'title': 'onboarding_1_title'.translate(context),
        'description': 'onboarding_1_description'.translate(context),
        'button': 'next_button.svg',
      },
      {
        'lottie': onBoardingTwoData,
        'title': 'onboarding_2_title'.translate(context),
        'description': 'onboarding_2_description'.translate(context),
      },
      {
        'lottie': onBoardingThreeData,
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
                      child: _buildLottieWidget(
                        context,
                        slidersList[index]['lottie'],
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

  Widget _buildLottieWidget(BuildContext context, dynamic lottieData) {
    // If lottie data is null or empty, return blank SizedBox
    if (lottieData == null) {
      return SizedBox(
        width: 350.rw(context),
        height: 350.rh(context),
      );
    }

    try {
      final data = lottieData as List<int>?;
      if (data == null || data.isEmpty) {
        return SizedBox(
          width: 350.rw(context),
          height: 350.rh(context),
        );
      }

      return Lottie.memory(
        width: 350.rw(context),
        height: 350.rh(context),
        fit: .contain,
        Uint8List.fromList(data),
        delegates: const LottieDelegates(values: []),
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Lottie error: $error');
          // Return blank SizedBox on error
          return SizedBox(
            width: 350.rw(context),
            height: 350.rh(context),
          );
        },
      );
    } on Exception catch (e) {
      debugPrint('Error building Lottie widget: $e');
      // Return blank SizedBox on any exception
      return SizedBox(
        width: 350.rw(context),
        height: 350.rh(context),
      );
    }
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
