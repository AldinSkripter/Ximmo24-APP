import 'package:ebroker/data/model/agent/agent_model.dart';
import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/agent_mode/cards/agent_card.dart';
import 'package:ebroker/ui/screens/home/widgets/header_card.dart';

class AgentsSection extends StatelessWidget {
  const AgentsSection({
    required this.title,
    required this.agents,
    super.key,
  });

  final String title;
  final List<AgentModel> agents;

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) return const SliverToBoxAdapter();
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: .start,
        children: [
          TitleHeader(
            title: title,
            enableShowAll: agents.length > 1,
            onSeeAll: () async {
              await Navigator.pushNamed(
                context,
                Routes.agentListScreen,
                arguments: {'title': title},
              );
            },
          ),
          SizedBox(
            height: 258.rh(context),
            child: ListView.separated(
              separatorBuilder: (context, index) =>
                  SizedBox(width: 8.rw(context)),
              itemCount: agents.length < 5 ? agents.length : 5,
              physics: Constant.scrollPhysics,
              padding: EdgeInsets.symmetric(horizontal: 18.rw(context)),
              scrollDirection: .horizontal,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final agent = agents[index];
                return AgentCard(
                  agent: agent,
                  propertyCount: agent.propertyCount,
                  name: agent.name,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
