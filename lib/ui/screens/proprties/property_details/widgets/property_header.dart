import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/utils/price_format.dart';
import 'package:flutter/material.dart';

class PropertyHeader extends StatelessWidget {
  const PropertyHeader({
    required this.property,
    super.key,
    this.heroTag,
  });

  final PropertyModel property;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16.rh(context)),
      padding: EdgeInsets.all(18.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(24.rw(context)),
        border: Border.all(
          color: context.color.brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.10)
              : context.color.borderColor.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.color.brightness == Brightness.dark ? 0.22 : 0.07,
            ),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          _buildCategoryAndType(context),
          SizedBox(height: 14.rh(context)),
          _buildTitleAndDate(context),
          SizedBox(height: 12.rh(context)),
          _buildPrice(context),
        ],
      ),
    );
  }

  Widget _buildCategoryAndType(BuildContext context) {
    final statusColor =
        (property.propertyType.toString().toLowerCase() == 'sell' ||
            property.propertyType.toString().toLowerCase() == 'sold')
        ? Colors.blue
        : Colors.amber;
    return Row(
      children: [
        Container(
          width: 38.rw(context),
          height: 38.rh(context),
          padding: EdgeInsets.all(8.rw(context)),
          decoration: BoxDecoration(
            color: context.color.tertiaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12.rw(context)),
          ),
          child: CustomImage(
            imageUrl: property.category?.image ?? '',
            color: context.color.tertiaryColor,
          ),
        ),
        SizedBox(width: 10.rw(context)),
        Expanded(
          child: heroTag != null
              ? Hero(
                  tag: '$heroTag-category',
                  child: Material(
                    type: MaterialType.transparency,
                    child: CustomText(
                      property.category?.translatedName ??
                          property.category?.category ??
                          '',
                      fontWeight: .w500,
                      fontSize: context.font.sm,
                      color: context.color.textColorDark,
                    ),
                  ),
                )
              : CustomText(
                  property.category?.translatedName ??
                      property.category?.category ??
                      '',
                  fontWeight: .w500,
                  fontSize: context.font.sm,
                  color: context.color.textColorDark,
                ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.rw(context),
            vertical: 7.rh(context),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: statusColor.withValues(alpha: 0.1),
          ),
          child: Center(
            child: CustomText(
              property.propertyType.toString().toLowerCase().translate(
                context,
              ),
              fontWeight: .w600,
              fontSize: context.font.sm,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndDate(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Expanded(
          child: heroTag != null
              ? Hero(
                  tag: '$heroTag-title',
                  child: Material(
                    type: MaterialType.transparency,
                    child: CustomText(
                      property.translatedTitle ??
                          property.title?.firstUpperCase() ??
                          '',
                      fontWeight: .w800,
                      fontSize: context.font.lg,
                      color: context.color.textColorDark,
                    ),
                  ),
                )
              : CustomText(
                  property.translatedTitle ??
                      property.title?.firstUpperCase() ??
                      '',
                  fontWeight: .w800,
                  fontSize: context.font.lg,
                  color: context.color.textColorDark,
                ),
        ),
        CustomText(
          property.postCreated ?? '',
          fontSize: context.font.xs,
          fontWeight: .w500,
          color: context.color.textColorDark,
        ),
      ],
    );
  }

  Widget _buildPrice(BuildContext context) {
    var priceText = (property.price ?? '0').priceFormat(
      enabled: Constant.isNumberWithSuffix,
      context: context,
    );

    if (property.propertyType.toString().toLowerCase() == 'rent' &&
        property.rentduration != '' &&
        property.rentduration != null) {
      priceText =
          '$priceText / ${(property.rentduration ?? '').toLowerCase().translate(context)}';
    }

    return Row(
      children: [
        if (heroTag != null)
          Hero(
            tag: '$heroTag-price',
            child: Material(
              type: MaterialType.transparency,
              child: CustomText(
                priceText,
                fontWeight: .w700,
                fontSize: context.font.xl,
                color: context.color.tertiaryColor,
              ),
            ),
          )
        else
          CustomText(
            priceText,
            fontWeight: .w700,
            fontSize: context.font.xl,
            color: context.color.tertiaryColor,
          ),
        if (Constant.isNumberWithSuffix &&
            property.propertyType.toString().toLowerCase() != 'rent') ...[
          SizedBox(width: 5.rw(context)),
          CustomText(
            '(${(property.price ?? '0').priceFormat(context: context, enabled: false)})',
            fontWeight: .w500,
            fontSize: context.font.sm,
            color: context.color.tertiaryColor,
          ),
        ],
      ],
    );
  }
}
