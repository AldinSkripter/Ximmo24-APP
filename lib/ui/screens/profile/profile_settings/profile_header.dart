import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/stories/widgets/story_ring_avatar.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.isGuest, super.key});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserDetailsCubit>().state.user;
    final role = RoleScope.of(context);
    final isAgent = role == ActiveRole.agent;
    final agentState = context.watch<AgentProfileCubit>().state;
    final agentProfile = agentState is AgentProfileSuccess
        ? agentState.agentProfile
        : null;

    final displayName = isAgent
        ? (agentProfile?.agentName?.isEmpty == false
              ? agentProfile?.agentName
              : null)
        : user?.name;
    final displayEmail = isAgent
        ? (agentProfile?.agentEmail?.isEmpty == false
              ? agentProfile?.agentEmail
              : null)
        : user?.email;
    final displayProfile = isAgent
        ? agentProfile?.agentProfilePhoto
        : user?.profile;

    final username = isGuest
        ? 'anonymous'.translate(context)
        : displayName?.firstUpperCase() ?? '';
    final email = isGuest
        ? 'notLoggedIn'.translate(context)
        : displayEmail ?? '';

    return Container(
      padding: .all(16.rw(context)),
      margin: .symmetric(horizontal: 16.rw(context)),
      decoration: BoxDecoration(
        border: Border.all(
          color: isGuest
              ? Colors.white.withValues(alpha: 0.82)
              : context.color.tertiaryColor.withValues(alpha: 0.12),
        ),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            context.color.secondaryColor.withValues(alpha: isGuest ? 0.97 : 1),
            isGuest
                ? context.color.secondaryColor.withValues(alpha: 0.88)
                : context.color.tertiaryColor.withValues(alpha: 0.055),
          ],
        ),
        borderRadius: BorderRadius.circular(24.rw(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isGuest ? 0.13 : 0.10),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isAgent && !isGuest)
            StoryRingAvatar(
              agentId: int.tryParse(HiveUtils.getUserId() ?? ''),
              borderRadius: 8.rw(context),
              showAddButton: true,
              onAddTap: () async {
                await Navigator.pushNamed(
                  context,
                  Routes.selectStoryListing,
                );
              },
              child: _profileImgWidget(
                context,
                (displayProfile ?? '').trim(),
                isAgent,
              ),
            )
          else
            _profileImgWidget(
              context,
              (displayProfile ?? '').trim(),
              isAgent,
            ),
          SizedBox(width: 14.rw(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  mainAxisAlignment: .spaceBetween,
                  spacing: 4.rw(context),
                  children: [
                    Expanded(
                      child: CustomText(
                        username,
                        color: context.color.inverseSurface,
                        fontSize: context.font.lg,
                        fontWeight: .w700,
                        maxLines: 2,
                      ),
                    ),
                    _buildEditOrLogin(context),
                  ],
                ),

                CustomText(
                  email,
                  color: context.color.textLightColor,
                  fontSize: context.font.xs,
                  maxLines: 1,
                ),
                if (!isGuest) _verifiedBadge(context, isAgent: isAgent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifiedBadge(BuildContext context, {required bool isAgent}) {
    final user = context.watch<UserDetailsCubit>().state.user;
    final isVerified = isAgent
        ? (user?.isAgentVerified ?? HiveUtils.isAgentVerified())
        : (user?.isUserVerified ?? HiveUtils.isUserVerified());

    if (!isVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.rw(context),
        vertical: 4.rh(context),
      ),
      margin: .only(top: 6.rh(context)),
      decoration: BoxDecoration(
        color: context.color.tertiaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImage(
            imageUrl: isAgent ? AppIcons.agentBadge : AppIcons.userBadge,
            color: context.color.tertiaryColor,
            height: 12.rh(context),
            width: 12.rw(context),
          ),
          SizedBox(width: 4.rw(context)),
          CustomText(
            'verified'.translate(context),
            color: context.color.tertiaryColor,
            fontSize: context.font.xxs,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Widget _buildEditOrLogin(BuildContext context) {
    return isGuest
        ? Container(
            child: UiUtils.buildButton(
              context,
              height: 32.rh(context),
              fontSize: context.font.xs,
              showElevation: false,
              buttonTitle: 'login'.translate(context),
              buttonColor: context.color.tertiaryColor,
              textColor: context.color.buttonColor,
              autoWidth: true,
              border: BorderSide(
                color: context.color.tertiaryColor.withValues(alpha: 0.85),
              ),
              onPressed: () async {
                await Navigator.pushReplacementNamed(
                  context,
                  Routes.login,
                );
              },
            ),
          )
        : GestureDetector(
            onTap: () async {
              final route = RoleScope.of(context) == ActiveRole.agent
                  ? Routes.editAgentProfile
                  : Routes.editProfile;
              await HelperUtils.goToNextPage(
                route,
                context,
                false,
                args: {'from': 'profile'},
              );
            },
            child: Container(
              padding: .all(8.rw(context)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.color.tertiaryColor.withValues(alpha: 0.10),
              ),
              child: Center(
                child: CustomImage(
                  imageUrl: AppIcons.edit,
                  color: context.color.tertiaryColor,
                  fit: .contain,
                  height: 18.rh(context),
                ),
              ),
            ),
          );
  }

  Widget _profileImgWidget(
    BuildContext context,
    String profileUrl,
    bool isAgent,
  ) {
    final radius = BorderRadius.circular(isAgent ? 18.rw(context) : 999);
    final useGuestStyle = isGuest && profileUrl.isEmpty;
    return Container(
      padding: EdgeInsets.all(3.rw(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            useGuestStyle ? Colors.white : context.color.tertiaryColor,
            useGuestStyle
                ? Colors.white.withValues(alpha: 0.72)
                : context.color.tertiaryColor.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: (useGuestStyle
                    ? Colors.black
                    : context.color.tertiaryColor)
                .withValues(alpha: useGuestStyle ? 0.14 : 0.22),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isAgent ? 15.rw(context) : 999),
        child: profileUrl.isEmpty
            ? _buildDefaultPersonSVG(context, isAgent)
            : CustomImage(
                imageUrl: profileUrl,
                width: 78.rw(context),
                height: 78.rh(context),
              ),
      ),
    );
  }

  Widget _buildDefaultPersonSVG(BuildContext context, bool isAgent) {
    return Container(
      width: 78.rw(context),
      height: 78.rh(context),
      decoration: BoxDecoration(
        shape: isAgent ? .rectangle : .circle,
        borderRadius: isAgent ? .all(.circular(15.rw(context))) : null,
        color: isGuest
            ? context.color.secondaryColor
            : context.color.tertiaryColor.withValues(alpha: 0.1),
      ),
      child: FittedBox(
        fit: .none,
        child: CustomImage(
          imageUrl: AppIcons.defaultPersonLogo,
          color: isGuest
              ? context.color.textColorDark.withValues(alpha: 0.72)
              : context.color.tertiaryColor,
          width: 32.rw(context),
          height: 32.rh(context),
        ),
      ),
    );
  }
}
