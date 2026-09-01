import 'package:ebroker/data/cubits/property/fetch_compare_properties_cubit.dart';
import 'package:ebroker/data/cubits/subscription/check_package_cubit.dart';
import 'package:ebroker/data/repositories/check_package.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/home/widgets/sell_rent_label.dart';
import 'package:ebroker/ui/screens/widgets/custom_open_container.dart';
import 'package:ebroker/ui/screens/widgets/like_button_widget.dart';
import 'package:ebroker/ui/screens/widgets/promoted_widget.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:flutter/material.dart';

class PropertyCardBig extends StatefulWidget {
  const PropertyCardBig({
    required this.property,
    required this.isFromCompare,
    required this.isFromGrid,
    this.sourceProperty,
    super.key,
    this.isFirst,
    this.showEndPadding,
    this.showLikeButton,
    this.disableTap,
    this.showFeatured,
    this.heroTag,
  });

  final PropertyModel property;
  final bool isFromCompare;
  final bool isFromGrid;
  final PropertyModel? sourceProperty;
  final bool? isFirst;
  final bool? showEndPadding;
  final bool? showLikeButton;
  final bool? disableTap;
  final bool? showFeatured;
  final String? heroTag;

  @override
  State<PropertyCardBig> createState() => _PropertyCardBigState();
}

class _PropertyCardBigState extends State<PropertyCardBig> {
  bool _isNavigating = false;
  final CheckPackageCubit _checkPackageCubit = CheckPackageCubit();

  @override
  void dispose() {
    unawaited(_checkPackageCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final isFromCompare = widget.isFromCompare;
    final sourceProperty = widget.sourceProperty;
    final showLikeButton = widget.showLikeButton;
    final disableTap = widget.disableTap;
    final showFeatured = widget.showFeatured;
    final resolvedHeroTag = widget.heroTag ?? 'property-hero-${property.id}';

    final price = property.price!.priceFormat(
      enabled: Constant.isNumberWithSuffix,
      context: context,
    );
    final isPremium = property.isPremium ?? false;
    final isPromoted = property.promoted ?? false;
    final isAddedByMe = property.addedBy.toString() == HiveUtils.getUserId();
    final isRent = property.propertyType.toString().toLowerCase() == 'rent';

    return CustomOpenContainer(
      openBuilder: (context, closeContainer) {
        return PropertyDetails.buildWithProviders(
          property: property,
          fromMyProperty: isAddedByMe,
          heroTag: resolvedHeroTag,
        );
      },
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: () async {
            if (_isNavigating) return;
            if (disableTap ?? false) return;

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

            try {
              if (isPremium) {
                await GuestChecker.check(
                  onNotGuest: () async {
                    if (isAddedByMe) {
                      openContainer();
                    } else {
                      final packageAvailable = await _checkPackageCubit
                          .checkAvailability(
                            packageType: PackageType.premiumProperties,
                          );

                      if (_checkPackageCubit.state is CheckPackageFail) {
                        if (context.mounted) {
                          HelperUtils.showSnackBarMessage(
                            context,
                            (_checkPackageCubit.state as CheckPackageFail)
                                .error,
                            type: .error,
                          );
                        }
                        return;
                      }

                      if (packageAvailable) {
                        openContainer();
                      } else {
                        await UiUtils.showBlurredDialoge(
                          context,
                          dialog: const BlurredSubscriptionDialogBox(
                            packageType:
                                SubscriptionPackageType.premiumProperties,
                            isAcceptContainesPush: true,
                          ),
                        );
                      }
                    }
                  },
                );
              } else {
                openContainer();
              }
            } on Exception catch (_) {
              // Property navigation errors are handled by the shared helper flow.
            } finally {
              if (mounted) {
                setState(() {
                  _isNavigating = false;
                });
              }
            }
          },
          child: Container(
            padding: EdgeInsets.all(8.rh(context)),
            width: widget.isFromGrid ? 254.rw(context) : 290.rw(context),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: context.color.secondaryColor,
              border: Border.all(
                color: context.color.borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.color.textColorDark.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: .start,
                  mainAxisSize: .min,
                  children: [
                    Stack(
                      children: [
                        Hero(
                          tag: resolvedHeroTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CustomImage(
                              imageUrl: property.titleImage ?? '',
                              height: widget.isFromGrid
                                  ? 96.rh(context)
                                  : 132.rh(context),
                              width: double.infinity,
                              loadingImageHash: property.lowQualityTitleImage,
                            ),
                          ),
                        ),

                        if (isPromoted || (showFeatured ?? false))
                          PositionedDirectional(
                            start: 10,
                            bottom: 10,
                            child: Hero(
                              tag: '$resolvedHeroTag-promoted',
                              child: const PromotedCard(),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 8.rh(context)),
                    Row(
                      children: [
                        CustomImage(
                          imageUrl: property.category?.image ?? '',
                          color: context.color.textLightColor,
                          width: 18.rw(context),
                          height: 18.rh(context),
                        ),
                        SizedBox(width: 4.rw(context)),
                        Expanded(
                          child: Hero(
                            tag: '$resolvedHeroTag-category',
                            child: Material(
                              type: MaterialType.transparency,
                              child: CustomText(
                                property.category?.translatedName ??
                                    property.category?.category ??
                                    '',
                                fontWeight: .w600,
                                fontSize: context.font.xs,
                                color: context.color.textLightColor,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                        if (isPremium) ...[
                          SizedBox(width: 4.rw(context)),
                          CustomText(
                            'premium'.translate(context),
                            color: Colors.orangeAccent,
                            fontSize: context.font.xxs,
                            fontWeight: .w600,
                          ),
                          SizedBox(width: 4.rw(context)),
                          Hero(
                            tag: '$resolvedHeroTag-premium',
                            child: CustomImage(
                              imageUrl: AppIcons.premium,
                              height: 18.rh(context),
                              width: 18.rw(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 8.rh(context)),
                    Hero(
                      tag: '$resolvedHeroTag-title',
                      child: Material(
                        type: MaterialType.transparency,
                        child: CustomText(
                          property.translatedTitle ?? property.title ?? '',
                          maxLines: 1,
                          fontSize: context.font.md,
                          fontWeight: .w600,
                          color: context.color.textColorDark,
                        ),
                      ),
                    ),
                    if (property.city != '') ...[
                      SizedBox(height: 8.rh(context)),
                      Row(
                        mainAxisSize: .min,
                        children: [
                          CustomImage(
                            imageUrl: AppIcons.location,
                            height: 18.rh(context),
                            width: 18.rw(context),
                            color: context.color.textLightColor,
                          ),
                          SizedBox(width: 5.rw(context)),
                          CustomText(
                            property.city ?? '',
                            maxLines: 1,
                            color: context.color.textLightColor,
                            fontSize: context.font.xs,
                            fontWeight: .w400,
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 8.rh(context)),
                    UiUtils.getDivider(context),
                    SizedBox(height: 8.rh(context)),
                    Row(
                      crossAxisAlignment: .start,
                      children: [
                        Expanded(
                          child: _buildPrice(
                            context,
                            price,
                            isRent,
                            resolvedHeroTag,
                          ),
                        ),
                        SellRentLabel(
                          propertyType: isRent ? 'rent' : 'sell',
                        ),
                      ],
                    ),
                    if (isFromCompare) ...[
                      SizedBox(height: 8.rh(context)),
                      UiUtils.getDivider(context),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: UiUtils.buildButton(
                              context,
                              onPressed: () async {
                                if (disableTap ?? false) return;
                                if (_checkPackageCubit.state
                                    is CheckPackageInProgress) {
                                  return;
                                }
                                try {
                                  if (isPremium) {
                                    await GuestChecker.check(
                                      onNotGuest: () async {
                                        if (isAddedByMe) {
                                          openContainer();
                                        } else {
                                          unawaited(
                                            Widgets.showLoader(context),
                                          );
                                          final packageAvailable =
                                              await _checkPackageCubit
                                                  .checkAvailability(
                                                    packageType: PackageType
                                                        .premiumProperties,
                                                  );
                                          Widgets.hideLoader(context);

                                          if (_checkPackageCubit.state
                                              is CheckPackageFail) {
                                            if (context.mounted) {
                                              HelperUtils.showSnackBarMessage(
                                                context,
                                                (_checkPackageCubit.state
                                                        as CheckPackageFail)
                                                    .error,
                                                type: .error,
                                              );
                                            }
                                            return;
                                          }

                                          if (packageAvailable) {
                                            openContainer();
                                          } else {
                                            await UiUtils.showBlurredDialoge(
                                              context,
                                              dialog:
                                                  const BlurredSubscriptionDialogBox(
                                                    packageType:
                                                        SubscriptionPackageType
                                                            .premiumProperties,
                                                    isAcceptContainesPush: true,
                                                  ),
                                            );
                                          }
                                        }
                                      },
                                    );
                                  } else {
                                    openContainer();
                                  }
                                } on Exception catch (_) {
                                  Widgets.hideLoader(context);
                                }
                              },
                              buttonTitle: 'viewProperty'.translate(context),
                              buttonColor: context.color.secondaryColor,
                              border: BorderSide(
                                color: context.color.tertiaryColor,
                              ),
                              textColor: context.color.tertiaryColor,
                              fontSize: context.font.sm,
                              height: 44.rh(context),
                            ),
                          ),
                          SizedBox(
                            width: 8.rw(context),
                          ),
                          Expanded(
                            child: UiUtils.buildButton(
                              context,
                              onPressed: () async {
                                Future<void> runCompare() async {
                                  try {
                                    unawaited(Widgets.showLoader(context));

                                    // Get a property to compare with
                                    final targetPropertyId = property.id!;

                                    // Fetch comparison data using the cubit
                                    final comparePropertiesCubit =
                                        FetchComparePropertiesCubit();
                                    await comparePropertiesCubit
                                        .fetchCompareProperties(
                                          sourcePropertyId: sourceProperty!.id!,
                                          targetPropertyId: targetPropertyId,
                                        );

                                    final state = comparePropertiesCubit.state;

                                    if (state
                                        is FetchComparePropertiesSuccess) {
                                      Widgets.hideLoder(context);
                                      final sourcePropertyData = sourceProperty;

                                      final targetPropertyData = property;

                                      // Navigate to compare property screen with the fetched data
                                      await Navigator.pushNamed(
                                        context,
                                        Routes.comparePropertiesScreen,
                                        arguments: {
                                          'comparisionData':
                                              state.comparisionData,
                                          'category': property.category,
                                          'isSourcePremium':
                                              sourcePropertyData.isPremium ??
                                              sourcePropertyData
                                                      .allPropData?['is_premium']
                                                  as bool?,
                                          'isTargetPremium':
                                              targetPropertyData.isPremium ??
                                              targetPropertyData
                                                      .allPropData?['is_premium']
                                                  as bool? ??
                                              false,
                                          'isSourcePromoted':
                                              sourcePropertyData.promoted ??
                                              false,
                                          'isTargetPromoted':
                                              targetPropertyData.promoted ??
                                              false,
                                        },
                                      );
                                    } else if (state
                                        is FetchComparePropertiesFailure) {
                                      Widgets.hideLoder(context);
                                      await UiUtils.showBlurredDialoge(
                                        context,
                                        dialog:
                                            const BlurredSubscriptionDialogBox(
                                              packageType:
                                                  SubscriptionPackageType
                                                      .premiumProperties,
                                            ),
                                      );
                                    } else {
                                      Widgets.hideLoder(context);
                                      HelperUtils.showSnackBarMessage(
                                        context,
                                        'somethingWentWrong',
                                        type: .error,
                                      );
                                    }
                                  } on Exception catch (e) {
                                    Widgets.hideLoder(context);
                                    HelperUtils.showSnackBarMessage(
                                      context,
                                      e.toString(),
                                      type: .error,
                                    );
                                  } finally {
                                    Widgets.hideLoder(context);
                                  }
                                }

                                if (isPremium) {
                                  await GuestChecker.check(
                                    onNotGuest: runCompare,
                                  );
                                } else {
                                  await runCompare();
                                }
                              },
                              buttonTitle: 'compareProperty'.translate(context),
                              height: 44.rh(context),
                              fontSize: context.font.sm,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (showLikeButton ?? true)
                  PositionedDirectional(
                    end: 4.rw(context),
                    top: 4.rh(context),
                    child: SizedBox(
                      height: 34.rh(context),
                      width: 34.rw(context),
                      child: LikeButtonWidget(
                        propertyId: property.id!,
                        isFavourite: property.isFavourite == '1',
                        backgroundColor: Colors.black26,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrice(
    BuildContext context,
    String price,
    bool isRent,
    String resolvedHeroTag,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Hero(
          tag: '$resolvedHeroTag-price',
          child: Material(
            type: MaterialType.transparency,
            child: CustomText(
              price,
              fontWeight: .w500,
              fontSize: context.font.md,
              maxLines: 1,
              color: context.color.tertiaryColor,
            ),
          ),
        ),
        if (isRent) ...[
          SizedBox(width: 4.rw(context)),
          CustomText(
            '${isRent ? ' /' : ''}${widget.property.rentduration?.toLowerCase().translate(context)}',
            fontWeight: .w500,
            maxLines: 1,
            fontSize: context.font.xxs,
            color: context.color.tertiaryColor,
          ),
        ],
      ],
    );
  }
}
