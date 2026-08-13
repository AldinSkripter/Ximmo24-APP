import 'package:ebroker/data/cubits/agents/fetch_projects_cubit.dart';
import 'package:ebroker/data/cubits/agents/fetch_property_cubit.dart';
import 'package:ebroker/data/cubits/appointment/post/create_appointment_request_cubit.dart';
import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/agent/agents_properties_models/customer_data.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_mode/agent_properties.dart';
import 'package:ebroker/ui/screens/agent_mode/agents_projects.dart';
import 'package:ebroker/ui/screens/stories/widgets/story_ring_avatar.dart';
import 'package:ebroker/ui/screens/widgets/read_more_text.dart';
import 'package:ebroker/ui/screens/widgets/search_filter_bar.dart';
import 'package:ebroker/utils/custom_tabbar.dart';
import 'package:ebroker/utils/whatsapp_helper.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentDetailsScreen extends StatefulWidget {
  const AgentDetailsScreen({
    required this.isAdmin,
    required this.agentID,
    this.heroTag,
    this.heroImageUrl,
    this.agentName,
    this.agentEmail,
    this.isVerified,
    super.key,
  });

  final bool isAdmin;
  final String agentID;
  final String? heroTag;
  final String? heroImageUrl;
  final String? agentName;
  final String? agentEmail;
  final bool? isVerified;

  static Widget buildWithProviders({
    required bool isAdmin,
    required String agentID,
    String? heroTag,
    String? heroImageUrl,
    String? agentName,
    String? agentEmail,
    bool? isVerified,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FetchAgentsPropertyCubit(),
        ),
        BlocProvider(
          create: (_) => FetchAgentsProjectCubit(),
        ),
      ],
      child: AgentDetailsScreen(
        isAdmin: isAdmin,
        agentID: agentID,
        heroTag: heroTag,
        heroImageUrl: heroImageUrl,
        agentName: agentName,
        agentEmail: agentEmail,
        isVerified: isVerified,
      ),
    );
  }

  static Route<dynamic> route(RouteSettings routeSettings) {
    final argument = routeSettings.arguments! as Map;

    return CupertinoPageRoute(
      builder: (_) => AgentDetailsScreen.buildWithProviders(
        isAdmin: argument['isAdmin'] as bool,
        agentID: argument['agentID'] as String,
        heroTag: argument['heroTag'] as String?,
        heroImageUrl: argument['heroImageUrl'] as String?,
        agentName: argument['agentName'] as String?,
        agentEmail: argument['agentEmail'] as String?,
        isVerified: argument['isVerified'] as bool?,
      ),
    );
  }

  @override
  State<AgentDetailsScreen> createState() => _AgentDetailsScreenState();
}

class _AgentDetailsScreenState extends State<AgentDetailsScreen>
    with TickerProviderStateMixin {
  static const double _bannerHeight = 200;
  static const double _cardOverlap = 40;

  bool showProjects = false;
  bool isProjectAllowed = false;
  TabController? _tabController;
  late ScrollController _scrollController;
  int _currentTabIndex = 0;
  bool _isShowingSubscriptionDialog = false;

  late final TextEditingController _searchController;
  Timer? _searchDelay;
  String _previousSearchQuery = '';
  FilterApply? _selectedFilter;

  late final TextEditingController _projectSearchController;
  Timer? _projectSearchDelay;
  String _previousProjectSearchQuery = '';
  FilterApply? _selectedProjectFilter;

  int get _projectsTabIndex => showProjects ? 1 : -1;

  void _initTabController(int length) {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this);
    _currentTabIndex = _tabController?.index ?? 0;
    _tabController?.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!mounted || _tabController == null) {
      return;
    }
    final newIndex = _tabController!.index;
    if (newIndex == _currentTabIndex) {
      return;
    }

    // Gate the Projects tab behind subscription when needed.
    if (newIndex == _projectsTabIndex &&
        showProjects &&
        !isProjectAllowed &&
        !_isShowingSubscriptionDialog) {
      _isShowingSubscriptionDialog = true;
      _tabController!.index = _currentTabIndex;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          _isShowingSubscriptionDialog = false;
          return;
        }
        await GuestChecker.check(
          onNotGuest: () async {
            if (!mounted) {
              _isShowingSubscriptionDialog = false;
              return;
            }
            final result = await UiUtils.showBlurredDialoge(
              context,
              dialog: const BlurredSubscriptionDialogBox(
                packageType: SubscriptionPackageType.premiumProjects,
                isAcceptContainesPush: true,
              ),
            );
            _isShowingSubscriptionDialog = false;

            if (result != true && mounted) {
              _tabController?.animateTo(0);
            }
          },
        );
        _isShowingSubscriptionDialog = false;
      });
      return;
    }

    _currentTabIndex = newIndex;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _searchController.addListener(_searchPropertyListener);
    _projectSearchController = TextEditingController();
    _projectSearchController.addListener(_searchProjectListener);
    _initTabController(2);
    HelperUtils.runAfterTransition(context, () {
      if (!mounted) return;
      unawaited(getAgentProjectsAndProperties());
    });
  }

  void _searchProjectListener() {
    _projectSearchDelay?.cancel();
    _projectSearchDelay = Timer(
      const Duration(milliseconds: 500),
      _projectSearch,
    );
  }

  Future<void> _projectSearch() async {
    final query = _projectSearchController.text.trim();
    if (_previousProjectSearchQuery != query) {
      _previousProjectSearchQuery = query;
      await context.read<FetchAgentsProjectCubit>().fetchAgentsProject(
        agentId: widget.agentID,
        forceRefresh: true,
        isAdmin: widget.isAdmin,
        filter: _selectedProjectFilter,
        searchQuery: query,
      );
    }
  }

  void _searchPropertyListener() {
    _searchDelay?.cancel();
    _searchDelay = Timer(const Duration(milliseconds: 500), _propertySearch);
  }

  Future<void> _propertySearch() async {
    final query = _searchController.text.trim();
    if (_previousSearchQuery != query) {
      _previousSearchQuery = query;
      await context.read<FetchAgentsPropertyCubit>().fetchAgentsProperty(
        agentId: widget.agentID,
        forceRefresh: true,
        isAdmin: widget.isAdmin,
        filter: _selectedFilter,
        searchQuery: query,
      );
    }
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollEndNotification) {
      return;
    }
    final metrics = notification.metrics;
    if (metrics.pixels >= metrics.maxScrollExtent - 20) {
      if (_tabController?.index == 0) {
        // Properties tab
        if (context.read<FetchAgentsPropertyCubit>().hasMoreData()) {
          unawaited(
            context.read<FetchAgentsPropertyCubit>().fetchMore(
              isAdmin: widget.isAdmin,
            ),
          );
        }
      } else if (showProjects && _tabController?.index == 1) {
        // Projects tab
        if (context.read<FetchAgentsProjectCubit>().hasMoreData()) {
          unawaited(
            context.read<FetchAgentsProjectCubit>().fetchMore(
              isAdmin: widget.isAdmin,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_searchPropertyListener)
      ..dispose();
    _searchDelay?.cancel();
    _projectSearchController
      ..removeListener(_searchProjectListener)
      ..dispose();
    _projectSearchDelay?.cancel();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> getAgentProjectsAndProperties() async {
    await context.read<FetchAgentsProjectCubit>().fetchAgentsProject(
      forceRefresh: true,
      agentId: widget.agentID,
      isAdmin: widget.isAdmin,
      filter: _selectedProjectFilter,
      searchQuery: _projectSearchController.text.trim(),
    );

    final projectState = context.read<FetchAgentsProjectCubit>().state;
    if (projectState is FetchAgentsProjectSuccess) {
      final hasProjects =
          projectState.agentsProperty.customerData.projectCount != '0';

      if (showProjects != hasProjects) {
        setState(() {
          showProjects = hasProjects;
          isProjectAllowed = projectState.agentsProperty.isFeatureAvailable;
          _initTabController(showProjects ? 3 : 2);
        });
      }
    }

    await context.read<FetchAgentsPropertyCubit>().fetchAgentsProperty(
      forceRefresh: true,
      agentId: widget.agentID,
      isAdmin: widget.isAdmin,
      filter: _selectedFilter,
      searchQuery: _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      CreateAppointmentRequestCubit,
      CreateAppointmentRequestState
    >(
      listener: (context, state) {
        if (state is CreateAppointmentRequestSuccess) {
          HelperUtils.showSnackBarMessage(
            context,
            'appointmentScheduledSuccessfully',
            type: .success,
          );
        }
        if (state is CreateAppointmentRequestFailure) {
          HelperUtils.showSnackBarMessage(
            context,
            state.errorMessage,
            type: .error,
          );
        }
      },
      child: BlocBuilder<FetchAgentsProjectCubit, FetchAgentsProjectState>(
        builder: (context, projectState) {
          return BlocBuilder<
            FetchAgentsPropertyCubit,
            FetchAgentsPropertyState
          >(
            builder: (context, propertyState) {
              return Scaffold(
                backgroundColor: context.color.backgroundColor,
                body: SafeArea(
                  child:
                      propertyState is FetchAgentsPropertyLoading ||
                          propertyState is FetchAgentsPropertyInitial ||
                          projectState is FetchAgentsProjectLoading ||
                          projectState is FetchAgentsProjectInitial
                      ? _buildLoadingWithHeroImage()
                      : propertyState is FetchAgentsPropertyFailure
                      ? Center(
                          child: SomethingWentWrong(
                            errorMessage: propertyState.errorMessage,
                          ),
                        )
                      : propertyState is FetchAgentsPropertySuccess
                      ? _buildNestedScrollView(
                          propertyState.agentsProperty.customerData,
                          propertyState,
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingWithHeroImage() {
    final heroTag = widget.heroTag;
    final heroImageUrl = widget.heroImageUrl;

    Widget profileImageWidget = CustomImage(
      imageUrl: heroImageUrl ?? '',
    );

    if (heroTag != null) {
      profileImageWidget = Hero(
        tag: heroTag,
        child: profileImageWidget,
      );
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated Banner (grey placeholder or shimmer)
          Container(
            height: _bannerHeight,
            decoration: BoxDecoration(
              color: context.color.textColorDark.withValues(alpha: 0.05),
              borderRadius: .vertical(bottom: .circular(16.rw(context))),
            ),

            child: Stack(
              children: [
                PositionedDirectional(
                  top: 8.rh(context),
                  start: 16.rw(context),
                  child: _buildBackButton(),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -_cardOverlap),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  border: Border.all(color: context.color.borderColor),
                  borderRadius: BorderRadius.circular(8.rw(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 76.rw(context),
                            height: 76.rw(context),
                            child: profileImageWidget,
                          ),
                        ),
                        SizedBox(width: 12.rw(context)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.agentName != null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: widget.heroTag != null
                                                ? Hero(
                                                    tag:
                                                        '${widget.heroTag}-name',
                                                    child: Material(
                                                      type: MaterialType
                                                          .transparency,
                                                      child: CustomText(
                                                        widget.agentName!
                                                            .firstUpperCase(),
                                                        maxLines: 2,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize:
                                                            context.font.md,
                                                      ),
                                                    ),
                                                  )
                                                : CustomText(
                                                    widget.agentName!
                                                        .firstUpperCase(),
                                                    maxLines: 2,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: context.font.md,
                                                  ),
                                          ),
                                          if (widget.isVerified == true ||
                                              widget.isAdmin) ...[
                                            SizedBox(width: 4.rw(context)),
                                            if (widget.heroTag != null)
                                              Hero(
                                                tag: '${widget.heroTag}-badge',
                                                child: CustomImage(
                                                  imageUrl: AppIcons.agentBadge,
                                                  height: 14.rh(context),
                                                  width: 14.rw(context),
                                                  color: context
                                                      .color
                                                      .tertiaryColor,
                                                ),
                                              )
                                            else
                                              CustomImage(
                                                imageUrl: AppIcons.agentBadge,
                                                height: 14.rh(context),
                                                width: 14.rw(context),
                                                color:
                                                    context.color.tertiaryColor,
                                              ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                CustomShimmer(
                                  width: 120.rw(context),
                                  height: 16.rh(context),
                                  borderRadius: 4,
                                ),
                              SizedBox(height: 8.rh(context)),
                              if (widget.agentEmail != null &&
                                  widget.agentEmail!.isNotEmpty)
                                widget.heroTag != null
                                    ? Hero(
                                        tag: '${widget.heroTag}-email',
                                        child: Material(
                                          type: MaterialType.transparency,
                                          child: CustomText(
                                            widget.agentEmail!,
                                            fontSize: context.font.xs,
                                            color: context.color.textLightColor,
                                            maxLines: 1,
                                          ),
                                        ),
                                      )
                                    : CustomText(
                                        widget.agentEmail!,
                                        fontSize: context.font.xs,
                                        color: context.color.textLightColor,
                                        maxLines: 1,
                                      )
                              else
                                CustomShimmer(
                                  width: 150.rw(context),
                                  height: 12.rh(context),
                                  borderRadius: 4,
                                ),
                              SizedBox(height: 12.rh(context)),
                              Row(
                                children: [
                                  CustomShimmer(
                                    width: 60.rw(context),
                                    height: 20.rh(context),
                                    borderRadius: 6,
                                  ),
                                  SizedBox(width: 8.rw(context)),
                                  CustomShimmer(
                                    width: 60.rw(context),
                                    height: 20.rh(context),
                                    borderRadius: 6,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.rh(context)),
                    Row(
                      spacing: 8.rw(context),
                      children: [
                        CustomShimmer(
                          width: 48.rh(context),
                          height: 48.rh(context),
                          borderRadius: 6,
                        ),
                        Expanded(
                          child: CustomShimmer(
                            height: 48.rh(context),
                            borderRadius: 6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                CustomShimmer(
                  height: 40.rh(context),
                  borderRadius: 8,
                ),
                SizedBox(height: 16.rh(context)),
                CustomShimmer(
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

  Widget _buildNestedScrollView(
    CustomerData agent,
    FetchAgentsPropertySuccess propertyState,
  ) {
    final showPremiumStrip =
        propertyState.agentsProperty.premiumPropertyCount != '0' &&
        !propertyState.agentsProperty.isPackageAvailable &&
        !propertyState.agentsProperty.isFeatureAvailable;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _onScrollNotification(notification);
        return true;
      },
      child: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(
              child: _buildHeaderSection(
                agent,
                propertyState,
                showPremiumStrip,
              ),
            ),

            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  tabBar: CustomTabBar(
                    margin: .fromLTRB(
                      16.rw(context),
                      8.rh(context),
                      16.rw(context),
                      0,
                    ),
                    tabBackgroundColor: context.color.textColorDark,
                    tabController: _tabController!,
                    isScrollable: false,
                    tabs: [
                      Tab(text: 'properties'.translate(context)),
                      if (showProjects)
                        Tab(text: 'projects'.translate(context)),
                      Tab(text: 'aboutAgent'.translate(context)),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildPropertiesTab(propertyState),
            if (showProjects)
              isProjectAllowed
                  ? _buildProjectsTab(propertyState)
                  : const SizedBox.shrink(),
            _buildAboutTab(agent),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    CustomerData agent,
    FetchAgentsPropertySuccess propertyState,
    bool showPremiumStrip,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Layer 1: Banner background.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: _bannerHeight,
            child: _buildBanner(
              agent.agentProfile.agentBanner ?? AppIcons.fallbackAgentBanner,
            ),
          ),
        ),
        // Layer 2: Content column reserves banner space at top.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: _bannerHeight - _cardOverlap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAgentProfileCard(
                agent: agent,
                showPremiumStrip: showPremiumStrip,
                propertyState: propertyState,
              ),
            ),
            SizedBox(height: 8.rh(context)),
          ],
        ),
        // Layer 3: Back button overlay.
        PositionedDirectional(
          top: 8.rh(context),
          start: 16.rw(context),
          child: _buildBackButton(),
        ),
      ],
    );
  }

  Widget _buildBanner(String url) {
    return ClipRRect(
      borderRadius: .vertical(bottom: .circular(16.rw(context))),
      child: CustomImage(
        imageUrl: url,
        showFullScreenImage: true,
      ),
    );
  }

  Widget _buildBackButton() {
    return UiUtils.buildButton(
      context,
      buttonTitle: '',
      radius: 12.rw(context),
      padding: EdgeInsetsDirectional.only(start: 4.rw(context)),
      onPressed: () => Navigator.of(context).pop(),
      height: 40.rh(context),
      width: 40.rw(context),
      buttonColor: context.color.secondaryColor,
      prefixWidget: CustomImage(
        imageUrl: AppIcons.arrowLeft,
        color: context.color.textColorDark,
        matchTextDirection: true,
        height: 24.rh(context),
        fit: .contain,
      ),
    );
  }

  Widget _buildAgentProfileCard({
    required CustomerData agent,
    required bool showPremiumStrip,
    required FetchAgentsPropertySuccess propertyState,
  }) {
    final hasProjects =
        agent.projectCount.isNotEmpty && agent.projectCount != '0';
    final email = agent.agentProfile.agentEmail ?? agent.email;
    final mobile = (agent.agentProfile.agentMobile?.isNotEmpty ?? false)
        ? '${agent.agentProfile.agentCountryCode ?? ''}${agent.agentProfile.agentMobile}'
        : agent.mobile;
    final canShowWhatsapp = WhatsappHelper.canShow(
      agent.agentProfile.agentMobile,
      agent.agentProfile.agentCountryCode,
    );
    final canBookAppointment =
        agent.isAppointmentAvailable && widget.agentID != HiveUtils.getUserId();
    final borderColors = [
      Colors.amberAccent,
      Colors.amberAccent.withValues(alpha: .2),
      Colors.amberAccent.withValues(alpha: .05),
    ];

    final gradientContainerColors = [
      Color.lerp(
            Colors.amberAccent,
            context.color.secondaryColor,
            .7,
          ) ??
          Colors.amberAccent,
      Color.lerp(
            Colors.amberAccent,
            context.color.secondaryColor,
            .9,
          ) ??
          Colors.amberAccent,
    ];

    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StoryRingAvatar(
              agentId: agent.id,
              isAdmin: widget.isAdmin,
              borderRadius: 12,
              child: SizedBox(
                width: 76.rw(context),
                height: 76.rw(context),
                child: widget.heroTag != null
                    ? Hero(
                        tag: widget.heroTag!,
                        child: ClipRRect(
                          borderRadius: .circular(8.rw(context)),
                          child: CustomImage(
                            imageUrl: agent.profile,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: .circular(8.rw(context)),
                        child: CustomImage(
                          imageUrl: agent.profile,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 12.rw(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: widget.heroTag != null
                                  ? Hero(
                                      tag: '${widget.heroTag}-name',
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: CustomText(
                                          agent.name.firstUpperCase(),
                                          maxLines: 2,
                                          fontWeight: FontWeight.w600,
                                          fontSize: context.font.md,
                                        ),
                                      ),
                                    )
                                  : CustomText(
                                      agent.name.firstUpperCase(),
                                      maxLines: 2,
                                      fontWeight: FontWeight.w600,
                                      fontSize: context.font.md,
                                    ),
                            ),
                            if (agent.isAgentVerified || agent.isAdmin) ...[
                              SizedBox(width: 4.rw(context)),
                              if (widget.heroTag != null)
                                Hero(
                                  tag: '${widget.heroTag}-badge',
                                  child: CustomImage(
                                    imageUrl: AppIcons.agentBadge,
                                    height: 14.rh(context),
                                    width: 14.rw(context),
                                    color: context.color.tertiaryColor,
                                  ),
                                )
                              else
                                CustomImage(
                                  imageUrl: AppIcons.agentBadge,
                                  height: 14.rh(context),
                                  width: 14.rw(context),
                                  color: context.color.tertiaryColor,
                                ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await HelperUtils.shareAgent(
                            context,
                            agent.slugId,
                            isAdmin: widget.isAdmin,
                          );
                        },
                        child: Container(
                          padding: .all(8.rw(context)),
                          decoration: BoxDecoration(
                            color: context.color.textLightColor.withValues(
                              alpha: .08,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CustomImage(
                            imageUrl: AppIcons.shareApp,
                            fit: .contain,
                            height: 18.rh(context),
                            width: 18.rw(context),
                            color: context.color.textColorDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (email.isNotEmpty) ...[
                    SizedBox(height: 4.rh(context)),
                    if (widget.heroTag != null)
                      Hero(
                        tag: '${widget.heroTag}-email',
                        child: Material(
                          type: MaterialType.transparency,
                          child: CustomText(
                            email,
                            fontSize: context.font.xs,
                            color: context.color.textLightColor,
                            maxLines: 1,
                          ),
                        ),
                      )
                    else
                      CustomText(
                        email,
                        fontSize: context.font.xs,
                        color: context.color.textLightColor,
                        maxLines: 1,
                      ),
                  ],
                  SizedBox(height: 10.rh(context)),
                  Wrap(
                    spacing: 8.rw(context),
                    runSpacing: 6.rh(context),
                    children: [
                      _buildStatBadge(
                        count: agent.propertyCount,
                        label: 'properties'.translate(context),
                      ),
                      if (hasProjects)
                        _buildStatBadge(
                          count: agent.projectCount,
                          label: 'projects'.translate(context),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.rh(context)),
        Row(
          spacing: 8.rw(context),
          children: [
            // Call icon is redundant when the big button below is Call
            // itself (whatsapp/appointment both unavailable) — hidden then.
            if (canShowWhatsapp || canBookAppointment)
              _buildCallIconButton(mobile),
            // Appointment only needs its own icon slot when WhatsApp has
            // taken over the big-button slot below; otherwise it already
            // has the big button and this slot stays SMS as usual.
            if (canShowWhatsapp && canBookAppointment)
              _buildAppointmentIconButton()
            else
              _buildSmsIconButton(mobile),
            Expanded(
              child: _buildBigActionButton(
                agent: agent,
                mobile: mobile,
                canShowWhatsapp: canShowWhatsapp,
                canBookAppointment: canBookAppointment,
              ),
            ),
          ],
        ),
      ],
    );

    if (showPremiumStrip) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13.rw(context)),
          gradient: LinearGradient(
            begin: .bottomCenter,
            end: .topCenter,
            colors: borderColors,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(1.rw(context)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(12.rw(context)),
              gradient: LinearGradient(
                begin: .centerStart,
                end: .centerEnd,
                colors: gradientContainerColors,
              ),
            ),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(12.rw(context)),
                  ),
                  child: Padding(
                    padding: .all(12.rw(context)),
                    child: child,
                  ),
                ),
                _buildPremiumStrip(
                  count: propertyState.agentsProperty.premiumPropertyCount,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      padding: .all(12.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border.all(color: context.color.borderColor),
        borderRadius: BorderRadius.circular(8.rw(context)),
      ),
      child: child,
    );
  }

  Widget _buildStatBadge({required String count, required String label}) {
    return Container(
      padding: .symmetric(horizontal: 8.rw(context), vertical: 4.rh(context)),
      decoration: BoxDecoration(
        color: context.color.textLightColor.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            count,
            fontSize: context.font.xs,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(width: 4.rw(context)),
          CustomText(
            label,
            fontSize: context.font.xs,
            color: context.color.textLightColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCallIconButton(String mobile) {
    return GestureDetector(
      onTap: mobile.isEmpty ? null : () => _onTapCall(contactNumber: mobile),
      child: Container(
        height: 48.rh(context),
        width: 48.rh(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.textLightColor.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: CustomImage(
          imageUrl: AppIcons.callFilled,
          height: 20.rh(context),
          width: 20.rh(context),
          color: context.color.textColorDark,
        ),
      ),
    );
  }

  Widget _buildSmsIconButton(String mobile) {
    return GestureDetector(
      onTap: mobile.isEmpty ? null : () => _onTapSms(contactNumber: mobile),
      child: Container(
        height: 48.rh(context),
        width: 48.rh(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.textLightColor.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: CustomImage(
          imageUrl: AppIcons.chatActive,
          height: 20.rh(context),
          width: 20.rh(context),
          color: context.color.textColorDark,
        ),
      ),
    );
  }

  Widget _buildAppointmentIconButton() {
    return GestureDetector(
      onTap: _onTapScheduleAppointment,
      child: Container(
        height: 48.rh(context),
        width: 48.rh(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.textLightColor.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: CustomImage(
          imageUrl: AppIcons.appointment,
          height: 20.rh(context),
          width: 20.rh(context),
          color: context.color.textColorDark,
        ),
      ),
    );
  }

  /// The single big CTA button, priority: WhatsApp > Schedule Appointment >
  /// Call. Whichever action wins here is *not* duplicated as a small icon
  /// button elsewhere in the row (see the icon-visibility logic in
  /// [_buildAgentProfileCard]).
  Widget _buildBigActionButton({
    required CustomerData agent,
    required String mobile,
    required bool canShowWhatsapp,
    required bool canBookAppointment,
  }) {
    if (canShowWhatsapp) {
      return UiUtils.buildButton(
        context,
        prefixWidget: Padding(
          padding: EdgeInsetsDirectional.only(end: 8.rw(context)),
          child: CustomImage(
            imageUrl: AppIcons.whatsapp,
            color: context.color.buttonColor,
            height: 24.rh(context),
            fit: .contain,
          ),
        ),
        onPressed: () => _onTapWhatsapp(
          mobile: agent.agentProfile.agentMobile!,
          countryCode: agent.agentProfile.agentCountryCode!,
        ),
        height: 48.rh(context),
        padding: .symmetric(
          vertical: 12.rh(context),
          horizontal: 12.rw(context),
        ),
        fontSize: context.font.sm,
        buttonTitle: 'whatsapp'.translate(context),
      );
    }
    if (canBookAppointment) {
      return UiUtils.buildButton(
        context,
        prefixWidget: Padding(
          padding: EdgeInsetsDirectional.only(end: 8.rw(context)),
          child: CustomImage(
            imageUrl: AppIcons.appointment,
            color: context.color.buttonColor,
            height: 24.rh(context),
            fit: .contain,
          ),
        ),
        onPressed: _onTapScheduleAppointment,
        height: 48.rh(context),
        padding: .symmetric(
          vertical: 12.rh(context),
          horizontal: 12.rw(context),
        ),
        fontSize: context.font.sm,
        buttonTitle: 'scheduleAppointment'.translate(context),
      );
    }
    return UiUtils.buildButton(
      context,
      prefixWidget: Padding(
        padding: EdgeInsetsDirectional.only(end: 8.rw(context)),
        child: CustomImage(
          imageUrl: AppIcons.call,
          color: context.color.buttonColor,
          height: 24.rh(context),
          fit: .contain,
        ),
      ),
      disabled: mobile.isEmpty,
      onPressed: () => _onTapCall(contactNumber: mobile),
      height: 48.rh(context),
      padding: .symmetric(
        vertical: 12.rh(context),
        horizontal: 12.rw(context),
      ),
      fontSize: context.font.sm,
      buttonTitle: 'call'.translate(context),
    );
  }

  Widget _buildPremiumStrip({required String count}) {
    return GestureDetector(
      onTap: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            await Navigator.pushNamed(
              context,
              Routes.subscriptionPackageListRoute,
              arguments: {
                'from': 'agentDetails',
                'isBankTransferEnabled':
                    (context.read<GetApiKeysCubit>().state as GetApiKeysSuccess)
                        .bankTransferStatus ==
                    '1',
              },
            );
          },
        );
      },
      child: Padding(
        padding: .symmetric(
          horizontal: 16.rw(context),
          vertical: 12.rw(context),
        ),
        child: Row(
          children: [
            CustomImage(
              imageUrl: AppIcons.premium,
              height: 22.rh(context),
              width: 22.rh(context),
            ),
            SizedBox(width: 10.rw(context)),
            Expanded(
              child: CustomText(
                '$count+ ${'premiumProperties'.translate(context)}',
                fontSize: context.font.sm,
                fontWeight: FontWeight.w500,
                maxLines: 1,
              ),
            ),
            Transform.flip(
              flipX: true,
              child: CustomImage(
                imageUrl: AppIcons.arrowLeft,
                height: 24.rh(context),
                width: 24.rh(context),
                fit: .contain,
                matchTextDirection: true,
                color: context.color.textColorDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsTab(FetchAgentsPropertySuccess projectState) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey<String>(
            'projects_tab',
          ),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                context,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchDelegate(
                height: 64.rh(context),
                child: SearchFilterBar(
                  controller: _projectSearchController,
                  currentFilter: _selectedProjectFilter,
                  isProject: true,
                  showPropertyType: false,
                  onSearchChanged: (query) async {
                    if (_previousProjectSearchQuery == query) return;
                    _previousProjectSearchQuery = query;
                    _projectSearchDelay?.cancel();
                    await context
                        .read<FetchAgentsProjectCubit>()
                        .fetchAgentsProject(
                          agentId: widget.agentID,
                          forceRefresh: true,
                          isAdmin: widget.isAdmin,
                          filter: _selectedProjectFilter,
                          searchQuery: query,
                        );
                  },
                  onFilterApplied: (filter) async {
                    _selectedProjectFilter = filter;
                    await context
                        .read<FetchAgentsProjectCubit>()
                        .fetchAgentsProject(
                          agentId: widget.agentID,
                          forceRefresh: true,
                          isAdmin: widget.isAdmin,
                          filter: filter,
                          searchQuery: _projectSearchController.text.trim(),
                        );
                    setState(() {});
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AgentProjects(
                agentId: projectState.agentsProperty.customerData.id.toString(),
                isAdmin: widget.isAdmin,
                selectedFilter: _selectedProjectFilter,
                searchQuery: _projectSearchController.text.trim(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertiesTab(FetchAgentsPropertySuccess propertyState) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey<String>('properties_tab'),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchDelegate(
                height: 64.rh(context),
                child: SearchFilterBar(
                  controller: _searchController,
                  currentFilter: _selectedFilter,
                  onSearchChanged: (query) async {
                    if (_previousSearchQuery == query) return;
                    _previousSearchQuery = query;
                    _searchDelay?.cancel();
                    await context
                        .read<FetchAgentsPropertyCubit>()
                        .fetchAgentsProperty(
                          agentId: widget.agentID,
                          forceRefresh: true,
                          isAdmin: widget.isAdmin,
                          filter: _selectedFilter,
                          searchQuery: query,
                        );
                  },
                  onFilterApplied: (filter) async {
                    _selectedFilter = filter;
                    await context
                        .read<FetchAgentsPropertyCubit>()
                        .fetchAgentsProperty(
                          agentId: widget.agentID,
                          forceRefresh: true,
                          isAdmin: widget.isAdmin,
                          filter: filter,
                          searchQuery: _searchController.text.trim(),
                        );
                    setState(() {});
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: AgentProperties(
                agentId: propertyState.agentsProperty.customerData.id
                    .toString(),
                isAdmin: widget.isAdmin,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutTab(CustomerData agent) {
    final email = agent.agentProfile.agentEmail ?? agent.email;
    final mobile = (agent.agentProfile.agentMobile?.isNotEmpty ?? false)
        ? '${agent.agentProfile.agentCountryCode ?? ''}${agent.agentProfile.agentMobile}'
        : agent.mobile;
    final address = agent.agentProfile.agentAddress ?? agent.address;
    final aboutMe = agent.agentProfile.aboutMe ?? '';

    bool hasSocialLink(String? value) {
      final link = value?.trim() ?? '';
      return link.isNotEmpty && link.toLowerCase() != 'null';
    }

    final showSocials =
        hasSocialLink(agent.agentProfile.facebookId) ||
        hasSocialLink(agent.agentProfile.linkedinId) ||
        hasSocialLink(agent.agentProfile.instagramId) ||
        hasSocialLink(agent.agentProfile.twitterId) ||
        hasSocialLink(agent.agentProfile.youtubeId);

    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey<String>('about_tab'),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16.rw(context),
                12.rh(context),
                16.rw(context),
                24.rh(context),
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _aboutCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (email.isNotEmpty)
                            _contactRow(
                              icon: AppIcons.email,
                              value: email,
                              onTap: () => _onTapEmail(email: email),
                            ),
                          if (email.isNotEmpty && mobile.isNotEmpty)
                            SizedBox(height: 10.rh(context)),
                          if (mobile.isNotEmpty)
                            _contactRow(
                              icon: AppIcons.call,
                              value: mobile,
                              onTap: () => _onTapCall(contactNumber: mobile),
                            ),
                          if (showSocials) ...[
                            SizedBox(height: 12.rh(context)),
                            UiUtils.getDivider(context),
                            SizedBox(height: 12.rh(context)),
                            Row(
                              children: [
                                CustomText(
                                  'followMe'.translate(context),
                                  fontSize: context.font.sm,
                                  fontWeight: FontWeight.w500,
                                ),
                                SizedBox(width: 8.rw(context)),
                                Expanded(
                                  child: Wrap(
                                    spacing: 12.rw(context),
                                    runSpacing: 12.rw(context),
                                    children: [
                                      if (hasSocialLink(
                                        agent.agentProfile.facebookId,
                                      ))
                                        _socialButton(
                                          name: 'facebook',
                                          url: agent.agentProfile.facebookId!
                                              .trim(),
                                        ),
                                      if (hasSocialLink(
                                        agent.agentProfile.linkedinId,
                                      ))
                                        _socialButton(
                                          name: 'linkedin',
                                          url: agent.agentProfile.linkedinId!
                                              .trim(),
                                        ),
                                      if (hasSocialLink(
                                        agent.agentProfile.instagramId,
                                      ))
                                        _socialButton(
                                          name: 'instagram',
                                          url: agent.agentProfile.instagramId!
                                              .trim(),
                                        ),
                                      if (hasSocialLink(
                                        agent.agentProfile.twitterId,
                                      ))
                                        _socialButton(
                                          name: 'twitter',
                                          url: agent.agentProfile.twitterId!
                                              .trim(),
                                        ),
                                      if (hasSocialLink(
                                        agent.agentProfile.youtubeId,
                                      ))
                                        _socialButton(
                                          name: 'youtube',
                                          url: agent.agentProfile.youtubeId!
                                              .trim(),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (address.trim().isNotEmpty) ...[
                      SizedBox(height: 12.rh(context)),
                      _aboutCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'addressLbl'.translate(context),
                              fontSize: context.font.sm,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: 8.rh(context)),
                            ReadMoreText(
                              text: address,
                              style: TextStyle(
                                fontSize: context.font.xs,
                                fontWeight: FontWeight.w500,
                                color: context.color.textLightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (aboutMe.trim().isNotEmpty) ...[
                      SizedBox(height: 12.rh(context)),
                      _aboutCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              'aboutAgent'.translate(context),
                              fontSize: context.font.sm,
                              fontWeight: FontWeight.w600,
                            ),
                            SizedBox(height: 8.rh(context)),
                            CustomText(
                              aboutMe,
                              fontSize: context.font.xs,
                              fontWeight: FontWeight.w500,
                              color: context.color.textLightColor,
                              maxLines: 100,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _aboutCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border.all(color: context.color.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }

  Widget _contactRow({
    required String icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 32.rw(context),
            height: 32.rh(context),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.color.textLightColor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: CustomImage(
              imageUrl: icon,
              height: 16.rh(context),
              width: 16.rh(context),
              color: context.color.textColorDark,
            ),
          ),
          SizedBox(width: 10.rw(context)),
          Expanded(
            child: CustomText(
              value,
              fontWeight: FontWeight.w500,
              fontSize: context.font.sm,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton({required String name, required String url}) {
    final String iconName;
    switch (name) {
      case 'facebook':
        iconName = AppIcons.facebook;
      case 'twitter':
        iconName = AppIcons.twitter;
      case 'instagram':
        iconName = AppIcons.instagram;
      case 'youtube':
        iconName = AppIcons.youtube;
      case 'linkedin':
        iconName = AppIcons.linkedin;
      default:
        iconName = '';
    }
    if (iconName.isEmpty) {
      return const SizedBox.shrink();
    }
    final uri = Uri.parse(url);
    return GestureDetector(
      onTap: () => _launchUrl(uri),
      child: CustomImage(
        imageUrl: iconName,
        height: 24.rh(context),
        width: 24.rw(context),
        fit: .contain,
        color: context.color.textColorDark,
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    try {
      await launchUrl(url);
    } on Exception catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _onTapCall({required String contactNumber}) async {
    await GuestChecker.check(
      onNotGuest: () async {
        final url = Uri.parse('tel: +$contactNumber');
        try {
          await launchUrl(url);
        } on Exception catch (e) {
          throw Exception('Error calling $e');
        }
      },
    );
  }

  Future<void> _onTapSms({required String contactNumber}) async {
    await GuestChecker.check(
      onNotGuest: () async {
        final url = Uri.parse('sms: $contactNumber');
        try {
          await launchUrl(url);
        } on Exception catch (e) {
          throw Exception('Error calling $e');
        }
      },
    );
  }

  Future<void> _onTapWhatsapp({
    required String mobile,
    required String countryCode,
  }) async {
    await GuestChecker.check(
      onNotGuest: () async {
        await WhatsappHelper.open(mobile, countryCode);
      },
    );
  }

  Future<void> _onTapEmail({required String email}) async {
    await GuestChecker.check(
      onNotGuest: () async {
        final url = Uri.parse('mailto: $email');
        try {
          await launchUrl(url);
        } on Exception catch (e) {
          throw Exception('Error mail $e');
        }
      },
    );
  }

  Future<void> _onTapScheduleAppointment() async {
    await GuestChecker.check(
      onNotGuest: () async {
        final propertyState = context.read<FetchAgentsPropertyCubit>().state;
        if (propertyState is FetchAgentsPropertySuccess) {
          await Navigator.pushNamed(
            context,
            Routes.appointmentFlow,
            arguments: {
              'isAdmin': widget.isAdmin,
              'agentDetails': propertyState.agentsProperty.customerData,
            },
          );
        } else {
          HelperUtils.showSnackBarMessage(
            context,
            'pleaseWaitForProperties',
            type: .warning,
          );
        }
      },
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyTabBarDelegate({required this.tabBar});
  final Widget tabBar;

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: context.color.backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  _StickySearchDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: context.color.backgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
