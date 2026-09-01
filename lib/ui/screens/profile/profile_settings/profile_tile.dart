import 'package:ebroker/exports/main_export.dart';
import 'package:flutter/material.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    required this.title,
    required this.onTap,
    super.key,
    this.svgImagePath,
    this.isSwitchBox = false,
    this.trailing,
  });

  final String? svgImagePath;
  final String title;
  final VoidCallback onTap;
  final bool isSwitchBox;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final hasInternet = await HelperUtils.checkInternet();
        if (!hasInternet) {
          return HelperUtils.showSnackBarMessage(
            context,
            'noInternet',
            type: MessageType.error,
          );
        }
        onTap.call();
      },
      child: AbsorbPointer(
        absorbing: !isSwitchBox && trailing == null,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.rw(context),
            vertical: 11.rh(context),
          ),
          decoration: BoxDecoration(
            color: context.color.primaryColor.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              if (svgImagePath != null) ...[
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.color.tertiaryColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FittedBox(
                    fit: .none,
                    child: CustomImage(
                      imageUrl: svgImagePath!,
                      height: 24.rh(context),
                      width: 24.rw(context),
                      color: context.color.tertiaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 12.rw(context)),
              ],
              Expanded(
                child: CustomText(
                  title,
                  fontSize: context.font.sm,
                  fontWeight: .w600,
                  color: context.color.textColorDark,
                ),
              ),
              if (isSwitchBox) ...[
                const _ThemeModeSelector(),
              ] else if (trailing != null) ...[
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = context.read<AppThemeCubit>().isDarkMode;
        return UiSwitch(
          value: isDark,
          onChanged: (val) {
            final newTheme = isDark ? ThemeMode.light : ThemeMode.dark;
            unawaited(context.read<AppThemeCubit>().changeTheme(newTheme));
          },
        );
      },
    );
  }
}
