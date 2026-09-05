import 'package:ebroker/exports/main_export.dart';
import 'package:ebroker/ui/screens/chat/chat_screen.dart';
import 'package:ebroker/ui/screens/home/widgets/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  static Route<dynamic> route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (context) {
        return const ChatListScreen();
      },
    );
  }

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() async {
      if (_scrollController.isEndReached() && mounted) {
        if (context.read<GetChatListCubit>().hasMoreData()) {
          await context.read<GetChatListCubit>().loadMore();
        }
      }
    });
    if (context.read<GetChatListCubit>().state is! GetChatListSuccess) {
      unawaited(context.read<GetChatListCubit>().fetch(forceRefresh: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        appBar: CustomAppBar(
          title: 'message'.translate(context),
          isFromHome: true,
          showBackButton: false,
        ),
        body: CustomRefreshIndicator(
          onRefresh: () async {
            await context.read<GetChatListCubit>().fetch(forceRefresh: true);
          },
          child: BlocBuilder<GetChatListCubit, GetChatListState>(
            builder: (context, state) {
              if (state is GetChatListFailed) {
                return SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  width: MediaQuery.sizeOf(context).width,
                  child: Center(
                    child: SomethingWentWrong(
                      errorMessage: state.error.toString(),
                    ),
                  ),
                );
              }
              if (state is GetChatListInProgress) {
                return buildChatListShimmer();
              }
              if (state is GetChatListSuccess) {
                if (state.chatedUserList.isEmpty) {
                  return Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: .center,
                      children: [
                        CustomImage(
                          imageUrl: AppIcons.noChatFound,
                          height: MediaQuery.of(context).size.height * 0.35,
                        ),
                        SizedBox(height: 16.rh(context)),
                        CustomText(
                          'noChats'.translate(context),
                          fontWeight: .w600,
                          fontSize: context.font.xl,
                          color: context.color.tertiaryColor,
                        ),
                        SizedBox(height: 16.rh(context)),
                        CustomText(
                          'startConversation'.translate(context),
                          textAlign: .center,
                          fontSize: context.font.md,
                        ),
                        SizedBox(height: 12.rh(context)),
                        UiUtils.buildButton(
                          context,
                          autoWidth: true,
                          outerPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          onPressed: () async {
                            await context.read<GetChatListCubit>().fetch(
                              forceRefresh: true,
                            );
                          },
                          buttonTitle: 'retry'.translate(context),
                          buttonColor: Colors.transparent,
                          height: 48.rh(context),
                          textColor: context.color.tertiaryColor,
                          showElevation: false,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  physics: Constant.scrollPhysics,
                  controller: _scrollController,
                  itemCount: state.chatedUserList.length,
                  padding: EdgeInsetsDirectional.fromSTEB(
                    16.rw(context),
                    16.rh(context),
                    16.rw(context),
                    118.rh(context),
                  ),
                  itemBuilder: (context, index) {
                    final chatedUser = state.chatedUserList[index];

                    return ChatTile(
                      id: chatedUser.userId.toString(),
                      propertyId: chatedUser.propertyId.toString(),
                      profilePicture: chatedUser.profile ?? '',
                      userName: chatedUser.name ?? '',
                      propertyPicture: chatedUser.titleImage ?? '',
                      propertyName:
                          chatedUser.translatedTitle ?? chatedUser.title ?? '',
                      pendingMessageCount:
                          chatedUser.unreadCount?.toString() ?? '',
                      isBlockedByMe: chatedUser.isBlockedByMe ?? false,
                      isBlockedByUser: chatedUser.isBlockedByUser ?? false,
                      isAgent: chatedUser.isAgent ?? false,
                      isAgentVerified: chatedUser.isAgentVerified ?? false,
                      isUserVerified: chatedUser.isUserVerified ?? false,
                      isAdmin: chatedUser.isAdmin ?? false,
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget buildChatListShimmer() {
    return ListView.builder(
      itemCount: 10,
      physics: Constant.scrollPhysics,
      padding: const EdgeInsetsDirectional.all(16),
      itemBuilder: (context, index) {
        return SizedBox(
          height: 74.rh(context),
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
                highlightColor: Theme.of(
                  context,
                ).colorScheme.shimmerHighlightColor,
                child: Stack(
                  children: [
                    SizedBox(width: 58.rw(context), height: 58.rh(context)),
                    Container(
                      width: 42.rw(context),
                      height: 42.rh(context),
                      clipBehavior: .antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        border: Border.all(
                          color: context.color.secondaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: .circle,
                          color: Colors.grey,
                        ),
                        height: 32.rh(context),
                        width: 32.rw(context),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.rw(context)),
              Column(
                crossAxisAlignment: .start,
                mainAxisAlignment: .center,
                children: [
                  CustomShimmer(
                    height: 10,
                    borderRadius: 4,
                    width: 220.rw(context),
                  ),
                  SizedBox(height: 10.rh(context)),
                  CustomShimmer(
                    height: 10,
                    borderRadius: 4,
                    width: 180.rw(context),
                  ),
                  SizedBox(height: 10.rh(context)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => false;
}

class ChatTile extends StatelessWidget {
  const ChatTile({
    required this.profilePicture,
    required this.userName,
    required this.propertyPicture,
    required this.propertyName,
    required this.pendingMessageCount,
    required this.id,
    required this.propertyId,
    required this.isBlockedByMe,
    required this.isBlockedByUser,
    required this.isAgent,
    required this.isAgentVerified,
    required this.isUserVerified,
    required this.isAdmin,
    super.key,
  });

  final String profilePicture;
  final String userName;
  final String propertyPicture;
  final String propertyName;
  final String propertyId;
  final String pendingMessageCount;
  final String id;
  final bool isBlockedByMe;
  final bool isBlockedByUser;
  final bool isAgent;
  final bool isAgentVerified;
  final bool isUserVerified;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          CupertinoPageRoute<dynamic>(
            builder: (context) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => LoadChatMessagesCubit()),
                  BlocProvider(create: (context) => DeleteMessageCubit()),
                ],
                child: Builder(
                  builder: (context) {
                    return ChatScreenNew(
                      profilePicture: profilePicture,
                      proeprtyTitle: propertyName,
                      userId: id,
                      propertyImage: propertyPicture,
                      userName: userName,
                      propertyId: propertyId,
                      isBlockedByMe: isBlockedByMe,
                      isBlockedByUser: isBlockedByUser,
                      isAgent: isAgent,
                      isAgentVerified: isAgentVerified,
                      isUserVerified: isUserVerified,
                      isAdmin: isAdmin,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
      child: AbsorbPointer(
        child: Container(
          margin: EdgeInsetsDirectional.only(bottom: 12.rh(context)),
          height: 90.rh(context),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(22.rw(context)),
            border: Border.all(
              color: context.color.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.09)
                  : context.color.borderColor.withValues(alpha: 0.70),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.color.brightness == Brightness.dark
                      ? 0.18
                      : 0.055,
                ),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: EdgeInsets.all(12.rw(context)),
            child: Row(
              children: [
                Stack(
                  children: [
                    SizedBox(width: 64.rw(context), height: 64.rh(context)),
                    Container(
                      width: 58.rw(context),
                      height: 58.rh(context),
                      clipBehavior: .antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17.rw(context)),
                      ),
                      child: CustomImage(
                        imageUrl: propertyPicture,
                      ),
                    ),
                    PositionedDirectional(
                      end: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: .circle,
                          border: Border.all(
                            color: context.color.secondaryColor,
                            width: 2,
                          ),
                        ),
                        child: profilePicture == ''
                            ? ClipOval(
                                child: ColoredBox(
                                  color: context.color.tertiaryColor,
                                  child: Padding(
                                    padding: .all(12.rw(context)),
                                    child: CustomImage(
                                      imageUrl: appSettings.placeholderLogo!,
                                    ),
                                  ),
                                ),
                              )
                            : ClipOval(
                                child: CustomImage(
                                  imageUrl: profilePicture,
                                  width: 32,
                                  height: 32,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 13.rw(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Expanded(
                        child: CustomText(
                          userName,
                          maxLines: 1,
                          fontWeight: FontWeight.w700,
                          fontSize: context.font.md,
                          color: context.color.textColorDark,
                        ),
                      ),
                      SizedBox(height: 4.rh(context)),
                      Flexible(
                        child: CustomText(
                          propertyName,
                          maxLines: 1,
                          color: context.color.textColorDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isBlockedByMe || isBlockedByUser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: CustomText(
                      'blocked'.translate(context),
                      color: Colors.red,
                      fontSize: context.font.xxs,
                      fontWeight: .w600,
                    ),
                  )
                else if (pendingMessageCount != '0')
                  Container(
                    width: 28.rw(context),
                    height: 28.rh(context),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.color.tertiaryColor,
                      shape: .circle,
                    ),
                    child: CustomText(
                      pendingMessageCount,
                      color: context.color.buttonColor,
                      fontWeight: .bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
