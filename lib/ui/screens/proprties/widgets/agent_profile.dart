import 'package:ebroker/data/cubits/agents/fetch_property_cubit.dart';
import 'package:ebroker/data/model/agent_profile_model.dart';
import 'package:ebroker/ui/screens/agent_mode/agent_details_screen.dart';
import 'package:ebroker/ui/screens/stories/widgets/story_ring_avatar.dart';
import 'package:ebroker/ui/screens/widgets/custom_open_container.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgentProfileWidget extends StatefulWidget {
  const AgentProfileWidget({
    required this.addedBy,
    required this.profileImage,
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.isAgent,
    required this.isAgentVerified,
    required this.isUserVerified,
    required this.propertiesCount,
    required this.projectsCount,
    required this.canScheduleAppointment,
    this.agentProfile,
    this.roleContext,
    this.popOnTap = false,
    super.key,
  });
  final String addedBy;
  final String profileImage;
  final String name;
  final String email;
  final bool isAdmin;
  final bool isAgent;
  final bool isAgentVerified;
  final bool isUserVerified;
  final String propertiesCount;
  final String projectsCount;
  final bool canScheduleAppointment;
  final AgentProfileModel? agentProfile;
  final String? roleContext;
  final bool popOnTap;

  @override
  State<AgentProfileWidget> createState() => _AgentProfileWidgetState();
}

class _AgentProfileWidgetState extends State<AgentProfileWidget> {
  bool? isAdmin;
  bool _isNavigating = false;

  String get _name =>
      (widget.roleContext == 'agent' ? widget.agentProfile?.agentName : null) ??
      widget.name;
  String get _email =>
      (widget.roleContext == 'agent'
          ? widget.agentProfile?.agentEmail
          : null) ??
      widget.email;
  String get _profileImage =>
      (widget.roleContext == 'agent'
          ? widget.agentProfile?.agentProfilePhoto
          : null) ??
      widget.profileImage;

  @override
  void initState() {
    super.initState();
    isAdmin = widget.addedBy == '0';
  }

  @override
  Widget build(BuildContext context) {
    final canNavigate =
        widget.isAdmin || (widget.isAgent && widget.roleContext == 'agent');

    return BlocBuilder<FetchAgentsPropertyCubit, FetchAgentsPropertyState>(
      builder: (context, state) {
        return IntrinsicHeight(
          child: CustomOpenContainer(
            closedShape: const RoundedRectangleBorder(),
            closedBuilder: (context, openContainer) {
              // Story-eligibility resolution: agent-owned (agentProfile
              // present) -> admin-listed (agentId 0, a valid poster id,
              // not "no agent") -> otherwise no ring at all.
              final storyAgentId =
                  widget.agentProfile?.customerId ??
                  (widget.isAdmin ? 0 : null);
              final avatar = Container(
                width: 70.rw(context),
                height: 70.rh(context),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: widget.roleContext == 'user'
                      ? null
                      : BorderRadius.circular(4),
                  shape: widget.roleContext == 'user'
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                ),
                child: Hero(
                  tag: 'agent-hero-${widget.addedBy}',
                  child: CustomImage(
                    imageUrl: _profileImage,
                  ),
                ),
              );
              return Row(
                children: [
                  if (storyAgentId != null)
                    StoryRingAvatar(
                      agentId: storyAgentId,
                      borderRadius: widget.roleContext == 'user'
                          ? null
                          : 4.rw(context),
                      child: avatar,
                    )
                  else
                    avatar,
                  SizedBox(width: 8.rw(context)),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (!canNavigate) return;
                        if (widget.popOnTap) {
                          return Navigator.of(context).pop();
                        }
                        if (_isNavigating) return;
                        final hasInternet = await HelperUtils.checkInternet();

                        if (!hasInternet) {
                          return HelperUtils.showSnackBarMessage(
                            context,
                            'noInternet',
                            type: .error,
                          );
                        }
                        setState(() {
                          _isNavigating = true;
                        });
                        openContainer();
                        Future.delayed(const Duration(seconds: 1), () {
                          if (mounted) {
                            setState(() {
                              _isNavigating = false;
                            });
                          }
                        });
                      },
                      child: Column(
                        mainAxisAlignment: .center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomText(
                                _name,
                                fontWeight: FontWeight.w500,
                                fontSize: context.font.sm,
                              ),
                              if (widget.isAgentVerified ||
                                  widget.isUserVerified ||
                                  widget.isAdmin)
                                Container(
                                  margin: EdgeInsetsDirectional.only(
                                    start: 4.rw(context),
                                  ),
                                  alignment: Alignment.center,
                                  child: CustomImage(
                                    imageUrl:
                                        widget.isAdmin ||
                                            (widget.isAgentVerified &&
                                                widget.roleContext == 'agent')
                                        ? AppIcons.agentBadge
                                        : AppIcons.userBadge,
                                    height: 16.rh(context),
                                    color: context.color.tertiaryColor,
                                  ),
                                ),
                            ],
                          ),
                          CustomText(
                            _email,
                            fontSize: context.font.xs,
                            color: context.color.textColorDark,
                            maxLines: 1,
                            fontWeight: FontWeight.w400,
                          ),
                          Container(
                            padding: .symmetric(
                              horizontal: 8.rw(context),
                              vertical: 4.rh(context),
                            ),
                            margin: .only(top: 4.rh(context)),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: context.color.textColorDark.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.propertiesCount != '0' ||
                                    widget.propertiesCount.isNotEmpty) ...[
                                  Expanded(
                                    child: CustomText(
                                      '${'properties'.translate(context)}: ${widget.propertiesCount}',
                                      fontSize: context.font.xs,
                                      color: context.color.textColorDark,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  if (widget.projectsCount != '0' ||
                                      widget.projectsCount.isNotEmpty) ...[
                                    Container(
                                      height: 12,
                                      width: 1,
                                      color: context.color.textLightColor
                                          .withValues(
                                            alpha: 0.5,
                                          ),
                                    ),
                                  ],
                                ],
                                if (widget.projectsCount != '0' ||
                                    widget.projectsCount.isNotEmpty) ...[
                                  Expanded(
                                    child: CustomText(
                                      '${'projects'.translate(context)}: ${widget.projectsCount}',
                                      fontSize: context.font.xs,
                                      color: context.color.textColorDark,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            openBuilder: (context, closeContainer) {
              return AgentDetailsScreen.buildWithProviders(
                agentID: widget.addedBy,
                isAdmin: isAdmin ?? (widget.addedBy == '0'),
                heroTag: 'agent-hero-${widget.addedBy}',
                heroImageUrl: _profileImage,
              );
            },
          ),
        );
      },
    );
  }
}
