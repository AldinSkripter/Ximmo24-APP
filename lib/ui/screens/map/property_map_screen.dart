import 'package:ebroker/data/helper/filter.dart';
import 'package:ebroker/data/repositories/map.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/search_filter_app_bar.dart';
import 'package:flutter/material.dart';

class PropertyMapScreen extends StatefulWidget {
  const PropertyMapScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return const PropertyMapScreen();
      },
    );
  }

  @override
  State<PropertyMapScreen> createState() => _PropertyMapScreenState();
}

class _PropertyMapScreenState extends State<PropertyMapScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);
  FilterApply _userFilter = FilterApply();
  LatLng? citylatLong;
  List<AppMapMarker> marker = [];
  Map<dynamic, dynamic> map = {};
  AppMapController? _mapController;
  bool isMapCreated = false;
  List<PlaceModel>? cities;
  int selectedMarker = 999999999999999;
  int? propertyId;
  ValueNotifier<bool> isLoadingProperty = ValueNotifier<bool>(false);
  PropertyModel? activePropertyModal;
  List<PropertyModel>? activePropertiesList;
  ValueNotifier<bool> loadintCitiesInProgress = ValueNotifier<bool>(false);
  bool showSellRentLables = false;
  bool showGoogleMap = true;
  final PageController _propertyCardController = PageController();
  double _currentZoom = 15;
  final PlaceSearchService _searchService =
      MapServiceFactory.createPlaceSearchService();

  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      cities = null;
      if (mounted) setState(() {});
      return;
    }
    try {
      loadintCitiesInProgress.value = true;
      cities = await _searchService.searchCities(query);
      loadintCitiesInProgress.value = false;
    } on Exception catch (_) {
      loadintCitiesInProgress.value = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _onFilterApplied(FilterApply filter) async {
    _userFilter = filter;
    if (mounted) setState(() {});
    await loadAll();
  }

  @override
  void initState() {
    super.initState();
    unawaited(loadAll());
  }

  LatLng getCameraPosition() {
    if (AppSettings.latitude.isNotEmpty && AppSettings.longitude.isNotEmpty) {
      return LatLng(
        double.parse(AppSettings.latitude),
        double.parse(AppSettings.longitude),
      );
    }
    return const LatLng(20.5937, 78.9629);
  }

  Future<void> loadAll() async {
    try {
      isLoadingProperty.value = true;
      final pointList = await GMap.getNearByProperty(
        '',
        '',
        '',
        '',
        filter: _userFilter.hasActiveFilters ? _userFilter : null,
      );
      activePropertiesList = pointList;

      //Animate camera to location
      await loopMarker(pointList);
      isLoadingProperty.value = false;
    } on Exception catch (e) {
      isLoadingProperty.value = false;
      HelperUtils.showSnackBarMessage(
        context,
        '$e',
        type: .error,
      );
    } finally {
      isLoadingProperty.value = false;
    }
  }

  Future<void> onTapCity(int index) async {
    try {
      unawaited(Widgets.showLoader(context));
      final pointList = await GMap.getNearByProperty(
        cities?.elementAt(index).city ?? '',
        cities?.elementAt(index).latitude ?? '',
        cities?.elementAt(index).longitude ?? '',
        cities?.elementAt(index).placeId ?? '',
        filter: _userFilter.hasActiveFilters ? _userFilter : null,
      );
      activePropertiesList = pointList;

      if (pointList.isEmpty) {
        marker = [];
        if (mounted) setState(() {});
      }

      final latLng = await getCityLatLong(
        latitude: cities?.elementAt(index).latitude ?? '',
        longitude: cities?.elementAt(index).longitude ?? '',
        placeId: cities?.elementAt(index).placeId ?? '',
      );

      try {
        if (latLng != null && _mapController != null) {
          await _mapController!.animateTo(latLng, zoom: 7);
        }
      } on Exception catch (e) {
        HelperUtils.showSnackBarMessage(
          context,
          '$e',
          type: .error,
        );
      }

      await loopMarker(pointList);
      _isSearching.value = false;
      HelperUtils.unfocus();
      Future.delayed(
        Duration.zero,
        () {
          Widgets.hideLoder(context);
        },
      );
      cities = null;
      if (mounted) setState(() {});
    } on Exception catch (e) {
      Widgets.hideLoder(context);
      HelperUtils.showSnackBarMessage(
        context,
        e.toString(),
        type: .error,
      );
    }
  }

  Future<void> selectPropertyAt(int index, {bool movePage = false}) async {
    final list = activePropertiesList;
    if (list == null || index < 0 || index >= list.length) return;
    final element = list[index];

    selectedMarker = index;
    propertyId = element.id;
    activePropertyModal = element;
    await loopMarker(list);

    final lat = double.tryParse(element.latitude ?? '');
    final lng = double.tryParse(element.longitude ?? '');
    if (lat != null && lng != null && _mapController != null) {
      await _mapController!.animateTo(LatLng(lat, lng), zoom: _currentZoom);
    }

    if (mounted) setState(() {});

    if (movePage) {
      if (_propertyCardController.hasClients) {
        await _propertyCardController.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_propertyCardController.hasClients) {
            _propertyCardController.jumpToPage(index);
          }
        });
      }
    }
  }

  Future<void> loopMarker(List<PropertyModel> pointList) async {
    marker.clear(); // Clear existing markers
    for (var i = 0; i < pointList.length; i++) {
      final element = pointList[i];

      // Safely parse latitude and longitude with error handling
      double? lat;
      double? lng;

      try {
        lat = element.latitude!.isNotEmpty
            ? double.parse(element.latitude!)
            : null;
        lng = element.longitude!.isNotEmpty
            ? double.parse(element.longitude!)
            : null;
      } on Exception catch (_) {
        // Skip this marker if parsing fails
        continue;
      }

      // Only add marker if both lat and lng are valid
      if (lat != null && lng != null) {
        marker.add(
          AppMapMarker(
            id: '$i',
            position: LatLng(lat, lng),
            iconAsset: selectedMarker == i
                ? 'assets/location_selected.png'
                : element.propertyType.toString().toLowerCase() == 'sell'
                ? 'assets/location_sell.png'
                : 'assets/location_rent.png',
            property: element,
            onTap: () async {
              try {
                await selectPropertyAt(i, movePage: true);
              } on Exception catch (e) {
                HelperUtils.showSnackBarMessage(
                  context,
                  '$e',
                  type: .error,
                );
              }
            },
          ),
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<LatLng?> getCityLatLong({
    required String latitude,
    required String longitude,
    required String placeId,
  }) async {
    final details = await _searchService.getPlaceDetails(
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
    );
    if (details.lat == null || details.lng == null) return null;
    return LatLng(details.lat!, details.lng!);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isSearching.dispose();
    _propertyCardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isSearching.value) {
          _isSearching.value = false;
          return;
        }
        showGoogleMap = false;
        setState(() {});
        Future.delayed(Duration.zero, () {
          Navigator.of(context).pop();
        });
      },
      child: Scaffold(
        backgroundColor: context.color.secondaryColor,
        appBar: SearchFilterAppBar(
          title: 'propertyMap'.translate(context),
          searchController: _searchController,
          searchingListenable: _isSearching,
          currentFilter: _userFilter,
          onSearchChanged: _onSearchChanged,
          onFilterApplied: _onFilterApplied,
        ),
        body: Stack(
          children: [
            // Map View
            if (showGoogleMap)
              AppMapWidget(
                config: AppMapConfig(
                  initialLatLng: getCameraPosition(),
                  initialZoom: 3,
                  markers: marker,
                  enableClustering: true,
                  onReady: (controller) {
                    _mapController = controller;
                    isMapCreated = true;
                    showSellRentLables = true;
                    setState(() {});
                  },
                  onTap: (latLng) {
                    activePropertyModal = null;
                    selectedMarker = 99999999999999;
                    setState(() {});
                  },
                  onCameraMove: (position, zoom) {
                    _currentZoom = zoom;
                    HelperUtils.unfocus();
                  },
                ),
              ),

            // Sell Rent Lable
            PositionedDirectional(
              top: 8.rh(context),
              start: 8.rw(context),
              end: 0,
              child: sellRentLable(context),
            ),

            // Cities List
            if (cities != null)
              ColoredBox(
                color: context.color.backgroundColor,
                child: ListView.builder(
                  itemCount: cities?.length ?? 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () async {
                        activePropertyModal = null;
                        setState(() {});
                        await onTapCity(index);
                      },
                      leading: SvgPicture.asset(
                        AppIcons.location,
                        colorFilter: ColorFilter.mode(
                          context.color.textColorDark,
                          .srcIn,
                        ),
                      ),
                      title: CustomText(
                        cities?.elementAt(index).city ?? '',
                      ),
                      subtitle: CustomText(
                        "${cities?.elementAt(index).state ?? ""},${cities?.elementAt(index).country ?? ""}",
                      ),
                    );
                  },
                ),
              ),

            // Loading Indicator
            PositionedDirectional(
              top: 8.rh(context),
              end: 8.rw(context),
              child: ValueListenableBuilder(
                valueListenable: isLoadingProperty,
                builder: (context, va, c) {
                  if (!va) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsetsDirectional.only(
                      end: 8,
                      top: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: .circle,
                      color: Color.lerp(
                        context.color.tertiaryColor,
                        context.color.secondaryColor,
                        0.8,
                      ),
                    ),
                    child: UiUtils.progress(
                      height: 20.rh(context),
                      width: 20.rw(context),
                    ),
                  );
                },
              ),
            ),

            // Active Property Modal
            PositionedDirectional(
              bottom: 8,
              child: cities != null
                  ? const SizedBox.shrink()
                  : activePropertyModal != null && activePropertiesList != null
                  ? SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 180.rh(context),
                      child: PageView.builder(
                        controller: _propertyCardController,
                        itemCount: activePropertiesList!.length,
                        onPageChanged: (index) {
                          unawaited(selectPropertyAt(index));
                        },
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: PropertyHorizontalCard(
                              showLikeButton: false,
                              property: activePropertiesList![index],
                            ),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Padding sellRentLable(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: context.color.borderColor),
              borderRadius: BorderRadius.circular(4),
              color: context.color.secondaryColor,
            ),
            child: Row(
              children: [
                Container(
                  width: 18.rw(context),
                  height: 18.rh(context),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(
                  width: 3,
                ),
                CustomText(
                  'sell'.translate(context),
                  color: context.color.inverseSurface,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: context.color.borderColor),
              borderRadius: BorderRadius.circular(4),
              color: context.color.secondaryColor,
            ),
            child: Row(
              children: [
                Container(
                  width: 18.rw(context),
                  height: 18.rh(context),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.green,
                  ),
                ),
                const SizedBox(
                  width: 3,
                ),
                CustomText(
                  'rent'.translate(context),
                  color: context.color.inverseSurface,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
