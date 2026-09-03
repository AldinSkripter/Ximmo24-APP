import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/profile_tile.dart';
import 'package:ebroker/ui/screens/profile/profile_settings/update_tile.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum _Visibility { all, user, agent }

class _Item {
  const _Item({
    required this.titleKey,
    required this.icon,
    required this.onTap,
    this.visibility = _Visibility.all,
  });

  final String titleKey;
  final String icon;
  final VoidCallback onTap;
  final _Visibility visibility;

  bool isVisibleFor(ActiveRole role) => switch (visibility) {
    _Visibility.all => true,
    _Visibility.user => role != ActiveRole.agent,
    _Visibility.agent => role != ActiveRole.user,
  };
}

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    required this.isGuest,
    required this.onShareApp,
    required this.onRateUs,
    required this.onDeleteAccount,
    required this.onLogout,
    super.key,
  });

  final bool isGuest;
  final VoidCallback onShareApp;
  final VoidCallback onRateUs;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogout;

  String _itemTitle(BuildContext context, String key) => switch (key) {
    'preferencesSettings' => key.translateWithFallback(
      context,
      english: 'Preferences & Settings',
      german: 'Einstellungen',
    ),
    'privacyOtherInfo' => key.translateWithFallback(
      context,
      english: 'Privacy & Information',
      german: 'Datenschutz & Informationen',
    ),
    _ => key.translate(context),
  };

  List<_Item> _buildItems(BuildContext context) => [
    _Item(
      titleKey: 'favorites',
      icon: AppIcons.heartFilled,
      visibility: _Visibility.user,
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(context, Routes.favoritesScreen);
          },
        );
      },
    ),

    if (!isGuest)
      _Item(
        titleKey: 'watermarkSettings',
        icon: AppIcons.watermark,
        visibility: _Visibility.agent,
        onTap: () async {
          await Navigator.pushNamed(context, Routes.watermarkSettings);
        },
      ),
    _Item(
      titleKey: 'myStories',
      icon: AppIcons.gallery,
      visibility: _Visibility.agent,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.myStories);
      },
    ),
    _Item(
      titleKey: 'myAds',
      icon: AppIcons.promoted,
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(context, Routes.myAdvertisment);
          },
        );
      },
    ),
    _Item(
      titleKey: 'myAppointments',
      icon: AppIcons.appointment,
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(context, Routes.myAppointmentsScreen);
          },
        );
      },
    ),
    _Item(
      titleKey: 'configurations',
      icon: AppIcons.configuration,
      visibility: _Visibility.agent,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.appointmentConfiguration);
      },
    ),
    _Item(
      titleKey: 'subscription',
      icon: AppIcons.subscription,
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(
              context,
              Routes.subscriptionPackageListRoute,
            );
          },
        );
      },
    ),

    _Item(
      titleKey: 'areaConvertor',
      visibility: _Visibility.user,
      icon: AppIcons.areaConvertor,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.areaConvertorScreen);
      },
    ),

    _Item(
      titleKey: 'shareApp',
      icon: AppIcons.shareApp,
      onTap: onShareApp,
    ),
    _Item(
      titleKey: 'rateUs',
      icon: AppIcons.rateUs,
      onTap: onRateUs,
    ),
    _Item(
      titleKey: 'preferencesSettings',
      icon: AppIcons.configuration,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.preferencesSettings);
      },
    ),
    _Item(
      titleKey: 'privacyOtherInfo',
      icon: AppIcons.info,
      onTap: () async {
        await Navigator.pushNamed(context, Routes.privacyOtherInfo);
      },
    ),
    if (!isGuest)
      _Item(
        titleKey: 'logout',
        visibility: .user,
        icon: AppIcons.logout,
        onTap: onLogout,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final role = RoleScope.of(context);
    final items = _buildItems(
      context,
    ).where((item) => item.isVisibleFor(role)).toList();
    final featuredCount = items.length < 4 ? items.length : 4;
    final featured = items.take(featuredCount).toList();
    final remaining = items.skip(featuredCount).toList();

    return Column(
      children: [
        if (featured.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: featured.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.rw(context),
              mainAxisSpacing: 12.rh(context),
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, index) => _PremiumActionCard(
              item: featured[index],
              index: index,
              title: _itemTitle(context, featured[index].titleKey),
            ),
          ),
        if (remaining.isNotEmpty) ...[
          SizedBox(height: 16.rh(context)),
          Container(
            padding: EdgeInsets.all(10.rw(context)),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(24.rw(context)),
              border: Border.all(
                color: context.color.tertiaryColor.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.055),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < remaining.length; i++) ...[
                  if (i > 0) SizedBox(height: 6.rh(context)),
                  ProfileTile(
                    title: _itemTitle(context, remaining[i].titleKey),
                    svgImagePath: remaining[i].icon,
                    onTap: remaining[i].onTap,
                    trailing: _buildTrailing(context, remaining[i]),
                  ),
                ],
                if (Constant.isUpdateAvailable) ...[
                  SizedBox(height: 6.rh(context)),
                  UpdateTile(
                    title: 'update'.translate(context),
                    newVersion: Constant.newVersionNumber,
                    isUpdateAvailable: Constant.isUpdateAvailable,
                    svgImagePath: AppIcons.update,
                    onTap: () async {
                      if (Platform.isIOS) {
                        await launchUrl(Uri.parse(AppSettings.appstoreURLios));
                      } else if (Platform.isAndroid) {
                        await launchUrl(
                          Uri.parse(AppSettings.playstoreURLAndroid),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(BuildContext context, _Item item) {
    if (item.titleKey == 'preferencesSettings') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 9.rw(context),
              vertical: 4.rh(context),
            ),
            decoration: BoxDecoration(
              color: context.color.tertiaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(99),
            ),
            child: CustomText(
              (context.watch<LanguageCubit>().state as LanguageLoader)
                  .languageCode
                  .toString()
                  .toUpperCase(),
              color: context.color.tertiaryColor,
              fontSize: context.font.xs,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 8.rw(context)),
          _arrow(context),
        ],
      );
    }
    return _arrow(context);
  }

  Widget _arrow(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: 13,
      color: context.color.textLightColor,
    );
  }
}

class _PremiumActionCard extends StatelessWidget {
  const _PremiumActionCard({
    required this.item,
    required this.index,
    required this.title,
  });

  final _Item item;
  final int index;
  final String title;

  @override
  Widget build(BuildContext context) {
    final accent = context.color.tertiaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22.rw(context)),
        onTap: () async {
          final hasInternet = await HelperUtils.checkInternet();
          if (!hasInternet) {
            return HelperUtils.showSnackBarMessage(
              context,
              'noInternet',
              type: MessageType.error,
            );
          }
          item.onTap();
        },
        child: Ink(
          padding: EdgeInsets.all(15.rw(context)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                context.color.secondaryColor,
                accent.withValues(alpha: index.isEven ? 0.12 : 0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(22.rw(context)),
            border: Border.all(color: accent.withValues(alpha: 0.13)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44.rw(context),
                height: 44.rh(context),
                padding: EdgeInsets.all(10.rw(context)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.72)],
                  ),
                  borderRadius: BorderRadius.circular(15.rw(context)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CustomImage(
                  imageUrl: item.icon,
                  color: context.color.buttonColor,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 11.rw(context)),
              Expanded(
                child: CustomText(
                  title,
                  maxLines: 2,
                  fontSize: context.font.sm,
                  fontWeight: FontWeight.w700,
                  color: context.color.textColorDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
