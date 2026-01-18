import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'model/artist_profile_response.dart';
import 'widgets/profile_header.dart';
import 'widgets/portfolio_grid.dart';
import 'widgets/sliver_tab_bar_delegate.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  ArtistProfileData? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await authProvider.getArtistProfile();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _profileData = response.data;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isBusinessUser = currentUser?.userType == 2;
    
    // 사업자회원: 스튜디오 이름, 일반회원: 사용자 이름
    final String title = isBusinessUser
        ? (_profileData?.businessVerification?.businessName ?? '스튜디오')
        : (currentUser?.username ?? '마이페이지');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            if (isBusinessUser) ...[
              FaIcon(FontAwesomeIcons.shop),
              const SizedBox(width: 5),
            ],
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.add_box_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.menu,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2, // 탭 개수 (이미지, 영상)
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: ProfileHeader(),
              ),
              SliverPersistentHeader(
                pinned: true, // 상단 고정
                delegate: SliverTabBarDelegate(
                  TabBar(
                    indicatorColor: Theme.of(context).colorScheme.onSurface,
                    labelColor: Theme.of(context).colorScheme.onSurface,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.movie_outlined)),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: const TabBarView(
            children: [
              PortfolioGrid(type: PortfolioGridType.image), // 이미지 탭
              PortfolioGrid(type: PortfolioGridType.video), // 영상 탭
            ],
          ),
        ),
      ),
    );
  }
}

