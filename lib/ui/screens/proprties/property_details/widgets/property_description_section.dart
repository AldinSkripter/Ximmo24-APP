import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/read_more_text.dart';
import 'package:flutter/material.dart';

class PropertyDescriptionSection extends StatelessWidget {
  const PropertyDescriptionSection({
    required this.property,
    super.key,
  });

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.rw(context)),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        border: Border.all(
          color: context.color.borderColor,
        ),
        borderRadius: BorderRadius.circular(22.rw(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.color.brightness == Brightness.dark ? 0.18 : 0.05,
            ),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Container(
                width: 36.rw(context),
                height: 36.rh(context),
                decoration: BoxDecoration(
                  color: context.color.tertiaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11.rw(context)),
                ),
                child: Icon(
                  Icons.notes_rounded,
                  color: context.color.tertiaryColor,
                  size: 20.rw(context),
                ),
              ),
              SizedBox(width: 11.rw(context)),
              Expanded(
                child: CustomText(
                  'aboutThisPropLbl'.translate(context),
                  fontWeight: .w700,
                  fontSize: context.font.md,
                  color: context.color.textColorDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.rh(context)),
          UiUtils.getDivider(context),
          SizedBox(height: 14.rh(context)),
          ReadMoreText(
            text: property.translatedDescription ?? property.description ?? '',
            style: TextStyle(
              fontSize: context.font.xs,
              fontWeight: .w400,
              height: 1.55,
              color: context.color.textColorDark,
            ),
            readMoreButtonStyle: TextStyle(
              color: context.color.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
