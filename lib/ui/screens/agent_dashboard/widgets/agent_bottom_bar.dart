// ---------------------------------------------------------------------------
// Bottom navigation bar
// ---------------------------------------------------------------------------

import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/widgets/add_listing_button.dart';
import 'package:ebroker/ui/screens/widgets/premium_bottom_bar.dart';

class AgentBottomBar extends StatelessWidget {
  const AgentBottomBar({
    required this.currentTab,
    required this.onTabTapped,
    required this.addListingController,
    super.key,
  });

  final int currentTab;
  final ValueChanged<int> onTabTapped;
  final AddListingController addListingController;

  @override
  Widget build(BuildContext context) {
    return PremiumBottomBar(
      currentTab: currentTab,
      onTabTapped: onTabTapped,
      addListingController: addListingController,
      firstLabel: 'dashboard'.translate(context),
    );
  }
}
