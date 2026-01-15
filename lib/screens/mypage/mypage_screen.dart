import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'widgets/profile_header.dart';
import 'widgets/portfolio_grid.dart';
import 'widgets/sliver_tab_bar_delegate.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final username = authProvider.currentUser?.username ?? 'user_nickname';
            return Text(
              username,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            );
          },
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

