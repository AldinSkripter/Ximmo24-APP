import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/chat_screen.dart';
import 'package:ebroker/utils/network/network_availability.dart';
import 'package:ebroker/utils/whatsapp_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyContactButtons extends StatelessWidget {
  const PropertyContactButtons({
    required this.property,
    super.key,
  });
  final PropertyModel property;

  bool get _canShowWhatsapp => WhatsappHelper.canShow(
    property.agentProfile?.agentMobile,
    property.agentProfile?.agentCountryCode,
  );

  @override
  Widget build(BuildContext context) {
    final canShowWhatsapp = _canShowWhatsapp;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: context.color.secondaryColor,
        boxShadow: [
          BoxShadow(
            color: context.color.textColorDark.withValues(alpha: 0.12),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      height: 72.rh(context),
      child: Row(
        spacing: 12.rw(context),
        children: <Widget>[
          if (canShowWhatsapp) ...[
            _buildIconButton(
              context,
              AppIcons.callFilled,
              onPressed: _onTapCall,
            ),
            _buildIconButton(
              context,
              AppIcons.chatActive,
              onPressed: () => _onTapChat(context),
            ),
            Expanded(child: _buildWhatsappButton(context)),
          ] else ...[
            _buildButton(
              context,
              'call',
              AppIcons.callFilled,
              onPressed: _onTapCall,
            ),
            _buildButton(
              context,
              'chat',
              AppIcons.chatActive,
              onPressed: () => _onTapChat(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    String icon, {
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48.rh(context),
        width: 48.rh(context),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.tertiaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomImage(
          imageUrl: icon,
          height: 24.rh(context),
          fit: .contain,
          color: context.color.tertiaryColor,
        ),
      ),
    );
  }

  Widget _buildWhatsappButton(BuildContext context) {
    return UiUtils.buildButton(
      context,
      fontSize: context.font.md,
      buttonTitle: 'whatsapp'.translate(context),
      height: 48.rh(context),
      onPressed: _onTapWhatsapp,
      prefixWidget: CustomImage(
        imageUrl: AppIcons.whatsapp,
        height: 24.rh(context),
        fit: .contain,
        color: context.color.buttonColor,
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String title,
    String icon, {
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: UiUtils.buildButton(
        context,
        fontSize: context.font.md,
        buttonTitle: title.translate(context),
        padding: const EdgeInsets.all(2),
        height: 48.rh(context),
        onPressed: onPressed,
        prefixWidget: Container(
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: CustomImage(
            imageUrl: icon,
            width: 18.rw(context),
            height: 18.rh(context),
            color: context.color.buttonColor,
          ),
        ),
      ),
    );
  }

  Future<void> _onTapCall() async {
    final contactNumber = property.customerNumber;

    final url = Uri.parse('tel: $contactNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _onTapWhatsapp() async {
    final mobile = property.agentProfile?.agentMobile;
    final countryCode = property.agentProfile?.agentCountryCode;
    if (mobile == null || countryCode == null) return;
    await WhatsappHelper.open(mobile, countryCode);
  }

  Future<void> _onTapChat(BuildContext context) async {
    await CheckInternet.check(
      onInternet: () async {
        await GuestChecker.check(
          onNotGuest: () async {
            final chatState = context.read<GetChatListCubit>().state;
            if (chatState is GetChatListSuccess) {
              await Navigator.push(
                context,
                CupertinoPageRoute<dynamic>(
                  builder: (context) {
                    return MultiBlocProvider(
                      providers: [
                        BlocProvider(
                          create: (context) => SendMessageCubit(),
                        ),
                        BlocProvider(
                          create: (context) => LoadChatMessagesCubit(),
                        ),
                        BlocProvider(
                          create: (context) => DeleteMessageCubit(),
                        ),
                      ],
                      child: ChatScreenNew(
                        profilePicture: property.customerProfile ?? '',
                        userName: property.customerName ?? '',
                        propertyImage: property.titleImage ?? '',
                        proeprtyTitle: property.title ?? '',
                        userId: property.addedBy.toString(),
                        from: 'property',
                        propertyId: property.id.toString(),
                        isBlockedByMe: property.isBlockedByMe ?? true,
                        isBlockedByUser: property.isBlockedByUser ?? true,
                        isAgent: property.isAgent ?? true,
                        isAgentVerified: property.isAgentVerified ?? true,
                        isUserVerified: property.isUserVerified ?? true,
                        isAdmin: property.isAdmin ?? true,
                      ),
                    );
                  },
                ),
              );
            }
            if (chatState is GetChatListFailed) {
              HelperUtils.showSnackBarMessage(
                context,
                chatState.error.toString(),
                type: .error,
              );
            }
          },
        );
      },
      onNoInternet: () {
        HelperUtils.showSnackBarMessage(
          context,
          'noInternet',
          type: .error,
        );
      },
    );
  }
}
