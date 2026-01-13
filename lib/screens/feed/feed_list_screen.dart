import 'package:flutter/material.dart';
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
import '../profile_screen.dart';

class FeedListPage extends StatefulWidget {
  const FeedListPage({super.key});

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  bool _isLoading = true;  // 로딩 상태
  List<Portfolio> _portfolios = [];  // 포트폴리오 리스트
  int _currentIndex = 0;  // bottom navigation 현재 인덱스

  @override
  void initState() {
    super.initState();
    // 빌드가 완료된 후에 실행되도록 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 0) {
        _loadFeedList();
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildFeedList();
      case 1:
        return const SearchScreen();
      case 2:
        return const CreateScreen();
      case 3:
        return const ActivityScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildFeedList();
    }
  }

  Widget _buildFeedList() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double contentHeight = 20.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
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
              if (_isLoading) {
                return const FeedItemSkeleton();
              } else {
                if (index >= _portfolios.length) {
                  return const SizedBox.shrink();
                }
                final portfolio = _portfolios[index];
                final sortedImages = List<PortfolioImage>.from(portfolio.images)
                  ..sort((a, b) => a.imageOrder.compareTo(b.imageOrder));
                final imageUrls = sortedImages
                    .map((img) => img.imageUrl)
                    .toList();
                
                final feed = FeedModel(
                  username: portfolio.user.username,
                  userImage: portfolio.user.profileImage.isNotEmpty
                      ? portfolio.user.profileImage
                      : 'https://via.placeholder.com/200',
                  userType: portfolio.user.userType,
                  postImage: portfolio.firstImageUrl.isNotEmpty
                      ? portfolio.firstImageUrl
                      : 'https://via.placeholder.com/600',
                  postImages: imageUrls.isNotEmpty
                      ? imageUrls
                      : ['https://via.placeholder.com/600'],
                  caption: portfolio.description,
                  likes: portfolio.likesCount,
                  timeAgo: portfolio.timeAgo,
                  businessName: portfolio.business.businessName
                );
                return FeedItem(feed: feed);
              }
            },
            childCount: _isLoading ? 10 : _portfolios.length,
          ),
        ),
      ],
    );
  }

  // 피드 리스트 로드
  Future<void> _loadFeedList() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.getFeedList();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _portfolios = response.data!.portfolios;
        } else {
          // 에러 발생 시 빈 리스트
          _portfolios = [];
          if (response.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    }
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