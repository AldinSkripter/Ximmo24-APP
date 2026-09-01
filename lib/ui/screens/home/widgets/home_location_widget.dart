import 'package:ebroker/app/app.dart';
import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/cubits/fetch_properties_by_cities_cubit.dart';
import 'package:ebroker/data/cubits/property/home_infinityscroll_cubit.dart';
import 'package:ebroker/settings.dart';
import 'package:ebroker/ui/screens/home/home_sections.dart';
import 'package:ebroker/utils/active_role_manager.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/hive_keys.dart';
import 'package:ebroker/utils/hive_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';

class HomeLocationWidget extends StatefulWidget {
  const HomeLocationWidget({super.key});

  @override
  State<HomeLocationWidget> createState() => _HomeLocationWidgetState();
}

class _HomeLocationWidgetState extends State<HomeLocationWidget> {
  String city = '';
  String state = '';
  String country = '';
  late Box<dynamic> homeLocationBox;
  late VoidCallback listener;
  double localLatitude = 0;
  double localLongitude = 0;

  @override
  void initState() {
    super.initState();
    homeLocationBox = Hive.box(HiveKeys.homeLocationBox);
    listener = () {
      if (mounted) {
        setState(() {
          city = HiveUtils.getHomeCityName().toString().trim();
          state = HiveUtils.getHomeStateName().toString().trim();
          country = HiveUtils.getHomeCountryName().toString().trim();
        });
      }
    };
    homeLocationBox
        .listenable(
          keys: [HiveKeys.city, HiveKeys.stateKey, HiveKeys.countryKey],
        )
        .addListener(listener);
  }

  @override
  void dispose() {
    homeLocationBox
        .listenable(
          keys: [HiveKeys.city, HiveKeys.stateKey, HiveKeys.countryKey],
        )
        .removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeLogo = context.color.brightness == .dark
        ? appSettings.darkModeLogo ?? ''
        : appSettings.appHomeScreen ?? '';
    city = HiveUtils.getHomeCityName().toString().trim();
    state = HiveUtils.getHomeStateName().toString().trim();
    country = HiveUtils.getHomeCountryName().toString().trim();

    return GestureDetector(
      onTap: () async {
        FocusManager.instance.primaryFocus?.unfocus();

        if (Hive.box<dynamic>(
          HiveKeys.userDetailsBox,
        ).get('latitude').toString().isNotEmpty) {
          final dynamic latitudeValue =
              Hive.box<dynamic>(HiveKeys.userDetailsBox).get('latitude') ?? '0';
          localLatitude = double.tryParse(latitudeValue.toString()) ?? 0.0;
        }
        if (Hive.box<dynamic>(
          HiveKeys.userDetailsBox,
        ).get('longitude').toString().isNotEmpty) {
          final dynamic longitudeValue =
              Hive.box<dynamic>(HiveKeys.userDetailsBox).get('longitude') ??
              '0';
          localLongitude = double.tryParse(longitudeValue.toString()) ?? 0.0;
        }

        final placeMark =
            await Navigator.pushNamed(
                  context,
                  Routes.chooseLocaitonMap,
                  arguments: {
                    'from': 'home_location',
                  },
                )
                as Map?;

        // Only update location if user pressed Apply (returned data)
        // If user pressed back, placeMark will be null and we skip the update
        if (placeMark != null) {
          try {
            final latlng =
                placeMark['latlng'] as LatLng? ??
                LatLng(
                  double.parse(AppSettings.latitude),
                  double.parse(AppSettings.longitude),
                );
            final place = placeMark['place'] as Placemark? ?? const Placemark();
            final radius =
                placeMark['radius']?.toString() ?? AppSettings.minRadius;

            await HiveUtils.setHomeLocation(
              city: place.locality ?? '',
              state: place.administrativeArea ?? '',
              latitude: latlng.latitude.toString(),
              longitude: latlng.longitude.toString(),
              country: place.country ?? '',
              placeId: place.postalCode ?? '',
              radius: radius,
            );

            // Refresh all home screen APIs with updated location
            if (mounted && !ActiveRoleManager.isAgent) {
              await HomeSections.fetchAllHomeSections(
                context,
                forceRefresh: true,
              );
              await context.read<FetchPropertiesByCitiesCubit>().fetch();
              await context.read<HomePageInfinityScrollCubit>().fetch();
            }
          } on Exception catch (_) {}
        }
      },
      child: Row(
        mainAxisSize: .min,
        children: [
          Container(
            width: 44.rw(context),
            height: 44.rh(context),
            padding: const EdgeInsets.all(5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.color.borderColor),
              boxShadow: [
                BoxShadow(
                  color: context.color.textColorDark.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomImage(
              fit: .contain,
              imageUrl: homeLogo,
              width: 34.rw(context),
              height: 34.rh(context),
            ),
          ),
          SizedBox(width: 10.rw(context)),
          ValueListenableBuilder(
              valueListenable: homeLocationBox.listenable(),
              builder: (context, value, child) {
                final currentCity = HiveUtils.getHomeCityName()
                    .toString()
                    .trim();
                final currentState = HiveUtils.getHomeStateName()
                    .toString()
                    .trim();
                final currentCountry = HiveUtils.getHomeCountryName()
                    .toString()
                    .trim();

                final locationList =
                    <String>[currentCity, currentState, currentCountry]
                      ..removeWhere((element) {
                        return element.isEmpty ||
                            element == 'null' ||
                            element == '';
                      });
                final joinedLocation = locationList.join(', ');
                final locationText = joinedLocation.isNotEmpty
                    ? joinedLocation
                    : 'selectLocation'.translate(context);

                return Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    CustomText(
                      'locationLbl'.translate(context),
                      fontSize: context.font.xxs,
                      fontWeight: .w500,
                      color: context.color.textLightColor,
                    ),
                    SizedBox(height: 2.rh(context)),
                    Row(
                      mainAxisSize: .min,
                      children: [
                        SizedBox(
                          width: 138.rw(context),
                          child: CustomText(
                            locationText,
                            maxLines: 1,
                            fontWeight: .w700,
                            fontSize: context.font.sm,
                            color: context.color.textColorDark,
                          ),
                        ),
                        SizedBox(width: 4.rw(context)),
                        Container(
                          width: 22.rw(context),
                          height: 22.rh(context),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.color.tertiaryColor.withValues(
                              alpha: 0.10,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: CustomImage(
                            imageUrl: AppIcons.downArrow,
                            height: 13.rh(context),
                            width: 13.rw(context),
                            color: context.color.tertiaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
