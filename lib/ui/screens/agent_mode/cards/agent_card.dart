import 'package:ebroker/data/model/agent/agent_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_mode/agent_details_screen.dart';
import 'package:ebroker/ui/screens/widgets/custom_open_container.dart';
import 'package:flutter/material.dart';

class AgentCard extends StatefulWidget {
  const AgentCard({
    required this.agent,
    required this.propertyCount,
    required this.name,
    super.key,
    this.isFirst,
    this.showEndPadding,
  });

  final AgentModel agent;
  final bool? isFirst;
  final bool? showEndPadding;
  final String name;
  final String propertyCount;

  @override
  State<AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<AgentCard> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return CustomOpenContainer(
      openBuilder: (context, closeContainer) {
        return AgentDetailsScreen.buildWithProviders(
          agentID: widget.agent.id.toString(),
          isAdmin: widget.agent.isAdmin,
          heroTag: 'agent-hero-${widget.agent.id}',
          heroImageUrl: widget.agent.profile,
          agentName: widget.agent.name,
          agentEmail: widget.agent.email,
          isVerified: widget.agent.isAgentVerified,
        );
      },
      closedBuilder: (context, openContainer) {
        final resolvedHeroTag = 'agent-hero-${widget.agent.id}';
        return GestureDetector(
          onLongPress: () async {
            await HelperUtils.share(context, widget.agent.name);
          },
          onTap: () async {
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
            // Reset navigation lock after container transition
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _isNavigating = false;
                });
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.color.secondaryColor,
              border: Border.all(
                color: context.color.borderColor,
              ),
            ),
            clipBehavior: .antiAlias,
            width: 181.rw(context),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Container(
                  height: 135.rh(context),
                  margin: EdgeInsets.only(bottom: 8.rh(context)),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Hero(
                      tag: 'agent-hero-${widget.agent.id}',
                      child: CustomImage(
                        imageUrl: widget.agent.profile,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      //Name
                      Row(
                        children: [
                          Flexible(
                            child: Hero(
                              tag: '$resolvedHeroTag-name',
                              child: Material(
                                type: MaterialType.transparency,
                                child: CustomText(
                                  widget.agent.name.firstUpperCase(),
                                  fontWeight: .w500,
                                  fontSize: context.font.sm,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.rw(context)),
                          if (widget.agent.isAgentVerified ||
                              widget.agent.isAdmin)
                            Hero(
                              tag: '$resolvedHeroTag-badge',
                              child: CustomImage(
                                imageUrl: AppIcons.agentBadge,
                                height: 18.rh(context),
                                fit: .contain,
                                color: context.color.tertiaryColor,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: 4.rh(context),
                      ),
                      //Email
                      Hero(
                        tag: '$resolvedHeroTag-email',
                        child: Material(
                          type: MaterialType.transparency,
                          child: CustomText(
                            widget.agent.email,
                            fontSize: context.font.xs,
                            fontWeight: .w400,
                            color: context.color.textLightColor,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 8.rh(context),
                      ),
                      //Property count &  Project count
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: context.color.textLightColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CustomText(
                                    'properties'.translate(context),
                                    fontSize: context.font.xxs,
                                    fontWeight: .w500,
                                    maxLines: 1,
                                    color: context.color.textLightColor,
                                  ),
                                ),
                                CustomText(
                                  widget.agent.propertyCount,
                                  fontSize: context.font.xxs,
                                  fontWeight: .w500,
                                  maxLines: 1,
                                  color: context.color.textLightColor,
                                ),
                              ],
                            ),
                            SizedBox(height: 4.rh(context)),
                            UiUtils.getDivider(context),
                            SizedBox(height: 4.rh(context)),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomText(
                                    'projects'.translate(context),
                                    fontSize: context.font.xxs,
                                    fontWeight: .w500,
                                    maxLines: 1,
                                    color: context.color.textLightColor,
                                  ),
                                ),
                                CustomText(
                                  widget.agent.projectsCount,
                                  fontSize: context.font.xxs,
                                  fontWeight: .w500,
                                  maxLines: 1,
                                  color: context.color.textLightColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
