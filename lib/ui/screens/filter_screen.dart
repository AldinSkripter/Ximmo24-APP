// filter_screen.dart - Optimized version

import 'package:ebroker/data/cubits/utility/fetch_facilities_cubit.dart';
import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/bottom_sheets/choose_location_bottomsheet.dart';
import 'package:ebroker/utils/admob/banner_ad_load_widget.dart';
import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({
    super.key,
    this.showPropertyType = false,
    this.selectedFilter,
    this.isProject = false,
    this.lockedFilter,
  });

  final bool showPropertyType;
  final FilterApply? selectedFilter;
  final bool isProject;
  final FilterApply? lockedFilter;

  @override
  FilterScreenState createState() => FilterScreenState();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => FilterScreen(
        selectedFilter: arguments?['filter'] as FilterApply? ?? FilterApply(),
        showPropertyType: arguments?['showPropertyType'] as bool? ?? false,
        isProject: arguments?['isProject'] as bool? ?? false,
        lockedFilter: arguments?['lockedFilter'] as FilterApply?,
      ),
    );
  }
}

class FilterScreenState extends State<FilterScreen> {
  // Lock checks helper getters
  bool get _isPremiumLocked =>
      widget.lockedFilter?.get<FlagsFilter>().premium ?? false;
  bool get _isPromotedLocked =>
      widget.lockedFilter?.get<FlagsFilter>().promoted ?? false;
  bool get _isLocationLocked =>
      !(widget.lockedFilter?.get<LocationFilter>().isEmpty ?? true);
  bool get _isCategoryLocked =>
      !(widget.lockedFilter?.get<CategoryFilter>().isEmpty ?? true);
  bool get _isPropertyTypeLocked =>
      !(widget.lockedFilter?.get<PropertyTypeFilter>().isEmpty ?? true);
  bool get _isProjectTypeLocked =>
      !(widget.lockedFilter?.get<ProjectTypeFilter>().isEmpty ?? true);

  // Controllers
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  // Filter state
  late FilterApply _filter;

  // Location state
  String? _city;
  String? _state;
  String? _country;

  // Selection state
  Category? _selectedCategory;
  final Set<int> _selectedFacilities = {};

  // Flags state
  bool _promoted = false;
  bool _premium = false;

  // Constants for posted since options
  static const List<({PostedSinceDuration duration, String labelKey})>
  _postedSinceOptions = [
    (labelKey: 'anytimeLbl', duration: PostedSinceDuration.anytime),
    (labelKey: 'lastWeekLbl', duration: PostedSinceDuration.lastWeek),
    (labelKey: 'yesterdayLbl', duration: PostedSinceDuration.yesterday),
    (labelKey: 'lastMonthLbl', duration: PostedSinceDuration.lastMonth),
    (
      labelKey: 'lastThreeMonthLbl',
      duration: PostedSinceDuration.lastThreeMonth,
    ),
    (labelKey: 'lastSixMonthLbl', duration: PostedSinceDuration.lastSixMonth),
  ];
  //Nearby Places
  final Map<int, TextEditingController> distanceFieldList = {};
  final Set<int> _addedNearbyPlaceIds = {};
  double _minPriceLimit = 0;
  double _maxPriceLimit = 100000;
  @override
  void initState() {
    super.initState();
    _initializeFilter();
    _initializeControllers();
    _initializeBudgetLimits();
    unawaited(_fetchFacilities());
  }

  void _initializeFilter() {
    _filter = widget.selectedFilter?.copy() ?? FilterApply();

    // Initialize from existing filter
    final category = _filter.get<CategoryFilter>();
    final facilities = _filter.get<FacilitiesFilter>();
    final location = _filter.get<LocationFilter>();
    final nearbyPlaces = _filter.get<NearbyPlacesFilter>();
    final flags = _filter.get<FlagsFilter>();

    // Set initial values
    if (category.categoryId != null) {
      _selectedCategory = Category(id: int.tryParse(category.categoryId!) ?? 0);
    }

    _selectedFacilities.addAll(facilities.facilities);

    _city = location.city;
    _state = location.state;
    _country = location.country;

    _promoted = flags.promoted;
    _premium = flags.premium;

    // Initialize nearby places controllers and added IDs
    for (final place in nearbyPlaces.nearbyPlaces) {
      distanceFieldList[place.id] = TextEditingController(
        text: place.value,
      );
      _addedNearbyPlaceIds.add(place.id);
    }
  }

  void _initializeControllers() {
    final minMax = _filter.get<MinMaxBudget>();
    _minController = TextEditingController(text: minMax.min ?? '');
    _maxController = TextEditingController(text: minMax.max ?? '');
  }

  void _initializeBudgetLimits() {
    final state = context.read<FetchSystemSettingsCubit>().state;
    if (state is FetchSystemSettingsSuccess) {
      final settingsData = state.settings['data'];
      _minPriceLimit =
          double.tryParse(settingsData['min_price']?.toString() ?? '') ?? 0.0;
      _maxPriceLimit =
          double.tryParse(settingsData['max_price']?.toString() ?? '') ??
          100000.0;
    }
  }

  Future<void> _fetchFacilities() async {
    if (!mounted) return;
    await context.read<FetchFacilitiesCubit>().fetch();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    for (final controller in distanceFieldList.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _filter.clear();
      widget.lockedFilter?.activeFilters.forEach(_filter.addOrUpdate);

      _minController.clear();
      _maxController.clear();
      _selectedCategory = _isCategoryLocked
          ? (widget.lockedFilter?.get<CategoryFilter>().categoryId != null
                ? Category(
                    id:
                        int.tryParse(
                          widget.lockedFilter!
                              .get<CategoryFilter>()
                              .categoryId!,
                        ) ??
                        0,
                  )
                : null)
          : null;
      _selectedFacilities.clear();
      _city = _isLocationLocked
          ? widget.lockedFilter?.get<LocationFilter>().city
          : null;
      _state = _isLocationLocked
          ? widget.lockedFilter?.get<LocationFilter>().state
          : null;
      _country = _isLocationLocked
          ? widget.lockedFilter?.get<LocationFilter>().country
          : null;
      _promoted = _isPromotedLocked;
      _premium = _isPremiumLocked;

      _addedNearbyPlaceIds.clear();
      // Clear distance field controllers
      for (final controller in distanceFieldList.values) {
        controller.clear();
      }
    });
  }

  void _applyFilters() {
    // Update filter with current values
    if (!widget.isProject) {
      _filter
        ..addOrUpdate(
          MinMaxBudget(
            min: _minController.text.trim().isEmpty
                ? null
                : _minController.text,
            max: _maxController.text.trim().isEmpty
                ? null
                : _maxController.text,
          ),
        )
        ..addOrUpdate(FacilitiesFilter(_selectedFacilities.toList()));

      // Add nearby places filter
      final nearbyPlaces = <NearbyPlace>[];
      for (final entry in distanceFieldList.entries) {
        if (!_addedNearbyPlaceIds.contains(entry.key)) continue;
        final text = entry.value.text.trim();
        if (text.isNotEmpty) {
          final distance = int.tryParse(text);
          if (distance != null) {
            nearbyPlaces.add(
              NearbyPlace(
                id: entry.key,
                value: distance.toString(),
              ),
            );
          }
        }
      }

      if (nearbyPlaces.isNotEmpty) {
        _filter.addOrUpdate(NearbyPlacesFilter(nearbyPlaces));
      } else {
        _filter.remove<NearbyPlacesFilter>();
      }
    }

    // Set category name for display
    if (widget.showPropertyType || widget.isProject) {
      selectedcategoryName = _selectedCategory?.category ?? '';
    }

    _filter.addOrUpdate(
      FlagsFilter(
        promoted: _promoted,
        premium: _premium,
      ),
    );

    Navigator.pop(context, _filter);
  }

  void _removeNearbyPlace(int facilityId) {
    setState(() {
      _addedNearbyPlaceIds.remove(facilityId);
      distanceFieldList[facilityId]?.clear();
    });
  }

  void _addNearbyPlace(int facilityId) {
    setState(() {
      _addedNearbyPlaceIds.add(facilityId);
      distanceFieldList.putIfAbsent(facilityId, TextEditingController.new);
    });
  }

  void _showAddNearbyPlacesBottomSheet() {
    unawaited(
      CustomBottomSheet.show<void>(
        context: context,
        title: '',
        showDragHandle: false,
        isScrollControlled: true,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return BlocBuilder<FetchFacilitiesCubit, FetchFacilitiesState>(
              builder: (context, state) {
                if (state is! FetchFacilitiesSuccess) {
                  return const SizedBox.shrink();
                }
                final remainingFacilities = state.outdoorFacilities
                    .where(
                      (facility) => !_addedNearbyPlaceIds.contains(facility.id),
                    )
                    .toList();

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.7,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            'chooseNearbyPlaces'.translate(context),
                            fontSize: context.font.lg,
                            fontWeight: FontWeight.w700,
                            color: context.color.textColorDark,
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.color.textColorDark.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: context.color.textColorDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.rh(context)),
                      UiUtils.getDivider(context),
                      SizedBox(height: 12.rh(context)),
                      if (remainingFacilities.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: CustomText(
                              'noDetailsFound'.translate(context),
                              color: context.color.textColorDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              spacing: 8.rh(context),
                              children: List.generate(
                                remainingFacilities.length,
                                (index) {
                                  final facility = remainingFacilities[index];
                                  return Row(
                                    children: [
                                      Container(
                                        height: 48.rh(context),
                                        width: 48.rw(context),
                                        padding: EdgeInsets.all(8.rw(context)),
                                        decoration: BoxDecoration(
                                          color: context.color.textColorDark
                                              .withValues(alpha: 0.05),
                                          borderRadius: .circular(
                                            4.rw(context),
                                          ),
                                        ),
                                        child: CustomImage(
                                          imageUrl: facility.image ?? '',
                                          color: context.color.textColorDark,
                                        ),
                                      ),
                                      SizedBox(width: 12.rw(context)),
                                      Expanded(
                                        child: CustomText(
                                          facility.translatedName ??
                                              facility.name ??
                                              '',
                                          fontSize: context.font.md,
                                          color: context.color.textColorDark,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          _addNearbyPlace(facility.id!);
                                          setSheetState(() {});
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            4.rw(context),
                                          ),
                                          decoration: const BoxDecoration(
                                            color: successMessageColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: context.color.secondaryColor,
                                            size: 16.rh(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectLocation() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await CustomBottomSheet.show<GooglePlaceModel>(
      context: context,
      isScrollControlled: true,
      title: 'selectLocation'.translate(context),
      child: const ChooseLocatonBottomSheet(),
    );
    if (result != null && mounted) {
      setState(() {
        _city = result.city;
        _country = result.country;
        _state = result.state;

        _filter.addOrUpdate(
          LocationFilter(
            placeId: result.placeId,
            city: result.city,
            state: result.state,
            country: result.country,
          ),
        );
      });
    }
  }

  void _clearLocation() {
    setState(() {
      _city = null;
      _state = null;
      _country = null;
      _filter.remove<LocationFilter>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: CustomAppBar(
          title: 'filterTitle'.translate(context),
        ),
        bottomNavigationBar: _buildBottomBar(),
        body: SingleChildScrollView(
          physics: Constant.scrollPhysics,
          padding: EdgeInsets.fromLTRB(
            16.rw(context),
            16.rh(context),
            16.rw(context),
            28.rh(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterHero(),
              SizedBox(height: 16.rh(context)),
              _premiumSection(_buildPropertyTypeToggle()),
              if (widget.showPropertyType || widget.isProject) ...[
                SizedBox(height: 16.rh(context)),
                _premiumSection(_buildCategorySection()),
              ],
              if (!widget.isProject) ...[
                SizedBox(height: 16.rh(context)),
                _premiumSection(_buildBudgetSection()),
              ],
              SizedBox(height: 16.rh(context)),
              _premiumSection(_buildPostedSinceSection()),
              SizedBox(height: 16.rh(context)),
              _premiumSection(_buildLocationSection()),
              SizedBox(height: 16.rh(context)),
              _premiumSection(_buildFlagsSection()),
              if (!widget.isProject) ...[
                SizedBox(height: 16.rh(context)),
                _premiumSection(_buildFacilitiesSection()),
                SizedBox(height: 16.rh(context)),
                _premiumSection(_buildAddedNearbyPlacesSection()),
              ],
              SizedBox(height: 16.rh(context)),
              const Center(
                child: BannerAdWidget(bannerSize: AdSize.banner),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterHero() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.rw(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            context.color.tertiaryColor,
            context.color.tertiaryColor.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(26.rw(context)),
        boxShadow: [
          BoxShadow(
            color: context.color.tertiaryColor.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52.rw(context),
            height: 52.rh(context),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(17.rw(context)),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: context.color.buttonColor,
              size: 28.rw(context),
            ),
          ),
          SizedBox(width: 14.rw(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'filterTitle'.translate(context),
                  color: context.color.buttonColor,
                  fontSize: context.font.xl,
                  fontWeight: FontWeight.w800,
                ),
                SizedBox(height: 4.rh(context)),
                CustomText(
                  'search'.translate(context),
                  color: context.color.buttonColor.withValues(alpha: 0.76),
                  fontSize: context.font.sm,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumSection(Widget child) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(22.rw(context)),
        border: Border.all(
          color: context.color.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.09)
              : context.color.borderColor.withValues(alpha: 0.68),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.color.brightness == Brightness.dark ? 0.18 : 0.05,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBottomBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(
        12.rw(context),
        0,
        12.rw(context),
        8.rh(context),
      ),
      height: 72.rh(context),
      padding: EdgeInsets.all(10.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22.rw(context)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: UiUtils.buildButton(
              context,
              onPressed: _resetFilters,
              buttonColor: context.color.secondaryColor,
              showElevation: false,
              textColor: context.color.tertiaryColor,
              border: BorderSide(color: context.color.tertiaryColor),
              radius: 15,
              buttonTitle: 'clearfilter'.translate(context),
            ),
          ),
          SizedBox(width: 16.rw(context)),
          Expanded(
            child: UiUtils.buildButton(
              context,
              buttonTitle: 'applyFilter'.translate(context),
              onPressed: _applyFilters,
              buttonColor: context.color.tertiaryColor,
              textColor: context.color.buttonColor,
              radius: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeToggle() {
    if (widget.isProject) {
      final projectType = _filter.get<ProjectTypeFilter>().type;
      final isLocked = _isProjectTypeLocked;

      return Container(
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.color.borderColor),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                title: 'upcoming'.translate(context),
                isSelected: projectType == 'upcoming' || projectType == '0',
                isLocked: isLocked,
                onTap: () {
                  if (isLocked) return;
                  setState(() {
                    _filter.addOrUpdate(
                      ProjectTypeFilter(
                        (projectType == 'upcoming' || projectType == '0')
                            ? ''
                            : 'upcoming',
                      ),
                    );
                  });
                },
              ),
            ),
            Expanded(
              child: _buildToggleButton(
                title: 'under_construction'.translate(context),
                isSelected:
                    projectType == 'under_construction' || projectType == '1',
                isLocked: isLocked,
                onTap: () {
                  if (isLocked) return;
                  setState(() {
                    _filter.addOrUpdate(
                      ProjectTypeFilter(
                        (projectType == 'under_construction' ||
                                projectType == '1')
                            ? ''
                            : 'under_construction',
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      );
    }

    final propertyType = _filter.get<PropertyTypeFilter>().type;
    final isLocked = _isPropertyTypeLocked;

    return Container(
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.color.borderColor),
      ),
      padding: .all(4.rw(context)),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              title: 'forSell'.translate(context),
              isSelected: propertyType == Constant.valSellBuy,
              isLocked: isLocked,
              onTap: () {
                if (isLocked) return;
                setState(() {
                  _filter.addOrUpdate(
                    PropertyTypeFilter(
                      propertyType == Constant.valSellBuy
                          ? ''
                          : Constant.valSellBuy,
                    ),
                  );
                });
              },
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              title: 'forRent'.translate(context),
              isSelected: propertyType == Constant.valRent,
              isLocked: isLocked,
              onTap: () {
                if (isLocked) return;
                setState(() {
                  _filter.addOrUpdate(
                    PropertyTypeFilter(
                      propertyType == Constant.valRent ? '' : Constant.valRent,
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    return Opacity(
      opacity: (isLocked && !isSelected) ? 0.4 : 1.0,
      child: UiUtils.buildButton(
        context,
        height: 48.rh(context),
        outerPadding: .zero,
        padding: .zero,
        onPressed: onTap,
        showElevation: false,
        textColor: isSelected
            ? context.color.buttonColor
            : context.color.textColorDark.withValues(alpha: 0.6),
        buttonColor: isSelected
            ? context.color.tertiaryColor
            : Colors.transparent,
        fontSize: context.font.md,
        radius: 4,
        buttonTitle: title,
        suffixWidget: isLocked && isSelected
            ? Padding(
                padding: .only(left: 6.rw(context)),
                child: CustomImage(
                  imageUrl: AppIcons.lock,
                  height: 14.rh(context),
                  fit: .contain,
                  color: context.color.buttonColor,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCategorySection() {
    final isLocked = _isCategoryLocked;

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            CustomText(
              'propertyType'.translate(context),
              fontSize: context.font.sm,
            ),
            if (isLocked) ...[
              SizedBox(width: 6.rw(context)),
              CustomImage(
                imageUrl: AppIcons.lock,
                height: 14.rh(context),
                fit: .contain,
                color: context.color.textColorDark.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.rh(context)),
        BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
          builder: (context, state) {
            if (state is! FetchCategorySuccess) return const SizedBox.shrink();

            final categories = [null, ...state.categories];

            return SizedBox(
              height: 32.rh(context),
              child: ListView.separated(
                scrollDirection: .horizontal,
                physics: Constant.scrollPhysics,
                separatorBuilder: (_, _) => SizedBox(width: 12.rw(context)),
                itemCount: isLocked ? 1 : categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category?.id == _selectedCategory?.id;
                  if (isLocked) {
                    final lockedCategory = categories.firstWhere(
                      (cat) => cat?.id == _selectedCategory?.id,
                      orElse: () => null,
                    );
                    return _buildCategoryChip(
                      lockedCategory,
                      true,
                      isLocked,
                    );
                  }

                  return GestureDetector(
                    onTap: isLocked
                        ? null
                        : () {
                            setState(() {
                              _selectedCategory = category;
                              _filter.addOrUpdate(
                                CategoryFilter(category?.id?.toString()),
                              );
                            });
                          },
                    child: _buildCategoryChip(category, isSelected, isLocked),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    Category? category,
    bool isSelected, [
    bool isLocked = false,
  ]) {
    final baseColor = isSelected
        ? context.color.tertiaryColor.withValues(alpha: 0.1)
        : context.color.secondaryColor;

    final border = isSelected
        ? Border.all(
            color: context.color.tertiaryColor.withValues(alpha: .2),
            width: .5,
          )
        : Border.all(color: context.color.borderColor, width: .5);

    final opacity = (isLocked && !isSelected) ? 0.4 : 1.0;

    final child = category == null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'all'.translate(context),
                color: isSelected
                    ? context.color.tertiaryColor
                    : context.color.textColorDark.withValues(alpha: 0.8),
              ),
              if (isLocked && isSelected) ...[
                SizedBox(width: 6.rw(context)),
                CustomImage(
                  imageUrl: AppIcons.lock,
                  height: 14.rh(context),
                  fit: .contain,
                  color: context.color.tertiaryColor,
                ),
              ],
            ],
          )
        : Row(
            children: [
              CustomImage(
                imageUrl: category.image ?? '',
                height: 18.rh(context),
                width: 18.rw(context),
                color: isSelected
                    ? context.color.tertiaryColor
                    : context.color.textLightColor,
              ),
              SizedBox(width: 8.rw(context)),
              CustomText(
                category.translatedName ?? category.category ?? '',
                color: isSelected
                    ? context.color.tertiaryColor
                    : context.color.textColorDark.withValues(alpha: 0.8),
              ),
              if (isLocked && isSelected) ...[
                SizedBox(width: 6.rw(context)),
                CustomImage(
                  imageUrl: AppIcons.lock,
                  height: 14.rh(context),
                  fit: .contain,
                  color: context.color.tertiaryColor,
                ),
              ],
            ],
          );

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: .symmetric(horizontal: 12.rw(context)),
        alignment: .center,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: .circular(4.rw(context)),
          border: border,
        ),
        child: child,
      ),
    );
  }

  Widget _buildBudgetSection() {
    final currentMin = double.tryParse(_minController.text) ?? _minPriceLimit;
    final currentMax = double.tryParse(_maxController.text) ?? _maxPriceLimit;

    final clampedMin = currentMin.clamp(_minPriceLimit, _maxPriceLimit);
    final clampedMax = currentMax.clamp(_minPriceLimit, _maxPriceLimit);
    final rangeValues = RangeValues(
      clampedMin <= clampedMax ? clampedMin : clampedMax,
      clampedMax,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'budgetLbl'.translate(context),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.rh(context)),
        Row(
          children: [
            Expanded(
              child: _buildBudgetField(
                controller: _minController,
                label: 'minLbl'.translate(context),
                validator: _validateMin,
              ),
            ),
            SizedBox(width: 16.rw(context)),
            Expanded(
              child: _buildBudgetField(
                controller: _maxController,
                label: 'maxLbl'.translate(context),
                validator: _validateMax,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.rh(context)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: context.color.tertiaryColor,
            inactiveTrackColor: context.color.borderColor,
            trackHeight: 4,
            thumbColor: context.color.tertiaryColor,
            overlayColor: context.color.tertiaryColor.withValues(alpha: 0.2),
            valueIndicatorColor: context.color.tertiaryColor,
          ),
          child: RangeSlider(
            values: rangeValues,
            min: _minPriceLimit,
            max: _maxPriceLimit,
            onChanged: (values) {
              setState(() {
                _minController.text = values.start.toInt().toString();
                _maxController.text = values.end.toInt().toString();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textInputAction: TextInputAction.done,
      validator: validator,
      onChanged: (val) {
        setState(() {});
      },
      decoration: InputDecoration(
        isDense: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.color.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.color.borderColor),
        ),
        labelStyle: TextStyle(
          color: context.color.textColorDark.withValues(alpha: 0.6),
        ),
        hintText: '00',
        label: CustomText(label),
        prefixText: '${AppSettings.currencySymbol} ',
        prefixStyle: TextStyle(color: context.color.textColorDark),
        fillColor: context.color.secondaryColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.number,
      style: TextStyle(color: context.color.textColorDark),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  String? _validateMin(String? value) {
    if (value?.isEmpty ?? true) return null;
    if (_maxController.text.isEmpty) return null;

    final min = num.tryParse(value!) ?? 0;
    final max = num.tryParse(_maxController.text) ?? 0;

    if (min >= max) {
      return '${'enterSmallerThan'.translate(context)} ${_maxController.text}';
    }
    return null;
  }

  String? _validateMax(String? value) {
    if (value?.isEmpty ?? true) return null;
    if (_minController.text.isEmpty) return null;

    final max = num.tryParse(value!) ?? 0;
    final min = num.tryParse(_minController.text) ?? 0;

    if (max <= min) {
      return '${'enterBiggerThan'.translate(context)} ${_minController.text}';
    }
    return null;
  }

  Widget _buildPostedSinceSection() {
    final currentDuration = _filter.get<PostedSince>().since;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'postedSinceLbl'.translate(context),
          fontSize: context.font.sm,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 8.rh(context)),
        SizedBox(
          height: 36.rh(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            separatorBuilder: (context, index) =>
                SizedBox(width: 12.rw(context)),
            itemCount: _postedSinceOptions.length,
            itemBuilder: (context, index) {
              final option = _postedSinceOptions[index];
              final isSelected = currentDuration == option.duration;

              return UiUtils.buildButton(
                context,
                fontSize: context.font.sm,
                showElevation: false,
                autoWidth: true,
                radius: 4,
                buttonColor: isSelected
                    ? context.color.tertiaryColor
                    : context.color.textColorDark.withValues(alpha: 0.05),
                textColor: isSelected
                    ? context.color.buttonColor
                    : context.color.textColorDark,
                buttonTitle: option.labelKey.translate(context),
                onPressed: () {
                  setState(() {
                    _filter.addOrUpdate(PostedSince(option.duration));
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _city != null && _city!.isNotEmpty;
    final isLocked = _isLocationLocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomText(
              'locationLbl'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w500,
            ),
            if (isLocked) ...[
              SizedBox(width: 6.rw(context)),
              CustomImage(
                imageUrl: AppIcons.lock,
                height: 14.rh(context),
                fit: .contain,
                color: context.color.textColorDark.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
        SizedBox(height: 8.rh(context)),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isLocked ? null : _selectLocation,
                child: Container(
                  height: 48.rh(context),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? context.color.secondaryColor.withValues(alpha: 0.5)
                        : context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.color.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: context.color.textColorDark.withValues(
                          alpha: 0.5,
                        ),
                        size: 20,
                      ),
                      SizedBox(width: 8.rw(context)),
                      Expanded(
                        child: CustomText(
                          hasLocation
                              ? '$_city, $_state, $_country'
                              : 'selectLocationOptional'.translate(context),
                          maxLines: 1,
                          color: isLocked
                              ? context.color.textColorDark.withValues(
                                  alpha: 0.6,
                                )
                              : context.color.textColorDark,
                        ),
                      ),
                      if (hasLocation && !isLocked)
                        GestureDetector(
                          onTap: _clearLocation,
                          child: Icon(
                            Icons.close,
                            color: context.color.textColorDark,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.rw(context)),
            GestureDetector(
              onTap: isLocked ? null : _selectLocation,
              child: Container(
                height: 48.rh(context),
                width: 48.rh(context),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isLocked
                      ? context.color.secondaryColor.withValues(alpha: 0.5)
                      : context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.color.borderColor),
                ),
                child: Opacity(
                  opacity: isLocked ? 0.5 : 1.0,
                  child: Icon(
                    Icons.gps_fixed,
                    color: context.color.tertiaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.color.borderColor),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.rw(context),
              vertical: 8.rh(context),
            ),
            child: Column(
              children: [
                _buildFlagRow(
                  title: 'featured'.translate(context),
                  iconUrl: AppIcons.featuredBolt,
                  value: _promoted,
                  onChanged: _isPromotedLocked
                      ? null
                      : (val) {
                          setState(() {
                            _promoted = val;
                          });
                        },
                ),
                SizedBox(height: 8.rh(context)),
                UiUtils.getDivider(context),
                SizedBox(height: 8.rh(context)),
                _buildFlagRow(
                  title: 'premium'.translate(context),
                  iconUrl: AppIcons.subscription,
                  value: _premium,
                  onChanged: _isPremiumLocked
                      ? null
                      : (val) {
                          setState(() {
                            _premium = val;
                          });
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlagRow({
    required String title,
    required String iconUrl,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final isLocked = onChanged == null;
    return Row(
      children: [
        CustomImage(
          imageUrl: iconUrl,
          height: 24.rh(context),
          fit: .contain,
          color: context.color.textColorDark,
        ),
        SizedBox(width: 8.rw(context)),
        Expanded(
          child: Row(
            children: [
              CustomText(
                title,
                fontSize: context.font.md,
                color: isLocked
                    ? context.color.textLightColor
                    : context.color.textColorDark,
              ),
              if (isLocked) ...[
                SizedBox(width: 6.rw(context)),
                CustomImage(
                  imageUrl: AppIcons.lock,
                  height: 14.rh(context),
                  fit: .contain,
                  color: context.color.textLightColor,
                ),
              ],
            ],
          ),
        ),
        UiSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFacilitiesSection() {
    return BlocBuilder<FetchFacilitiesCubit, FetchFacilitiesState>(
      builder: (context, state) {
        if (state is! FetchFacilitiesSuccess || state.facilities.isEmpty) {
          return const SizedBox.shrink();
        }

        final facilities = state.facilities;
        final row1 = <Widget>[];
        final row2 = <Widget>[];
        final row3 = <Widget>[];

        for (var i = 0; i < facilities.length; i++) {
          final facility = facilities[i];
          final isSelected = _selectedFacilities.contains(facility.id);

          final widget = GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedFacilities.remove(facility.id);
                } else {
                  _selectedFacilities.add(facility.id!);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.color.tertiaryColor
                    : context.color.secondaryColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? context.color.tertiaryColor
                      : context.color.borderColor,
                ),
              ),
              child: CustomText(
                facility.translatedName ?? facility.name ?? '',
                color: isSelected
                    ? context.color.buttonColor
                    : context.color.textColorDark,
                fontSize: context.font.sm,
              ),
            ),
          );

          if (i % 3 == 0) {
            row1.add(widget);
          } else if (i % 3 == 1) {
            row2.add(widget);
          } else {
            row3.add(widget);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              'facilities'.translate(context),
              fontSize: context.font.sm,
              fontWeight: FontWeight.w500,
            ),
            SizedBox(height: 12.rh(context)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: Constant.scrollPhysics,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (row1.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < row1.length; i++) ...[
                          row1[i],
                          if (i < row1.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  if (row2.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < row2.length; i++) ...[
                          row2[i],
                          if (i < row2.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                  if (row3.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < row3.length; i++) ...[
                          row3[i],
                          if (i < row3.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddedNearbyPlacesSection() {
    return BlocBuilder<FetchFacilitiesCubit, FetchFacilitiesState>(
      builder: (context, state) {
        if (state is! FetchFacilitiesSuccess) {
          return const SizedBox.shrink();
        }

        final addedFacilities = state.outdoorFacilities
            .where(
              (facility) => _addedNearbyPlaceIds.contains(facility.id),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomText(
                  'chooseNearbyPlaces'.translate(context),
                  fontSize: context.font.sm,
                  fontWeight: FontWeight.w500,
                ),
                CustomText(
                  '${'withinDistance'.translate(context)} ${AppSettings.distanceOption}',
                  fontSize: context.font.xs,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
            SizedBox(height: 12.rh(context)),
            if (addedFacilities.isNotEmpty)
              ListView.separated(
                itemCount: addedFacilities.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) =>
                    SizedBox(height: 12.rh(context)),
                itemBuilder: (context, index) {
                  final facility = addedFacilities[index];

                  // Ensure controller exists
                  distanceFieldList.putIfAbsent(
                    facility.id!,
                    TextEditingController.new,
                  );

                  return Row(
                    children: [
                      // Remove button
                      GestureDetector(
                        onTap: () => _removeNearbyPlace(facility.id!),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.rw(context)),

                      // Icon in light grey box
                      Container(
                        height: 48.rh(context),
                        width: 48.rw(context),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.color.textColorDark.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomImage(
                          imageUrl: facility.image ?? '',
                          color: context.color.textColorDark,
                        ),
                      ),
                      SizedBox(width: 12.rw(context)),

                      // Name
                      Expanded(
                        flex: 2,
                        child: CustomText(
                          facility.translatedName ?? facility.name ?? '',
                          color: context.color.textColorDark,
                          fontSize: context.font.md,
                        ),
                      ),
                      SizedBox(width: 12.rw(context)),

                      // Distance input
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: distanceFieldList[facility.id],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: TextStyle(
                            color: context.color.textColorDark,
                          ),
                          decoration: InputDecoration(
                            hintText: AppSettings.distanceOption,
                            suffixText: AppSettings.distanceOption,
                            suffixStyle: TextStyle(
                              color: context.color.textColorDark.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: context.color.borderColor,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: context.color.borderColor,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: context.color.borderColor,
                              ),
                            ),
                            isDense: true,
                            fillColor: context.color.secondaryColor,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            SizedBox(height: 12.rh(context)),
            // Add More Button
            UiUtils.buildButton(
              context,
              height: 48,
              showElevation: false,
              buttonTitle: 'Add'.translate(context),
              onPressed: _showAddNearbyPlacesBottomSheet,
              buttonColor: context.color.secondaryColor,
              textColor: context.color.tertiaryColor,
              border: BorderSide(color: context.color.tertiaryColor),
            ),
          ],
        );
      },
    );
  }
}
