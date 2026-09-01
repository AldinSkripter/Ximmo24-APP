import 'package:ebroker/app/routes.dart';
import 'package:ebroker/data/cubits/fetch_home_sections_data_cubit.dart';
import 'package:ebroker/ui/screens/widgets/custom_shimmer.dart';
import 'package:ebroker/utils/app_icons.dart';
import 'package:ebroker/utils/custom_image.dart';
import 'package:ebroker/utils/custom_text.dart';
import 'package:ebroker/utils/extensions/extensions.dart';
import 'package:ebroker/utils/helper_utils.dart';
import 'package:ebroker/utils/responsive_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchHomeSectionsDataCubit, FetchHomeSectionsDataState>(
      builder: (context, state) {
        if (state is FetchHomeSectionsDataLoading ||
            state is FetchHomeSectionsDataInitial) {
          return CustomShimmer(
            height: 48.rh(context),
            width: context.screenWidth,
            margin: EdgeInsets.symmetric(horizontal: 16.rh(context)),
          );
        }
        if (state is FetchHomeSectionsDataSuccess &&
            !state.data.searchSection) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
          child: Container(
            height: 58.rh(context),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.color.borderColor),
              boxShadow: [
                BoxShadow(
                  color: context.color.textColorDark.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        Routes.searchScreenRoute,
                        arguments: {'autoFocus': true},
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 42.rw(context),
                          height: 42.rh(context),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.color.tertiaryColor.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: CustomImage(
                            imageUrl: AppIcons.search,
                            width: 21.rw(context),
                            height: 21.rh(context),
                            color: context.color.tertiaryColor,
                          ),
                        ),
                        SizedBox(width: 12.rw(context)),
                        Expanded(
                          child: CustomText(
                            'searchHintLbl'.translate(context),
                            maxLines: 1,
                            fontSize: context.font.sm,
                            color: context.color.textLightColor,
                            fontWeight: .w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.rw(context)),
                GestureDetector(
                  onTap: () async {
                    final hasInternet = await HelperUtils.checkInternet();
                    if (!hasInternet) {
                      return HelperUtils.showSnackBarMessage(
                        context,
                        'noInternet',
                        type: .error,
                      );
                    }
                    await Navigator.pushNamed(
                      context,
                      Routes.propertyMapScreen,
                    );
                  },
                  child: Container(
                    width: 46.rw(context),
                    height: 46.rh(context),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.color.tertiaryColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: context.color.tertiaryColor.withValues(
                            alpha: 0.24,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CustomImage(
                      imageUrl: AppIcons.propertyMap,
                      color: context.color.buttonColor,
                      width: 23.rw(context),
                      height: 23.rh(context),
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

}
