import 'package:ebroker/data/cubits/agents/agent_profile_cubit.dart';
import 'package:ebroker/data/cubits/agents/update_agent_profile_cubit.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/data/repositories/auth_repository.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/image_cropper.dart';
import 'package:ebroker/ui/screens/widgets/phone_field.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

class EditAgentProfileScreen extends StatefulWidget {
  const EditAgentProfileScreen({super.key});

  static Route<dynamic> route(RouteSettings routeSettings) {
    return CupertinoPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => UpdateAgentProfileCubit()),
        ],
        child: const EditAgentProfileScreen(),
      ),
    );
  }

  @override
  State<EditAgentProfileScreen> createState() => _EditAgentProfileScreenState();
}

class _EditAgentProfileScreenState extends State<EditAgentProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();

  File? _profilePhoto;
  File? _agentBanner;
  String? _currentProfileUrl;
  String? _currentBannerUrl;
  String? selectedCountryCode = HiveUtils.getUserDetails().countryCode ?? '';

  @override
  void initState() {
    super.initState();
    unawaited(context.read<AgentProfileCubit>().fetchAgentProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _aboutMeController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _youtubeController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  void _populateFields(AgentProfileModel profile) {
    _nameController.text = profile.agentName ?? '';
    _emailController.text = profile.agentEmail ?? '';
    _mobileController.text = profile.agentMobile ?? '';
    _addressController.text = profile.agentAddress ?? '';
    _aboutMeController.text = profile.aboutMe ?? '';
    _facebookController.text = profile.facebookId ?? '';
    _twitterController.text = profile.twitterId ?? '';
    _youtubeController.text = profile.youtubeId ?? '';
    _instagramController.text = profile.instagramId ?? '';
    _linkedinController.text = profile.linkedinId ?? '';
    _currentProfileUrl = profile.agentProfilePhoto;
    _currentBannerUrl = profile.agentBanner;
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final checkInternet = await HelperUtils.checkInternet();
    if (!checkInternet) {
      HelperUtils.showSnackBarMessage(context, 'lblchecknetwork', type: .error);
      return;
    }
    if (selectedCountryCode == null || selectedCountryCode == '') {
      HelperUtils.showSnackBarMessage(
        context,
        'pleaseSelectCountry'.translate(context),
        type: .error,
      );
      return;
    }
    await context.read<UpdateAgentProfileCubit>().updateProfile(
      agentName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      countryCode: selectedCountryCode,
      address: _addressController.text.trim(),
      aboutMe: _aboutMeController.text.trim(),
      facebookId: _facebookController.text.trim(),
      twitterId: _twitterController.text.trim(),
      youtubeId: _youtubeController.text.trim(),
      instagramId: _instagramController.text.trim(),
      linkedinId: _linkedinController.text.trim(),
      profilePhoto: _profilePhoto,
      agentBanner: _agentBanner,
    );
  }

  Future<void> _showPicker({required bool isBanner}) async {
    final currentFile = isBanner ? _agentBanner : _profilePhoto;
    await CustomBottomSheet.show<void>(
      context: context,
      showDragHandle: false,
      borderRadius: 18,
      padding: .all(16.rw(context)),
      child: Column(
        mainAxisSize: .min,
        spacing: 8.rh(context),
        children: [
          _customTile(
            AppIcons.gallery,
            'gallery'.translate(context),
            () async {
              await _pickImage(ImageSource.gallery, isBanner: isBanner);
              Navigator.of(context).pop();
            },
          ),
          _customTile(
            AppIcons.eye,
            'camera'.translate(context),
            () async {
              await _pickImage(ImageSource.camera, isBanner: isBanner);
              Navigator.of(context).pop();
            },
          ),
          if (currentFile != null)
            _customTile(
              AppIcons.closeCircle,
              'lblremove'.translate(context),
              () {
                if (isBanner) {
                  _agentBanner = null;
                } else {
                  _profilePhoto = null;
                }
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _customTile(
    String icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 32.rh(context),
        child: Row(
          spacing: 8.rw(context),
          children: [
            CustomImage(
              imageUrl: icon,
              fit: .contain,
              height: 24,
              color: context.color.textColorDark,
            ),
            CustomText(
              title,
              color: context.color.textColorDark,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(
    ImageSource imageSource, {
    required bool isBanner,
  }) async {
    CropImage.context = context;
    final pickedFile = await ImagePicker().pickImage(source: imageSource);
    File? result;
    if (pickedFile != null) {
      final croppedFile = await CropImage.crop(
        filePath: pickedFile.path,
        aspectRatio: isBanner
            ? const CropAspectRatio(ratioX: 78, ratioY: 43)
            : const CropAspectRatio(ratioX: 1, ratioY: 1),
        lockAspectRatio: !isBanner,
      );
      if (croppedFile != null) {
        result = File(croppedFile.path);
      }
    }
    if (isBanner) {
      _agentBanner = result;
    } else {
      _profilePhoto = result;
    }
    setState(() {});
  }


  Widget _getProfileImage() {
    if (_profilePhoto != null) {
      return Image.file(_profilePhoto!, fit: .contain);
    }
    if ((_currentProfileUrl ?? '').isNotEmpty) {
      return CustomImage(imageUrl: _currentProfileUrl!);
    }
    return CustomImage(
      imageUrl: AppIcons.defaultPersonLogo,
      color: context.color.tertiaryColor,
    );
  }

  Widget _buildProfileHeader() {
    final headerHeight = 170.rh(context) + 62.rw(context);
    return SizedBox(
      height: headerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 170.rh(context),
            child: GestureDetector(
              onTap: () => unawaited(_showPicker(isBanner: true)),
              child: Container(
                decoration: BoxDecoration(
                  color: context.color.tertiaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.rw(context)),
                  border: Border.all(
                    color: context.color.borderColor,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _getBannerImage(),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 12.rh(context),
            end: 12.rw(context),
            child: GestureDetector(
              onTap: () => unawaited(_showPicker(isBanner: true)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.rw(context),
                  vertical: 6.rh(context),
                ),
                decoration: BoxDecoration(
                  color: context.color.inverseSurface,
                  borderRadius: BorderRadius.circular(18.rw(context)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomImage(
                      imageUrl: AppIcons.edit,
                      height: 16.rh(context),
                      fit: .contain,
                      color: context.color.secondaryColor,
                    ),
                    SizedBox(width: 4.rw(context)),
                    CustomText(
                      'edit'.translate(context),
                      fontSize: context.font.xs,
                      color: context.color.secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 170.rh(context) - 62.rw(context),
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 124.rh(context),
                    width: 124.rw(context),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.color.borderColor,
                        width: 2,
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: _getProfileImage(),
                    ),
                  ),
                  Positioned(
                    bottom: -12.rh(context),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => unawaited(_showPicker(isBanner: false)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.rw(context),
                            vertical: 6.rh(context),
                          ),
                          decoration: BoxDecoration(
                            color: context.color.primaryColor,
                            borderRadius: BorderRadius.circular(18.rw(context)),
                            border: Border.all(
                              color: context.color.tertiaryColor,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomImage(
                                imageUrl: AppIcons.edit,
                                height: 16.rh(context),
                                fit: .contain,
                                color: context.color.tertiaryColor,
                              ),
                              SizedBox(width: 4.rw(context)),
                              CustomText(
                                'edit'.translate(context),
                                fontSize: context.font.xs,
                                color: context.color.tertiaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getBannerImage() {
    if (_agentBanner != null) {
      return Image.file(_agentBanner!, fit: BoxFit.cover);
    }
    if ((_currentBannerUrl ?? '').isNotEmpty) {
      return CustomImage(imageUrl: _currentBannerUrl ?? '');
    }
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: context.color.tertiaryColor,
        size: 40.rh(context),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    CustomTextFieldValidator? validator,
    bool? readOnly,
    int? maxLine,
    TextInputType? keyboard,
    Widget? prefix,
    Widget? suffix,
    List<TextInputFormatter>? formatters,
    TextDirection? textDirection,
    dynamic Function(dynamic value)? onChange,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        SizedBox(height: 8.rh(context)),
        CustomText(
          title.translate(context),
          fontSize: context.font.sm,
          fontWeight: .w600,
        ),
        SizedBox(height: 8.rh(context)),
        CustomTextFormField(
          maxLength: maxLength,
          textDirection: textDirection,
          controller: controller,
          isReadOnly: readOnly,
          validator: validator,
          maxLine: maxLine,
          keyboard: keyboard,
          fillColor: context.color.secondaryColor,
          onChange: onChange,
          prefix: prefix,
          suffix: suffix,
          formaters: formatters,
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      itemBuilder: (context, index) => index == 0
          ? Shimmer.fromColors(
              period: const Duration(milliseconds: 1000),
              baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
              highlightColor: Theme.of(
                context,
              ).colorScheme.shimmerHighlightColor,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.shimmerContentColor,
                  shape: .circle,
                ),
              ),
            )
          : CustomShimmer(height: 50.rh(context)),
      separatorBuilder: (context, index) =>
          SizedBox(height: index == 0 ? 24 : 16),
      itemCount: 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmailLogin =
        HiveUtils.getUserLoginType() == LoginType.google ||
        HiveUtils.getUserLoginType() == LoginType.apple ||
        HiveUtils.getUserLoginType() == LoginType.email;
    final isPhoneLogin = HiveUtils.getUserLoginType() == LoginType.phone;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(title: 'editProfile'.translate(context)),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: BlocConsumer<AgentProfileCubit, AgentProfileState>(
            listener: (context, state) {
              if (state is AgentProfileSuccess) {
                _populateFields(state.agentProfile);
              }
            },
            builder: (context, state) {
              if (state is AgentProfileInProgress) return _buildShimmer();
              if (state is AgentProfileFailure) {
                return SomethingWentWrong(
                  errorMessage: state.errorMessage,
                );
              }
              return BlocConsumer<
                UpdateAgentProfileCubit,
                UpdateAgentProfileState
              >(
                listener: (context, state) {
                  if (state is UpdateAgentProfileSuccess) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      'profileupdated',
                      type: .success,
                    );
                    unawaited(
                      context.read<AgentProfileCubit>().fetchAgentProfile(),
                    );
                    Navigator.pop(context);
                  } else if (state is UpdateAgentProfileFailure) {
                    HelperUtils.showSnackBarMessage(
                      context,
                      state.errorMessage,
                      type: .error,
                    );
                  }
                },
                builder: (context, updateState) {
                  return SingleChildScrollView(
                    physics: Constant.scrollPhysics,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          _buildProfileHeader(),
                          SizedBox(height: 8.rh(context)),
                          _buildTextField(
                            context,
                            title: 'fullName',
                            controller: _nameController,
                            validator: CustomTextFieldValidator.nullCheck,
                          ),
                          _buildTextField(
                            context,
                            title: 'email',
                            controller: _emailController,
                            readOnly: isEmailLogin,
                            validator: CustomTextFieldValidator.email,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 8.rh(context)),
                            child: Column(
                              crossAxisAlignment: .start,
                              children: [
                                CustomText(
                                  'mobile'.translate(context),
                                  fontSize: context.font.sm,
                                  fontWeight: .w600,
                                ),
                                SizedBox(height: 8.rh(context)),
                                PhoneField(
                                  controller: _mobileController,
                                  enabled: !isPhoneLogin,
                                  initialCountryCode: selectedCountryCode,
                                  validator: AppSettings.isDemoModeOn
                                      ? CustomTextFieldValidator.nullCheck
                                      : CustomTextFieldValidator.phoneNumber,
                                  onCountryChanged: (value) {
                                    setState(() {
                                      selectedCountryCode = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          _buildTextField(
                            context,
                            title: 'addressLbl',
                            controller: _addressController,
                            validator: CustomTextFieldValidator.nullCheck,
                          ),
                          _buildTextField(
                            context,
                            title: 'aboutMe',
                            controller: _aboutMeController,
                            validator: CustomTextFieldValidator.nullCheck,
                            maxLine: 4,
                            keyboard: TextInputType.multiline,
                          ),
                          SizedBox(height: 10.rh(context)),
                          CustomText(
                            'enablesNewSection'.translate(context),
                            fontWeight: .w300,
                            fontSize: context.font.xs,
                            color: context.color.textColorDark.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          _buildTextField(
                            context,
                            title: 'instagram',
                            controller: _instagramController,
                            validator: CustomTextFieldValidator.link,
                          ),
                          _buildTextField(
                            context,
                            title: 'facebook',
                            controller: _facebookController,
                            validator: CustomTextFieldValidator.link,
                          ),
                          _buildTextField(
                            context,
                            title: 'youtube',
                            controller: _youtubeController,
                            validator: CustomTextFieldValidator.link,
                          ),
                          _buildTextField(
                            context,
                            title: 'twitter',
                            controller: _twitterController,
                            validator: CustomTextFieldValidator.link,
                          ),
                          _buildTextField(
                            context,
                            title: 'linkedin',
                            controller: _linkedinController,
                            validator: CustomTextFieldValidator.link,
                          ),
                          SizedBox(height: 45.rh(context)),
                          UiUtils.buildButton(
                            context,
                            outerPadding: const EdgeInsets.only(bottom: 16),
                            onPressed: () => unawaited(_submit()),
                            isInProgress:
                                updateState is UpdateAgentProfileInProgress,
                            height: 48.rh(context),
                            buttonTitle: 'updateProfile'.translate(context),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
