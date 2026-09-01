import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/data/cubits/auth/get_user_data_cubit.dart';
import 'package:ebroker/data/model/system_settings_model.dart';
import 'package:ebroker/data/repositories/system_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/hive_keys.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AuthenticationState authenticationState;

  bool isSettingsLoaded = false;
  bool isLanguageLoaded = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    unawaited(connectivityCheck());
    unawaited(
      getDefaultLanguage(
        onSuccess: () {
          if (mounted) {
            setState(() {
              isLanguageLoaded = true;
            });
            _tryNavigate();
          }
        },
        context: context,
      ),
    );

    unawaited(checkIsUserAuthenticated());

    unawaited(MobileAds.instance.initialize());
  }

  Future<void> connectivityCheck() async {
    await Connectivity().checkConnectivity().then((value) async {
      if (!mounted) return;
      if (value.contains(ConnectivityResult.none)) {
        await Navigator.pushReplacement(
          context,
          CupertinoPageRoute<dynamic>(
            builder: (context) {
              return NoInternet(
                onRetry: () async {
                  try {
                    await LoadAppSettings().load(initBox: true);

                    // Check internet connectivity before redirecting
                    final connectivityResult = await Connectivity()
                        .checkConnectivity();
                    if (!connectivityResult.contains(ConnectivityResult.none)) {
                      // Only redirect to splash screen if internet is available
                      if (context.mounted) {
                        await Navigator.pushReplacementNamed(
                          context,
                          Routes.splash,
                        );
                      }
                    } else {
                      HelperUtils.showSnackBarMessage(
                        context,
                        'noInternetErrorMsg',
                        type: .error,
                      );
                    }
                  } on Exception catch (_) {}
                },
              );
            },
          ),
        );
      }
    });
  }

  Future<void> checkIsUserAuthenticated() async {
    authenticationState = context.read<AuthenticationCubit>().state;
    if (!mounted) return;
    if (authenticationState == AuthenticationState.authenticated) {
      ///Only load sensitive details if user is authenticated
      ///This call will load sensitive details with settings
      await context.read<FetchSystemSettingsCubit>().fetchSettings(
        isAnonymous: false,
      );
      // Force a fresh user/agent profile fetch on every app launch so an
      // in-place Play Store update overwrites stale cached Hive data
      // (missing fields added in newer app versions) instead of leaving
      // it stale until the user visits Profile or reinstalls. Fire and
      // forget: navigation must not wait on this, cubits update reactively.
      unawaited(refreshCachedUserData());
    } else {
      //This call will hide sensitive details.
      await context.read<FetchSystemSettingsCubit>().fetchSettings(
        isAnonymous: true,
      );
    }
  }

  Future<void> refreshCachedUserData() async {
    if (!mounted || HiveUtils.isGuest()) return;
    try {
      await context.read<GetUserDataCubit>().getUserData();
      ActiveRoleManager.syncFromHive();
      if (!mounted) return;
      await context.read<AgentProfileCubit>().fetchAgentProfile();
    } on Exception catch (e) {
      log('Error while refreshing cached user data: $e');
    }
  }

  void _tryNavigate() {
    if (_navigated) return;
    if (!isSettingsLoaded || !isLanguageLoaded) return;
    _navigated = true;
    unawaited(navigateCheck());
  }

  Future<void> navigateCheck() async {
    ({
      'isSettingsLoaded': isSettingsLoaded,
      'isLanguageLoaded': isLanguageLoaded,
    }).logg;

    if (isSettingsLoaded && isLanguageLoaded) {
      await validateCurrentLanguage();
    }
  }

  Future<void> validateCurrentLanguage() async {
    final currentLanguageCode = HiveUtils.getLanguageCode();

    // Check if current language exists in AppSettings.languages
    final isCurrentLanguageAvailable = AppSettings.languages.any(
      (language) => language.code == currentLanguageCode,
    );

    if (!isCurrentLanguageAvailable && AppSettings.languages.isNotEmpty) {
      // Current language not available, switch to first language
      final firstLanguage = AppSettings.languages.first;

      // Load the first available language
      await context
          .read<FetchLanguageCubit>()
          .getLanguage(firstLanguage.code!)
          .then((_) async {
            if (!mounted) return;
            final state = context.read<FetchLanguageCubit>().state;
            if (state is FetchLanguageSuccess) {
              final map = state.toMap();
              final data = map['file_name'];
              map['data'] = data;
              map.remove('file_name');

              await HiveUtils.storeLanguage(map).then((_) {
                context.read<LanguageCubit>().emitLanguageLoader(
                  code: state.code,
                  isRtl: state.isRTL,
                );
                navigateToScreen();
              });
            } else {
              // If language loading fails, proceed with navigation
              navigateToScreen();
            }
          })
          .catchError((dynamic error) {
            // Proceed with navigation even if language loading fails
            navigateToScreen();
          });
    } else {
      // Current language is valid or no languages available, proceed normally
      navigateToScreen();
    }
  }

  void navigateToScreen() {
    if (!mounted) return;
    if (context.read<FetchSystemSettingsCubit>().getSetting(
          SystemSetting.maintenanceMode,
        ) ==
        '1') {
      Future.delayed(Duration.zero, () async {
        await Navigator.of(
          context,
        ).pushReplacementNamed(Routes.maintenanceMode);
      });
    } else if (authenticationState == AuthenticationState.authenticated) {
      Future.delayed(Duration.zero, () async {
        await Navigator.of(
          context,
        ).pushReplacementNamed(Routes.main, arguments: {'from': 'main'});
      });
    } else if (authenticationState == AuthenticationState.unAuthenticated) {
      if (Hive.box<dynamic>(HiveKeys.userDetailsBox).get('isGuest') == true) {
        Future.delayed(Duration.zero, () async {
          await Navigator.of(
            context,
          ).pushReplacementNamed(Routes.main, arguments: {'from': 'splash'});
        });
      } else {
        Future.delayed(Duration.zero, () async {
          await Navigator.of(context).pushReplacementNamed(Routes.login);
        });
      }
    } else if (authenticationState == AuthenticationState.firstTime) {
      Future.delayed(Duration.zero, () async {
        await Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FetchSystemSettingsCubit, FetchSystemSettingsState>(
      listener: (context, state) {
        if (state is FetchSystemSettingsFailure) {
          log(state.errorMessage, name: 'FetchSystemSettings ERROR');
        }
        if (state is FetchSystemSettingsSuccess) {
          final setting = <dynamic>[];
          if (setting.isNotEmpty) {
            if ((setting[0] as Map).containsKey('package_id')) {
              Constant.subscriptionPackageId = '';
            }
          }

          isSettingsLoaded = true;
          _tryNavigate();
        }
      },
      builder: (context, state) {
        if (state is FetchSystemSettingsFailure) {
          return Scaffold(
            backgroundColor: context.color.secondaryColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    CustomImage(
                      imageUrl: AppIcons.somethingWentWrong,
                      height: 300.rs(context),
                    ),
                    SizedBox(height: 24.rh(context)),
                    CustomText(
                      'defaultErrorMsg'.translate(context),
                      textAlign: .center,
                      fontSize: context.font.lg,
                      color: context.color.textColorDark,
                    ),
                    SizedBox(height: 24.rh(context)),
                    UiUtils.buildButton(
                      context,
                      onPressed: () async {
                        await context
                            .read<FetchSystemSettingsCubit>()
                            .fetchSettings(
                              isAnonymous: true,
                            );
                      },
                      showElevation: false,
                      buttonTitle: 'retry'.translate(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final splashBackground = context.color.tertiaryColor;
        final isLightBackground = splashBackground.computeLuminance() > 0.45;
        final splashLogo = isLightBackground
            ? AppIcons.splashLogoLight
            : AppIcons.splashLogoDark;
        final splashLogoWidth = (MediaQuery.sizeOf(context).width * 0.78)
            .clamp(240.0, 360.0)
            .toDouble();

        return AnnotatedRegion(
          value: SystemUiOverlayStyle(
            statusBarColor: splashBackground,
            statusBarIconBrightness: isLightBackground
                ? Brightness.dark
                : Brightness.light,
            statusBarBrightness: isLightBackground
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarColor: splashBackground,
            systemNavigationBarIconBrightness: isLightBackground
                ? Brightness.dark
                : Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: splashBackground,
            extendBody: true,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomImage(
                  key: const ValueKey('ximmo24-splash-logo'),
                  imageUrl: splashLogo,
                  width: splashLogoWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<dynamic> getDefaultLanguage({
  required VoidCallback onSuccess,
  required BuildContext context,
}) async {
  try {
    await Hive.openBox<dynamic>(HiveKeys.languageBox);
    await Hive.openBox<dynamic>(HiveKeys.userDetailsBox);
    await Hive.openBox<dynamic>(HiveKeys.authBox);

    final cachedLanguage = HiveUtils.getLanguage();
    String code;

    if (cachedLanguage != null && cachedLanguage['data'] != null) {
      code = HiveUtils.getLanguageCode();
    } else {
      final result = await SystemRepository().fetchSystemSettings(
        isAnonymouse: true,
      );
      code = result['data']?['default_language']?.toString() ?? 'en';
    }

    if (!context.mounted) return;

    try {
      await context.read<FetchLanguageCubit>().getLanguage(code);
      if (context.mounted) {
        final state = context.read<FetchLanguageCubit>().state;

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
        } else {
          if (cachedLanguage != null && cachedLanguage['data'] != null) {
            context.read<LanguageCubit>().loadCurrentLanguage();
          }
        }
      }
    } on Exception catch (e) {
      log('Error while fetching language from API: $e');
      if (cachedLanguage != null &&
          cachedLanguage['data'] != null &&
          context.mounted) {
        context.read<LanguageCubit>().loadCurrentLanguage();
      }
    }

    onSuccess.call();
  } on Exception catch (e, st) {
    log('Error while load default language $e\n$st');
    // Fallback: proceed with default template language to avoid blocking splash
    onSuccess.call();
  }
}
