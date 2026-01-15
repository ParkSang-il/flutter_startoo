import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:starttoo/screens/feed/widgets/feed_item_skeleton.dart';
import 'model/FeedModel.dart';
import 'widgets/feed_item.dart';
import '../../providers/auth_provider.dart';
import '../../models/portfolio_model.dart';
import '../auth/login_or_register_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../search_screen.dart';
import '../create_screen.dart';
import '../activity_screen.dart';
import '../mypage/mypage_screen.dart';
import 'controllers/feed_list_controller.dart';

class FeedListPage extends StatefulWidget {
  const FeedListPage({super.key});

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  int _currentIndex = 0;  // bottom navigation 현재 인덱스
  late FeedListController _feedController;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _feedController = FeedListController(authProvider);
    _feedController.addListener(_onFeedControllerUpdate);
    // 빌드가 완료된 후에 실행되도록 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 0) {
        _feedController.loadFeedList(reset: true);
      }
    });
  }

  @override
  void dispose() {
    _feedController.removeListener(_onFeedControllerUpdate);
    _feedController.dispose();
    super.dispose();
  }

  void _onFeedControllerUpdate() {
    if (mounted) {
      setState(() {});
      
      // 에러 메시지 표시
      if (_feedController.errorMessage != null && _feedController.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_feedController.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        _feedController.clearError();
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // 등록 화면은 모달로 표시
      _showCreateModal();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 전체 화면 사용 가능
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateScreen(),
    ).then((_) {
      // 모달이 닫힌 후 피드 리스트 새로고침
      if (_currentIndex == 0) {
        _feedController.loadFeedList(reset: true);
      }
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildFeedList();
      case 1:
        return const SearchScreen();
      case 2:
        // 등록 화면은 모달로 표시되므로 여기서는 피드 리스트 표시
        return _buildFeedList();
      case 3:
        return const ActivityScreen();
      case 4:
        return const MyPageScreen();
      default:
        return _buildFeedList();
    }
  }

  Widget _buildFeedList() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double contentHeight = 20.0;

    return RefreshIndicator(
      onRefresh: () async {
        await _feedController.loadFeedList(reset: true);
      },
      color: Theme.of(context).colorScheme.onSurface,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        controller: _feedController.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          pinned: false,
          primary: true,
          expandedHeight: statusBarHeight + contentHeight,
          toolbarHeight: contentHeight,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              margin: EdgeInsets.only(top: statusBarHeight),
              height: contentHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/startoo_logo.png',
                        height: contentHeight * 1,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        padding: EdgeInsets.all(0),
                        constraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const LoginOrRegisterScreen()),
                            );
                          }
                        },
                        icon: Icon(Icons.logout,
                            color: Theme.of(context).colorScheme.onSurface, size: 24),
                      ),
                      SizedBox(
                        width: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                          icon: const Icon(Icons.settings),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              // 초기 로딩 중
              if (_feedController.isLoading && index == 0) {
                return const FeedItemSkeleton();
              }
              
              // 로딩 중이 아니고 인덱스가 범위를 벗어나면 빈 위젯
              if (index >= _feedController.portfolios.length) {
                // 추가 로딩 중일 때 로딩 인디케이터 표시
                if (_feedController.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
              
              final portfolio = _feedController.portfolios[index];
              final sortedImages = List<PortfolioImage>.from(portfolio.images)
                ..sort((a, b) => a.imageOrder.compareTo(b.imageOrder));
              final imageUrls = sortedImages
                  .map((img) => img.imageUrl)
                  .toList();
              
              final feed = FeedModel(
                portfolioId: portfolio.id,
                portfolioOwnerId: portfolio.userId,
                username: portfolio.user.username,
                userImage: portfolio.user.profileImage,
                userType: portfolio.user.userType,
                postImage: portfolio.firstImageUrl,
                postImages: imageUrls.isNotEmpty
                    ? imageUrls
                    : [],
                caption: portfolio.description,
                likes: portfolio.likesCount,
                comments: portfolio.commentsCount,
                timeAgo: portfolio.timeAgo,
                businessName: portfolio.business.businessName,
                isLiked: portfolio.isLiked,
              );
              return FeedItem(
                feed: feed,
                onCommentAdded: () {
                  // 댓글 작성 후 해당 포트폴리오만 업데이트
                  _feedController.updatePortfolio(feed.portfolioId);
                },
              );
            },
            childCount: _feedController.isLoading 
                ? 10 
                : _feedController.portfolios.length + (_feedController.isLoadingMore ? 1 : 0),
          ),
        ),
      ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        height: 65,
        child: CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      )
    );
  }
}