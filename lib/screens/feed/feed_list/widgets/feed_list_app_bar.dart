import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../auth/login_or_register_screen.dart';

class FeedListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FeedListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double contentHeight = 20.0;

    return SliverAppBar(
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
                  Image.asset(
                    'assets/images/startoo_logo.png',
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
                          MaterialPageRoute(
                            builder: (context) => const LoginOrRegisterScreen(),
                          ),
                        );
                      }
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.rightFromBracket,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {},
                      icon: const FaIcon(FontAwesomeIcons.gear),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

