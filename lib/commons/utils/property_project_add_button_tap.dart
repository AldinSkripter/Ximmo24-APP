import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/exports/main_export.dart';

Future<void> handleAddPropertyOrProjectTap(
  BuildContext context,
  PropertyAddType type,
) async {
  final isAgent = RoleScope.of(context) == ActiveRole.agent;
  final hasInternet = await HelperUtils.checkInternet();
  final user = HiveUtils.getUserDetails();
  final agent = HiveUtils.getAgentProfileData();
  final verificationStatus = isAgent
      ? user.agentVerificationStatus
      : user.userVerificationStatus;

  if (!hasInternet) {
    return HelperUtils.showSnackBarMessage(
      context,
      'noInternet',
      type: MessageType.error,
    );
  }
  await GuestChecker.check(
    onNotGuest: () async {
      unawaited(Widgets.showLoader(context));

      try {
        final bool isProfileCompleted;
        if (isAgent) {
          isProfileCompleted =
              agent != null &&
              agent.agentEmail != null &&
              (agent.agentEmail?.isNotEmpty ?? false) &&
              agent.agentMobile != null &&
              (agent.agentMobile?.isNotEmpty ?? false) &&
              agent.agentName != null &&
              (agent.agentName?.isNotEmpty ?? false) &&
              agent.agentAddress != null &&
              (agent.agentAddress?.isNotEmpty ?? false) &&
              (agent.aboutMe?.isNotEmpty ?? false) &&
              agent.aboutMe != null &&
              agent.agentProfilePhoto != null &&
              (agent.agentProfilePhoto?.isNotEmpty ?? false);
        } else {
          isProfileCompleted =
              user.email != null &&
              (user.email?.isNotEmpty ?? false) &&
              user.mobile != null &&
              (user.mobile?.isNotEmpty ?? false) &&
              user.name != null &&
              (user.name?.isNotEmpty ?? false) &&
              user.address != null &&
              (user.address?.isNotEmpty ?? false) &&
              user.profile != null &&
              (user.profile?.isNotEmpty ?? false);
        }

        if (!isProfileCompleted) {
          Widgets.hideLoder(context);
          await _showCompleteProfileDialog(
            context,
            isAgent: isAgent,
            agent: agent,
          );
        } else if ((ActiveRoleManager.isAgent
                ? AppSettings.isVerificationRequiredForAgent
                : AppSettings.isVerificationRequiredForUser) &&
            verificationStatus != 'approved') {
          Widgets.hideLoder(context);
          await _showVerificationRequiredDialog(context);
        } else {
          Widgets.hideLoder(context);
          await _navigateToAddScreen(context, type);
        }
      } on Exception catch (e) {
        Widgets.hideLoder(context);
        HelperUtils.showSnackBarMessage(
          context,
          e.toString(),
          type: MessageType.error,
        );
      }
    },
  );
}

Future<void> _showCompleteProfileDialog(
  BuildContext context, {
  required bool isAgent,
  required AgentProfileModel? agent,
}) async {
  final user = HiveUtils.getUserDetails();
  await UiUtils.showBlurredDialoge(
    context,
    dialog: BlurredDialogBox(
      title: 'completeProfile'.translate(context),
      isAcceptContainesPush: true,
      svgImagePath: AppIcons.logoutIllustration,
      onAccept: () async {
        final route = RoleScope.of(context) == ActiveRole.agent
            ? Routes.editAgentProfile
            : Routes.editProfile;
        await Navigator.popAndPushNamed(
          context,
          route,
          arguments: {'from': 'profile'},
        );
      },

      content: isAgent
          ? (agent?.agentProfilePhoto == null ||
                        (agent?.agentProfilePhoto?.isEmpty ?? true)) &&
                    (agent?.agentName?.isNotEmpty ?? false) &&
                    (agent?.agentEmail?.isNotEmpty ?? false) &&
                    (agent?.agentAddress?.isNotEmpty ?? false)
                ? CustomText(
                    'uploadProfilePicture'.translate(context),
                    textAlign: .center,
                  )
                : CustomText(
                    'completeProfileFirst'.translate(context),
                    textAlign: .center,
                  )
          : user.profile == '' &&
                (user.name != '' && user.email != '' && user.address != '')
          ? CustomText(
              'uploadProfilePicture'.translate(context),
              textAlign: .center,
            )
          : CustomText(
              'completeProfileFirst'.translate(context),
              textAlign: .center,
            ),
    ),
  );
}

Future<void> _showVerificationRequiredDialog(BuildContext context) async {
  await UiUtils.showBlurredDialoge(
    context,
    dialog: BlurredDialogBox(
      content: CustomText(
        'completeAgentVerificationToContinue'.translate(context),
      ),
      title: 'agentVerificationRequired'.translate(context),
      isAcceptContainesPush: true,
      onAccept: () async {
        await HelperUtils.goToNextPage(
          Routes.userVerificationForm,
          context,
          false,
        );
      },
    ),
  );
}

Future<void> _navigateToAddScreen(
  BuildContext context,
  PropertyAddType propertyAddType,
) async {
  if (propertyAddType == .project) {
    await context.read<ManageProjectCubit>().clear();
  }
  if (propertyAddType == .property) {
    await context.read<CreatePropertyCubit>().clear();
  }
  if (context.read<FetchCategoryCubit>().state is! FetchCategorySuccess) {
    await context.read<FetchCategoryCubit>().fetchCategories(
      loadWithoutDelay: true,
      forceRefresh: false,
    );
  }
  Widgets.hideLoder(context);

  await Navigator.pushNamed(
    context,
    Routes.selectPropertyTypeScreen,
    arguments: {'type': propertyAddType},
  );

  Widgets.hideLoder(context);
}
