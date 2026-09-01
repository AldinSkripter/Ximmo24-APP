import 'package:ebroker/data/model/category.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.frontSpacing,
    required this.onTapCategory,
    required this.category,
    super.key,
  });

  final bool? frontSpacing;
  final dynamic Function(Category category) onTapCategory;
  final Category category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: frontSpacing ?? false ? 10.0 : 0,
      ),
      child: GestureDetector(
        onTap: () {
          onTapCategory.call(category);
        },
        child: Container(
          constraints: BoxConstraints(minWidth: 106.rw(context)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            border: Border.all(color: context.color.borderColor),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.color.textColorDark.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.rw(context),
                height: 36.rh(context),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.color.tertiaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomImage(
                  imageUrl: category.image ?? '',
                  color: context.color.tertiaryColor,
                  width: 21.rw(context),
                  height: 21.rh(context),
                ),
              ),
              SizedBox(width: 8.rw(context)),
              CustomText(
                category.translatedName ?? category.category ?? '',
                maxLines: 1,
                fontWeight: .w600,
                fontSize: context.font.xs,
                color: context.color.textColorDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
