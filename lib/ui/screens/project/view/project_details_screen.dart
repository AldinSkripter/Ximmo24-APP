import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/cubits/project/change_project_status_cubit.dart';
import 'package:ebroker/data/cubits/project/delete_project_cubit.dart';
import 'package:ebroker/data/cubits/project/fetch_my_projects_cubit.dart';
import 'package:ebroker/data/cubits/property/create_advertisement_cubit.dart';
import 'package:ebroker/data/cubits/property/renew_listing_cubit.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/cubits/subscription/fetch_subscription_packages_cubit.dart';
import 'package:ebroker/data/cubits/subscription/get_subsctiption_package_limits_cubit.dart';
import 'package:ebroker/data/cubits/system/get_api_keys_cubit.dart';
import 'package:ebroker/data/helper/widgets.dart';
import 'package:ebroker/data/model/project_model.dart';
import 'package:ebroker/data/model/property_model.dart';
import 'package:ebroker/data/model/subscription_pacakage_model.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/data/repositories/project_repository.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/ui/screens/advertisement/create_advertisement_popup.dart';
import 'package:ebroker/ui/screens/project/widgets/project_helpers.dart';
import 'package:ebroker/ui/screens/proprties/widgets/agent_profile.dart';
import 'package:ebroker/ui/screens/proprties/widgets/google_map_screen.dart';
import 'package:ebroker/ui/screens/proprties/widgets/property_gallery.dart';
import 'package:ebroker/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:ebroker/ui/screens/widgets/custom_shimmer.dart';
import 'package:ebroker/ui/screens/widgets/custom_video_player.dart';
import 'package:ebroker/ui/screens/widgets/interactive_property_map.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/ui/screens/widgets/read_more_text.dart';
import 'package:ebroker/ui/screens/widgets/ui_switch.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/cloud_state/cloud_state.dart';
import 'package:ebroker/utils/constant.dart';
import 'package:ebroker/utils/custom_appbar.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:ebroker/utils/ui_utils.dart';
import 'package:ebroker/utils/whatsapp_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({
    required this.project,
    super.key,
    this.heroTag,
    this.fromAgentDetails = false,
  });

  final ProjectModel project;
  final String? heroTag;
  final bool fromAgentDetails;

  static CupertinoPageRoute<dynamic> route(RouteSettings settings) {
    final arguement = settings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => DeleteProjectCubit()),
            BlocProvider(create: (context) => RenewListingCubit()),
          ],
          child: ProjectDetailsScreen(
            project: arguement?['project'] as ProjectModel? ?? ProjectModel(),
          ),
        );
      },
    );
  }

  @override
  CloudState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends CloudState<ProjectDetailsScreen> {
  static const detailsPageSizedBoxHeight = 8.0;

  int _currentImageIndex = 0;

  final ValueNotifier<bool> _isEnabled = ValueNotifier(false);

  late ProjectModel _project;
  late final bool _isMyProject;

  late final FetchMyProjectsCubit _myProjectsCubit;
  bool _isLoading = true;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _myProjectsCubit = context.read<FetchMyProjectsCubit>();

    _isEnabled.value = _project.status.toString() == '1';
    _isMyProject = _checkIsProjectMine();
    if (widget.project.videoLink != '' && widget.project.videoLink != null) {
      setState(() {});
    }
    HelperUtils.runAfterTransition(context, () {
      if (!mounted) return;
      unawaited(_fetchDetails());
    });
  }

  Future<void> _fetchDetails() async {
    try {
      final loadedProject = await HelperUtils.loadProjectDetails(
        projectId: _project.id!,
        isMyProject: _isMyProject,
        context: context,
      );
      if (loadedProject != null) {
        if (mounted) {
          setState(() {
            _project = loadedProject;
            _isEnabled.value = _project.status.toString() == '1';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          await _onBackPress();
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        HelperUtils.showSnackBarMessage(context, e.toString(), type: .error);
      }
    }
  }

  @override
  void dispose() {
    _isEnabled.dispose();
    unawaited(_checkPackageCubit.close());

    super.dispose();
  }

  bool _checkIsProjectMine() {
    return _project.addedBy.toString() == HiveUtils.getUserId();
  }

  bool get _hasFloors => _project.plans?.isNotEmpty ?? false;
  bool get _hasDocuments => _project.documents?.isNotEmpty ?? false;

  Future<void> _onBackPress() async {
    if (!mounted) return;

    if (_isMyProject) {
      final rootContext = Constant.navigatorKey.currentContext;
      if (rootContext != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (rootContext.mounted) {
            unawaited(
              rootContext.read<FetchMyProjectsCubit>().fetchMyProjects(),
            );
          }
        });
      }
    }
  }

  Future<void> _handleStatusChange(bool newValue) async {
    final cubit = context.read<ChangeProjectStatusCubit>();
    final currentState = cubit.state;

    if (currentState is ChangeProjectStatusInProgress) return;

    final status = _isEnabled.value ? 0 : 1;
    _isEnabled.value = newValue;

    try {
      await cubit.enableProject(
        projectId: _project.id!,
        status: status,
      );

      final newState = cubit.state;
      if (newState is ChangeProjectStatusFailure) {
        _isEnabled.value = !newValue;
        final errorMessage = newState.error.contains('429')
            ? 'tooManyRequestsPleaseWait'.translate(context)
            : newState.error;

        HelperUtils.showSnackBarMessage(
          context,
          errorMessage,
          type: .error,
        );
      }
    } on Exception catch (_) {
      _isEnabled.value = !newValue;
      HelperUtils.showSnackBarMessage(
        context,
        'somethingWentWrong',
        type: .error,
      );
    }
  }

  Widget _buildEnableDisableSwitch() {
    return Container(
      height: 48.rh(context),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Row(
        children: [
          CustomText(
            'updateProjectStatus'.translate(context),
            fontSize: context.font.md,
            color: context.color.textColorDark,
            fontWeight: .w600,
          ),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: _isEnabled,
            builder: (context, value, child) {
              return UiSwitch(
                trackColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.disabled)) {
                      return context.color.textColorDark.withValues(alpha: 0.1);
                    }
                    if (states.contains(WidgetState.selected)) {
                      return context.color.tertiaryColor;
                    }
                    return Colors.grey;
                  },
                ),
                value: value,
                onChanged:
                    _project.requestStatus.toString().toLowerCase() !=
                        'approved'
                    ? null
                    : _handleStatusChange,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Container(
              width: 24.rw(context),
              height: 24.rh(context),
              alignment: Alignment.center,
              child: CustomImage(
                imageUrl: _project.category?.image ?? '',
                color: context.color.textColorDark,
              ),
            ),
            SizedBox(width: 4.rw(context)),
            Expanded(
              child: widget.heroTag != null
                  ? Hero(
                      tag: '${widget.heroTag}-category',
                      child: Material(
                        type: MaterialType.transparency,
                        child: CustomText(
                          _project.category?.translatedName ??
                              _project.category?.category ??
                              '',
                          color: context.color.textColorDark,
                          maxLines: 2,
                          fontSize: context.font.sm,
                        ),
                      ),
                    )
                  : CustomText(
                      _project.category?.translatedName ??
                          _project.category?.category ??
                          '',
                      color: context.color.textColorDark,
                      maxLines: 2,
                      fontSize: context.font.sm,
                    ),
            ),
            SizedBox(width: 4.rw(context)),
            if (widget.heroTag != null)
              Hero(
                tag: '${widget.heroTag}-type',
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    height: 36.rh(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.color.textColorDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(48),
                    ),
                    child: CustomText(
                      _project.type?.translate(context) ?? '',
                      fontWeight: .w600,
                      fontSize: context.font.sm,
                      color: context.color.textColorDark,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 36.rh(context),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.color.textColorDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(48),
                ),
                child: CustomText(
                  _project.type?.translate(context) ?? '',
                  fontWeight: .w600,
                  fontSize: context.font.sm,
                  color: context.color.textColorDark,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.rh(context)),
        if (widget.heroTag != null)
          Hero(
            tag: '${widget.heroTag}-title',
            child: Material(
              type: MaterialType.transparency,
              child: CustomText(
                _project.translatedTitle ??
                    _project.title?.firstUpperCase() ??
                    '',
                fontWeight: .w700,
                fontSize: context.font.md,
                color: context.color.textColorDark,
              ),
            ),
          )
        else
          CustomText(
            _project.translatedTitle ?? _project.title?.firstUpperCase() ?? '',
            fontWeight: .w700,
            fontSize: context.font.md,
            color: context.color.textColorDark,
          ),
        SizedBox(height: 4.rh(context)),
        CustomText(
          '${'projectId'.translate(context)}: ${_project.id ?? ''}',
          fontWeight: .w500,
          fontSize: context.font.xs,
          color: context.color.textLightColor,
        ),
      ],
    );
  }

  Widget _buildProjectDescription() {
    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          CustomText(
            'aboutThisProjectLbl'.translate(context),
            fontWeight: .w500,
            fontSize: context.font.md,
          ),
          SizedBox(height: 8.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 8.rh(context)),
          ReadMoreText(
            text:
                _project.translatedDescription ??
                _project.description?.trim() ??
                '',
            style: TextStyle(
              fontWeight: .w400,
              fontSize: context.font.xs,
              color: context.color.textColorDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    if (!_hasDocuments) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          CustomText(
            'Documents'.translate(context),
            fontWeight: .w500,
            fontSize: context.font.md,
          ),
          SizedBox(height: 8.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 8.rh(context)),
          ListView.separated(
            separatorBuilder: (context, index) => UiUtils.getDivider(context),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final document = _project.documents![index];
              return DownloadableDocument(url: document.name!);
            },
            itemCount: _project.documents!.length,
          ),
        ],
      ),
    );
  }

  Widget _buildFloorPlansSection() {
    if (!_hasFloors) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          CustomText(
            'floorPlans'.translate(context),
            fontWeight: .w500,
            fontSize: context.font.md,
          ),
          SizedBox(height: 8.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 8.rh(context)),
          ListView.separated(
            separatorBuilder: (context, index) => UiUtils.getDivider(context),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _project.plans!.length,
            itemBuilder: (context, index) {
              final floor = _project.plans![index];
              return CustomFloorPlanTile(
                title: floor.title!,
                children: [Image.network(floor.document!)],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          CustomText(
            'projectLocation'.translate(context),
            fontWeight: .w500,
            fontSize: context.font.md,
          ),
          SizedBox(height: 8.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 8.rh(context)),
          Column(
            crossAxisAlignment: .start,
            children: [
              _buildLocation(
                address: _project.location!,
              ),
              SizedBox(height: 8.rh(context)),
              _buildMapPreview(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocation({required String address}) {
    return CustomText(
      '${'addressLbl'.translate(context)}: $address',
      fontWeight: .w500,
      fontSize: context.font.sm,
      color: context.color.textColorDark.withValues(alpha: 0.89),
    );
  }

  Widget _buildMapPreview() {
    return SizedBox(
      height: 168.rh(context),
      child: InteractivePropertyMap(
        latitude: double.tryParse(_project.latitude ?? '') ?? 0,
        longitude: double.tryParse(_project.longitude ?? '') ?? 0,
        propertyType: _project.type ?? '',
        delayMs: 300,
        onFullScreenTap: _navigateToMap,
      ),
    );
  }

  Future<void> _navigateToMap() async {
    await Navigator.push(
      context,
      CupertinoPageRoute<dynamic>(
        builder: (context) => Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            iconTheme: IconThemeData(color: context.color.tertiaryColor),
            backgroundColor: Colors.transparent,
          ),
          body: GoogleMapScreen(
            latitude: double.tryParse(_project.latitude ?? '') ?? 0,
            longitude: double.tryParse(_project.longitude ?? '') ?? 0,
            propertyType: _project.type ?? '',
          ),
        ),
      ),
    );
  }

  Future<void> _handleRenewProject() async {
    if (_checkPackageCubit.state is CheckPackageInProgress) {
      return;
    }

    unawaited(Widgets.showLoader(context));
    final packageAvailable = await _checkPackageCubit.checkAvailability(
      packageType: PackageType.projectList,
    );
    Widgets.hideLoader(context);

    if (_checkPackageCubit.state is CheckPackageFail) {
      if (context.mounted) {
        HelperUtils.showSnackBarMessage(
          context,
          (_checkPackageCubit.state as CheckPackageFail).error,
          type: .error,
        );
      }
      return;
    }

    if (!packageAvailable) {
      PayAsYouGoModel? payAsYouGoPackage;
      bool? isBankTransferActive;
      var availableOnlineGateways = <String>[];

      try {
        await context.read<GetApiKeysCubit>().fetch();
        if (!mounted) return;
        final apiKeyState = context.read<GetApiKeysCubit>().state;
        if (apiKeyState is GetApiKeysSuccess) {
          isBankTransferActive = apiKeyState.bankTransferStatus == '1';
          availableOnlineGateways = apiKeyState.enabledPaymentGateways;

          await context.read<FetchSubscriptionPackagesCubit>().fetchPackages();
          if (!mounted) return;
          final packageState = context
              .read<FetchSubscriptionPackagesCubit>()
              .state;
          if (packageState is FetchSubscriptionPackagesSuccess) {
            final match = packageState.packageResponseModel.payAsYouGo
                .where((p) => p.type == 'project')
                .toList();
            if (match.isNotEmpty) payAsYouGoPackage = match.first;
          }
        }
      } on Exception catch (_) {}

      await UiUtils.showBlurredDialoge(
        context,
        dialog: BlurredSubscriptionDialogBox(
          packageType: SubscriptionPackageType.projectList,
          isAcceptContainesPush: true,
          preFetchedPayAsYouGo: payAsYouGoPackage,
          preFetchedIsBankTransferActive: isBankTransferActive,
          preFetchedAvailableOnlineGateways: availableOnlineGateways,
        ),
      );
      return;
    }

    await context.read<RenewListingCubit>().renew(
      id: _project.id!,
      type: 'project',
    );
  }

  Future<void> _handleFeaturePress() async {
    await context.read<GetSubsctiptionPackageLimitsCubit>().getLimits(
      packageType: 'project_feature',
    );

    final state = context.read<GetSubsctiptionPackageLimitsCubit>().state;

    if (state is GetSubsctiptionPackageLimitsFailure) {
      await UiUtils.showBlurredDialoge(
        context,
        dialog: const BlurredSubscriptionDialogBox(
          packageType: SubscriptionPackageType.projectFeature,
          isAcceptContainesPush: true,
        ),
      );
    } else if (state is GetSubscriptionPackageLimitsSuccess) {
      if (state.error) {
        await _showPackageLimitDialog(state.message.translate(context));
      } else {
        await _showCreateAdvertisementDialog();
      }
    }
  }

  Future<void> _showPackageLimitDialog(String message) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: message.firstUpperCase(),
        isAcceptContainesPush: true,
        onAccept: () async {
          await Navigator.popAndPushNamed(
            context,
            Routes.subscriptionPackageListRoute,
            arguments: {
              'from': 'propertyDetails',
              'isBankTransferEnabled':
                  (context.read<GetApiKeysCubit>().state as GetApiKeysSuccess)
                      .bankTransferStatus ==
                  '1',
            },
          );
        },
        content: CustomText('yourPackageLimitOver'.translate(context)),
      ),
    );
  }

  Future<void> _showCreateAdvertisementDialog() async {
    try {
      await showDialog<dynamic>(
        context: context,
        builder: (context) => CreateAdvertisementPopup(
          property: PropertyModel(),
          isProject: true,
          project: _project,
        ),
      );
    } on Exception catch (e) {
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: .error,
      );
    }
  }

  Future<void> _handleEditPress() async {
    if (AppSettings.isDemoModeOn &&
        (HiveUtils.getUserDetails().isDemoUser ?? false)) {
      HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo',
        type: .error,
      );
      return;
    }

    try {
      await Navigator.pushNamed(
        context,
        Routes.addProjectDetails,
        arguments: {
          'id': _project.id,
          'meta_title': _project.metaTitle,
          'meta_description': _project.metaDescription,
          'meta_image': _project.metaImage,
          'slug_id': _project.slugId,
          'category_id': _project.category!.id,
          'translations': _project.translations,
          'project': _project,
          'is_premium': _project.isPremium ?? false,
          'video_type': _project.videoType,
        },
      );
    } on Exception catch (_) {
      HelperUtils.showSnackBarMessage(
        context,
        'somethingWentWrong',
        type: .error,
      );
    }
  }

  Future<void> _handleDeletePress() async {
    if (AppSettings.isDemoModeOn &&
        (HiveUtils.getUserDetails().isDemoUser ?? false)) {
      HelperUtils.showSnackBarMessage(
        context,
        'thisActionNotValidDemo',
        type: .error,
      );
      return;
    }

    await UiUtils.showBlurredDialoge(
      context,
      dialog: BlurredDialogBox(
        title: 'areYouSure'.translate(context),
        svgImagePath: AppIcons.deleteIllustration,
        onAccept: () async {
          await context.read<DeleteProjectCubit>().delete(_project.id!);
        },
        content: CustomText(
          'projectWillNotRecover'.translate(context),
          textAlign: .center,
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    if (_isLoading) return const SizedBox.shrink();
    if (!_isMyProject) return const SizedBox.shrink();

    return BottomAppBar(
      padding: EdgeInsets.zero,
      color: Colors.transparent,
      elevation: 0,
      height: 72.rh(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          boxShadow: [
            BoxShadow(
              color: context.color.textColorDark.withValues(alpha: 0.12),
              offset: const Offset(0, -1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            if (!HiveUtils.isGuest() && !AppSettings.isDemoModeOn) ...[
              if ((_project.isFeatureAvailable ?? false) &&
                  !(_project.isPromoted ?? false)) ...[
                Expanded(
                  child:
                      BlocBuilder<
                        GetSubsctiptionPackageLimitsCubit,
                        GetSubscriptionPackageLimitsState
                      >(
                        builder: (context, state) {
                          return UiUtils.buildButton(
                            context,
                            height: 48.rh(context),
                            disabled: _project.status.toString() == '0',
                            onPressed: _handleFeaturePress,
                            prefixWidget: Padding(
                              padding: const EdgeInsetsDirectional.only(end: 4),
                              child: CustomImage(
                                imageUrl: AppIcons.promoted,
                                color: context.color.buttonColor,
                                width: 18.rw(context),
                                height: 18.rh(context),
                              ),
                            ),
                            fontSize: context.font.md,
                            buttonTitle: 'feature'.translate(context),
                          );
                        },
                      ),
                ),
                SizedBox(width: 16.rw(context)),
              ],
            ],
            if (_project.requestStatus != 'pending') ...[
              Expanded(
                child: UiUtils.buildButton(
                  context,
                  height: 48.rh(context),
                  onPressed: _handleEditPress,
                  fontSize: context.font.md,
                  prefixWidget: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: CustomImage(
                      imageUrl: AppIcons.edit,
                      color: context.color.buttonColor,
                      height: 18.rh(context),
                      width: 18.rw(context),
                    ),
                  ),
                  buttonTitle: 'edit'.translate(context),
                ),
              ),
              SizedBox(width: 16.rw(context)),
            ],
            Expanded(
              child: UiUtils.buildButton(
                context,
                height: 48.rh(context),
                padding: const EdgeInsets.symmetric(horizontal: 1),
                prefixWidget: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: CustomImage(
                    imageUrl: AppIcons.delete,
                    color: context.color.buttonColor,
                    width: 18.rw(context),
                    height: 18.rh(context),
                  ),
                ),
                onPressed: _handleDeletePress,
                fontSize: context.font.md,
                buttonTitle: 'deleteBtnLbl'.translate(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!mounted) return;

        Navigator.pop(context);
        await _onBackPress();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          onTapBackButton: _onBackPress,
          actions: [_appBarActions()],
        ),
        backgroundColor: context.color.primaryColor,
        bottomNavigationBar: _buildBottomNavigation(),
        body: MultiBlocListener(
          listeners: [
            BlocListener<RenewListingCubit, RenewListingState>(
              listener: (context, state) {
                if (state is RenewListingInProgress) {
                  unawaited(Widgets.showLoader(context));
                }
                if (state is RenewListingSuccess) {
                  Widgets.hideLoder(context);
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.message,
                    type: .success,
                  );
                }
                if (state is RenewListingFailure) {
                  Widgets.hideLoder(context);
                  HelperUtils.showSnackBarMessage(
                    context,
                    state.errorMessage,
                    type: .error,
                  );
                }
              },
            ),
            BlocListener<DeleteProjectCubit, DeleteProjectState>(
              listener: (context, state) async {
                if (state is DeleteProjectSuccess) {
                  HelperUtils.showSnackBarMessage(
                    context,
                    'projectDeleteSuccessfully',
                    type: .success,
                  );
                  context.read<FetchMyProjectsCubit>().delete(
                    state.id,
                  );
                  Navigator.pop(context);
                }
              },
            ),
            BlocListener<CreateAdvertisementCubit, CreateAdvertisementState>(
              listener: (context, state) async {
                if (state is! CreateAdvertisementSuccess) return;
                final id = _project.id;
                if (id == null || !mounted) return;
                try {
                  final result = await ProjectRepository()
                      .fetchProjectFromProjectId(id);
                  if (!mounted) return;
                  if (result.modelList.isNotEmpty) {
                    final updated = result.modelList.first;
                    setState(() {
                      _project = updated;
                      _isEnabled.value = updated.status.toString() == '1';
                    });
                  }
                } on Exception catch (_) {}
                unawaited(_myProjectsCubit.fetchMyProjects());
              },
            ),
          ],
          child: _isLoading
              ? _buildLoadingWithHeroImage()
              : SingleChildScrollView(
                  physics: Constant.scrollPhysics,
                  child: Column(
                    children: [
                      _buildProjectImage(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            _buildProjectHeader(),
                            SizedBox(
                              height: detailsPageSizedBoxHeight.rh(context),
                            ),
                            if (_isMyProject) ...[
                              _buildEnableDisableSwitch(),
                              SizedBox(
                                height: detailsPageSizedBoxHeight.rh(context),
                              ),
                            ],
                            _buildProjectDescription(),
                            SizedBox(
                              height: detailsPageSizedBoxHeight.rh(context),
                            ),
                            _buildAddressSection(),
                            SizedBox(
                              height: detailsPageSizedBoxHeight.rh(context),
                            ),
                            buildAgentProfileAndGallery(),
                            SizedBox(
                              height: detailsPageSizedBoxHeight.rh(context),
                            ),
                            _buildDocumentsSection(),
                            SizedBox(
                              height: detailsPageSizedBoxHeight.rh(context),
                            ),
                            _buildFloorPlansSection(),
                            SizedBox(
                              height: detailsPageSizedBoxHeight.rh(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _appBarActions() {
    if (_isMyProject) {
      return PopupMenuButton<String>(
        color: context.color.secondaryColor,
        position: PopupMenuPosition.under,
        padding: .zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: context.color.borderColor),
          borderRadius: .circular(12.rw(context)),
        ),
        menuPadding: .symmetric(
          horizontal: 12.rw(context),
          vertical: 8.rh(context),
        ),
        onSelected: (value) async {
          if (value == 'share') {
            await HelperUtils.shareProject(
              context,
              _project.slugId ?? '',
            );
          }
          if (value == 'renewListing') {
            await _handleRenewProject();
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  SizedBox(
                    height: 20.rh(context),
                    width: 20.rw(context),
                    child: CustomImage(
                      imageUrl: AppIcons.shareIcon,
                      fit: .contain,
                      color: context.color.textColorDark,
                    ),
                  ),
                  SizedBox(width: 8.rw(context)),
                  CustomText('share'.translate(context)),
                ],
              ),
            ),
            if (_project.isExpired ?? false)
              PopupMenuItem<String>(
                value: 'renewListing',
                child: Row(
                  children: [
                    SizedBox(
                      height: 20.rh(context),
                      width: 20.rw(context),
                      child: CustomImage(
                        imageUrl: AppIcons.changeStatus,
                        fit: .contain,
                        color: context.color.textColorDark,
                      ),
                    ),
                    SizedBox(width: 8.rw(context)),
                    CustomText('renewListing'.translate(context)),
                  ],
                ),
              ),
          ];
        },
        child: Container(
          margin: const EdgeInsetsDirectional.only(end: 16),
          alignment: Alignment.center,
          child: Icon(
            Icons.more_horiz_rounded,
            size: 24.rh(context),
            color: context.color.textColorDark,
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: () async {
          await HelperUtils.shareProject(
            context,
            _project.slugId ?? '',
          );
        },
        child: Container(
          margin: EdgeInsetsDirectional.only(end: 16.rw(context)),
          alignment: Alignment.center,
          child: CustomImage(
            imageUrl: AppIcons.shareIcon,
            height: 24.rh(context),
            color: context.color.textColorDark,
          ),
        ),
      );
    }
  }

  Widget buildAgentProfileAndGallery() {
    if ((_project.addedBy.toString() == HiveUtils.getUserId()) &&
        (_project.gallaryImages?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.all(8.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(4.rw(context)),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Column(
        children: [
          if (_project.addedBy.toString() != HiveUtils.getUserId()) ...[
            AgentProfileWidget(
              addedBy: _project.addedBy ?? '',
              name: _project.customer?.name ?? '',
              email: _project.customer?.email ?? '',
              profileImage: _project.customer?.profile ?? '',
              isUserVerified: _project.isUserVerified ?? false,
              isAgentVerified: _project.isAgentVerified ?? false,
              isAgent: _project.isAgent ?? false,
              propertiesCount: _project.customer?.totalProperties ?? '',
              projectsCount: _project.customer?.totalProjects ?? '',
              canScheduleAppointment: false,
              isAdmin: _project.isAdmin ?? false,
              agentProfile: _project.agentProfile,
              roleContext: _project.roleContext,
              popOnTap: widget.fromAgentDetails,
            ),
            if (WhatsappHelper.canShow(
              _project.agentProfile?.agentMobile,
              _project.agentProfile?.agentCountryCode,
            )) ...[
              SizedBox(height: 8.rh(context)),
              _buildProjectWhatsappButton(),
            ],
          ],
          if (_project.gallaryImages?.isNotEmpty ?? false) ...[
            if (_project.addedBy.toString() != HiveUtils.getUserId()) ...[
              SizedBox(height: 8.rh(context)),
              UiUtils.getDivider(context),
              SizedBox(height: 8.rh(context)),
            ],
            ProjectGallery(
              gallary: _project.gallaryImages,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectWhatsappButton() {
    return SizedBox(
      width: double.infinity,
      child: UiUtils.buildButton(
        context,
        height: 42.rh(context),
        onPressed: _onTapProjectWhatsapp,
        buttonTitle: 'whatsapp'.translate(context),
        prefixWidget: CustomImage(
          imageUrl: AppIcons.whatsapp,
          width: 18.rw(context),
          height: 18.rh(context),
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _onTapProjectWhatsapp() async {
    final mobile = _project.agentProfile?.agentMobile;
    final countryCode = _project.agentProfile?.agentCountryCode;
    if (mobile == null || countryCode == null) return;
    await WhatsappHelper.open(mobile, countryCode);
  }

  Widget _buildProjectImage() {
    final videoUrl = _project.videoLink?.trim();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    // Combine title image and gallery images (excluding videos)
    final imageUrls = <String>[
      if (_project.image != null && _project.image!.isNotEmpty) _project.image!,
      ...?_project.gallaryImages
          ?.where((element) => !element.isVideo)
          .map((e) => e.imageUrl),
    ];

    // Build carousel items: cover image first, then video (if exists),
    // then remaining images.
    final carouselItems = <Widget>[
      ...imageUrls.asMap().entries.map((entry) {
        Widget image = CustomImage(
          imageUrl: entry.value,
          width: double.infinity,
          height: 218.rs(context),
          showFullScreenImage: true,
        );
        // Wrap the first image in a Hero for shared-element transition
        if (entry.key == 0 && widget.heroTag != null) {
          image = Hero(tag: widget.heroTag!, child: image);
        }
        return image;
      }),
    ];

    // Insert video after the first image (cover image)
    if (hasVideo) {
      final videoWidget = _buildVideoThumbnailItem(videoUrl);
      if (carouselItems.isNotEmpty) {
        carouselItems.insert(1, videoWidget);
      } else {
        carouselItems.add(videoWidget);
      }
    }

    final totalItems = carouselItems.length;

    return SizedBox(
      height: 218.rs(context),
      child: Stack(
        children: [
          if (totalItems > 1)
            Stack(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    autoPlay: !hasVideo,
                    viewportFraction: 1,
                    height: 218.rs(context),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                  ),
                  items: carouselItems,
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: .center,
                    children: List.generate(totalItems, (index) {
                      // Video is at index 1 when images exist, or index 0
                      // when there are no images.
                      final videoIndex = imageUrls.isNotEmpty ? 1 : 0;
                      if (hasVideo && index == videoIndex) {
                        return Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 8.rh(context),
                            horizontal: 4.rw(context),
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 18.rw(context),
                            color: Colors.white.withValues(
                              alpha: _currentImageIndex == index ? 0.9 : 0.4,
                            ),
                          ),
                        );
                      }
                      return Container(
                        width: 8.rw(context),
                        height: 8.rh(context),
                        margin: EdgeInsets.symmetric(
                          vertical: 8.rh(context),
                          horizontal: 4.rw(context),
                        ),
                        decoration: BoxDecoration(
                          shape: .circle,
                          color: Colors.white.withValues(
                            alpha: _currentImageIndex == index ? 0.9 : 0.4,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            )
          else if (totalItems == 1)
            carouselItems.first
          else
            Container(
              alignment: Alignment.center,
              child: CustomImage(
                imageUrl: _project.image ?? '',
                width: double.infinity,
                height: 218.rs(context),
                showFullScreenImage: true,
                loadingImageHash: _project.lowQualityImage,
              ),
            ),
          if (widget.project.isPromoted ?? false)
            PositionedDirectional(
              bottom: 16.rh(context),
              start: 16.rw(context),
              child: widget.heroTag != null
                  ? Hero(
                      tag: '${widget.heroTag}-promoted',
                      child: const PromotedCard(),
                    )
                  : const PromotedCard(),
            ),
          if (widget.project.isPremium ?? false)
            PositionedDirectional(
              top: 16.rh(context),
              start: 10.rw(context),
              child: Container(
                alignment: Alignment.center,
                width: 24.rw(context),
                height: 24.rh(context),
                child: widget.heroTag != null
                    ? Hero(
                        tag: '${widget.heroTag}-premium',
                        child: CustomImage(
                          imageUrl: AppIcons.premium,
                        ),
                      )
                    : CustomImage(
                        imageUrl: AppIcons.premium,
                      ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds an inline video player widget for the carousel
  Widget _buildVideoThumbnailItem(String videoUrl) {
    return CustomVideoPlayer(
      videoUrl: videoUrl,
      autoPlay: true,
    );
  }

  Widget _buildLoadingWithHeroImage() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectImage(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProjectHeader(),
                SizedBox(height: detailsPageSizedBoxHeight.rh(context)),
                _buildLocation(address: _project.location ?? ''),
                SizedBox(height: 24.rh(context)),
                CustomShimmer(
                  width: double.infinity,
                  height: 120.rh(context),
                  borderRadius: 8,
                ),
                SizedBox(height: 16.rh(context)),
                CustomShimmer(
                  width: double.infinity,
                  height: 180.rh(context),
                  borderRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
