import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/image_url_helper.dart';
import '../model/artist_profile_response.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  ArtistProfileData? _profileData;
  UserProfileData? _userProfileData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isBioExpanded = false; // 사업자 소개(인라인 더보기/접기)

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final isBusinessUser = currentUser?.userType == 2;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 같은 엔드포인트 사용 (/auth/artist-profile)
      final response = await authProvider.getArtistProfile();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            if (isBusinessUser) {
              // 사업자회원: ArtistProfileData 사용
              _profileData = response.data;
            } else {
              // 일반회원: UserProfileData로 변환
              final data = response.data!;
              _userProfileData = UserProfileData(
                user: data.user,
                followInfo: data.followInfo,
              );
            }
          } else {
            _errorMessage = response.message.isNotEmpty 
                ? response.message 
                : '프로필 정보를 불러오는데 실패했습니다.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '프로필 정보를 불러오는 중 오류가 발생했습니다.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isBusinessUser = currentUser?.userType == 2;

    if (_isLoading) {
      return _buildShimmer(isBusinessUser: isBusinessUser);
    }

    // 일반회원인 경우
    if (!isBusinessUser) {
      if (_errorMessage != null || _userProfileData == null) {
        return _buildError();
      }
      return _buildGeneralUserProfile(_userProfileData!);
    }

    // 사업자회원인 경우
    if (_errorMessage != null || _profileData == null) {
      return _buildError();
    }

    final user = _profileData!.user;
    final artistProfile = _profileData!.artistProfile;
    final businessVerification = _profileData!.businessVerification;
    final followInfo = _profileData!.followInfo;
    final colorScheme = Theme.of(context).colorScheme;

    // 커버 이미지 URL 처리 (너비 500 파라미터 자동 추가)
    String? coverImageUrl = artistProfile != null 
        ? ImageUrlHelper.buildCoverImageUrl(artistProfile.coverImage)
        : null;
    if (coverImageUrl != null && coverImageUrl.isEmpty) {
      coverImageUrl = null; // 빈 문자열이면 null로 처리하여 플레이스홀더 표시
    }

    // 사업자 정보 (헤더 하단 섹션으로 이동)
    final String? bio = artistProfile?.bio;
    final String? studioAddress = artistProfile?.studioAddress ??
        (businessVerification != null &&
                businessVerification.address != null &&
                businessVerification.addressDetail != null
            ? '${businessVerification.address} ${businessVerification.addressDetail}'
            : businessVerification?.address);

    final List<String> availableRegions = businessVerification?.availableRegions ?? const [];
    final List<String> mainStyles = businessVerification?.mainStyles ?? const [];
    final String? businessName = businessVerification?.businessName;

    final headerHeight = 350.0; // 고정 헤더 높이
    final avatarRadius = 46.0;
    const statsBarHeight = 80.0;

    return Column(
      children: [
        // ===== 헤더(커버+그라데이션+프로필+이름+통계) =====
        SizedBox(
          height: headerHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 커버 이미지
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  image: coverImageUrl != null && coverImageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(coverImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: coverImageUrl == null || coverImageUrl.isEmpty
                    ? Center(
                        child: FaIcon(
                          FontAwesomeIcons.image,
                          size: 60,
                          color: Colors.grey.shade600,
                        ),
                      )
                    : null,
              ),
              // 그라데이션 오버레이 (상단은 투명, 하단은 진하게)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.10),
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
              // 프로필 + 텍스트 (가운데 정렬) - 통계 바는 패딩 영향 받지 않도록 별도 배치
              Transform.translate(
                offset: const Offset(0, -50), // 프로필/이름을 살짝 위로
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    // 통계 바는 Stack 하단에 고정 배치하므로, 내용은 그 위까지만 사용
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, statsBarHeight + 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                      // 프로필 이미지
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1), // 그림자 색상과 투명도
                              spreadRadius: 10,  // 그림자가 퍼지는 범위
                              blurRadius: 5,    // 그림자의 흐림 정도
                              offset: Offset(0, 0), // 그림자의 위치 (x축, y축)
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty)
                              ? NetworkImage(ImageUrlHelper.buildGeneralImageUrl(user.profileImage))
                              : null,
                          child: (user.profileImage == null || user.profileImage!.isEmpty)
                              ? FaIcon(FontAwesomeIcons.user, size: 40, color: Colors.grey.shade600)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // 이름(헤더에는 최소 정보만)
                      Text(
                        user.username,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 2,              // 그림자의 퍼짐 정도
                              offset: Offset(0.3, 0.3),      // 그림자의 위치 (x, y)
                            ),
                          ]
                        ),
                      ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              // 통계 3칸 (가로 전체 배경, 상위 horizontal padding 영향 X)
              Positioned(
                left: 0,
                right: 0,
                bottom: -6, // 통계 영역을 살짝 아래로
                child: Container(
                  height: statsBarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.black.withOpacity(0.35),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildHeaderStat("FRIENDS", "0"), // TODO: 게시물 수 연결 시 교체
                      _buildHeaderStat("FOLLOWING", followInfo.followingCount.toString()),
                      _buildHeaderStat("FOLLOWER", followInfo.followerCount.toString()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ===== 사업자 정보 섹션(헤더 밖) =====
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.store, size: 16, color: colorScheme.onSurface.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(
                      '소개',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 상호명
                if (businessName != null && businessName.trim().isNotEmpty) ...[
                  Text(
                    businessName.trim(),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 소개 (인라인 더보기/접기)
                if (bio != null && bio.trim().isNotEmpty) ...[
                  _buildExpandableBio(
                    bio.trim(),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                ],

                // 주소
                if (studioAddress != null && studioAddress.trim().isNotEmpty) ...[
                  _buildInfoRow(
                    icon: FontAwesomeIcons.locationDot,
                    title: '스튜디오 주소',
                    value: studioAddress.trim(),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                ],

                // 지역
                if (availableRegions.isNotEmpty) ...[
                  _buildChipSection(
                    icon: FontAwesomeIcons.map,
                    title: '작업가능 지역',
                    items: availableRegions,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 12),
                ],

                // 스타일
                if (mainStyles.isNotEmpty) ...[
                  _buildChipSection(
                    icon: FontAwesomeIcons.palette,
                    title: '작업가능 스타일',
                    items: mainStyles,
                    colorScheme: colorScheme,
                  ),
                ],

                const SizedBox(height: 14),
                // 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade700),
                        ),
                        child: Text(
                          '프로필 편집',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade700),
                        ),
                        child: Text(
                          '프로필 공유',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            count,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableBio(String bio, {required ColorScheme colorScheme}) {
    const collapsedMaxLines = 2;
    final textStyle = TextStyle(
      color: colorScheme.onSurface.withOpacity(0.75),
      fontSize: 13,
      height: 1.35,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: bio, style: textStyle),
          maxLines: collapsedMaxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflow = painter.didExceedMaxLines;
        final showToggle = isOverflow;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bio,
              maxLines: _isBioExpanded ? null : collapsedMaxLines,
              overflow: _isBioExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: textStyle,
            ),
            if (showToggle) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isBioExpanded = !_isBioExpanded;
                  });
                },
                child: Text(
                  _isBioExpanded ? '접기' : '더보기',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FaIcon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.8)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipSection({
    required IconData icon,
    required String title,
    required List<String> items,
    required ColorScheme colorScheme,
  }) {
    const maxShow = 8;
    final showItems = items.take(maxShow).toList();
    final moreCount = items.length - showItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.8)),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.65),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in showItems)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (moreCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
                ),
                child: Text(
                  '+$moreCount',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 일반회원 프로필 레이아웃
  Widget _buildGeneralUserProfile(UserProfileData profileData) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = profileData.user;
    final followInfo = profileData.followInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 사진과 닉네임, 팔로우 정보
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 사진 (작게)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade700,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty)
                          ? NetworkImage(ImageUrlHelper.buildGeneralImageUrl(user.profileImage))
                          : null,
                      child: (user.profileImage == null || (user.profileImage?.isEmpty ?? true))
                          ? FaIcon(FontAwesomeIcons.user, size: 30, color: Colors.grey.shade600)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 닉네임과 팔로우 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 닉네임
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user.username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 7),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onTertiary,
                                borderRadius: BorderRadius.all(Radius.circular(4))
                              ),
                              child: Text(
                                '팔로우',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(offset: Offset(1, 1), color: Colors.black54)],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 5),
                        // 팔로우 정보 (게시물, 팔로워, 팔로잉)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildStatColumn(context, "게시물", "0"),
                            const SizedBox(width: 24),
                            _buildStatColumn(context, "팔로워", followInfo.followerCount.toString()),
                            const SizedBox(width: 24),
                            _buildStatColumn(context, "팔로잉", followInfo.followingCount.toString()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 자기소개글 (일반회원은 없을 수도 있음)
              Text(
                '자기소개를 입력해주세요.',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade700),
                      ),
                      child: Text(
                        '프로필 편집',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade700),
                      ),
                      child: Text(
                        '프로필 공유',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer({bool isBusinessUser = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 커버 이미지 스켈레톤
        Shimmer.fromColors(
          baseColor: Colors.grey.shade800,
          highlightColor: Colors.grey.shade700,
          child: Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade800,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 통계 스켈레톤
              Row(
                children: [
                  const SizedBox(width: 80),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) => _buildShimmerStat()),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              // 이름 스켈레톤
              Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade700,
                child: Container(
                  height: 20,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 자기소개글 스켈레톤
              Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade700,
                child: Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade700,
                child: Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 아이콘 스켈레톤 (사업자회원만)
              if (isBusinessUser)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: List.generate(3, (index) => _buildShimmerIcon()),
                ),
              if (isBusinessUser) const SizedBox(height: 15),
              // 버튼 스켈레톤
              Row(
                children: [
                  Expanded(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade800,
                      highlightColor: Colors.grey.shade700,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade800,
                      highlightColor: Colors.grey.shade700,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerStat() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Column(
        children: [
          Container(
            height: 14,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 18,
            width: 30,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerIcon() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.circleExclamation, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '프로필 정보를 불러오는데 실패했습니다.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String count) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoIcon(BuildContext context, {required IconData icon, required String hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hint, style: const TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Tooltip(
        message: hint,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            icon,
            size: 20,
            color: colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
