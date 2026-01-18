import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/auth_response.dart';
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

    // 스튜디오 주소
    final String? studioAddress = artistProfile?.studioAddress ?? 
        (businessVerification != null && businessVerification.address != null && businessVerification.addressDetail != null
            ? '${businessVerification.address} ${businessVerification.addressDetail}'
            : businessVerification?.address);

    // 작업가능 지역
    final String? availableRegions = businessVerification != null && businessVerification.availableRegions.isNotEmpty
        ? businessVerification.availableRegions.join(', ')
        : null;

    // 작업가능 스타일
    final String? availableStyles = businessVerification != null && businessVerification.mainStyles.isNotEmpty
        ? businessVerification.mainStyles.join(', ')
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 커버 이미지와 프로필 사진이 겹치는 부분
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 커버 이미지
            Container(
              height: 200,
              width: double.infinity,
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
            // 프로필 사진 (커버 이미지와 50% 겹치게)
            Positioned(
              left: 16,
              bottom: -40, // 프로필 사진의 50% (radius 40)가 커버 이미지와 겹치도록
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade800,
                  backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty)
                      ? NetworkImage(ImageUrlHelper.buildGeneralImageUrl(user.profileImage))
                      : null,
                  child: (user.profileImage == null || user.profileImage!.isEmpty)
                      ? Icon(Icons.person, size: 40, color: Colors.grey.shade600)
                      : null,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0, bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 통계 섹션 (가장 위로 배치)
              Row(
                children: [
                  const SizedBox(width: 80), // 프로필 사진 너비만큼 공간 확보
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(context, "게시물", "0"),
                        _buildStatColumn(context, "팔로워", followInfo.followerCount.toString()),
                        _buildStatColumn(context, "팔로잉", followInfo.followingCount.toString()),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              // 사용자 이름
              Text(
                user.username,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              // 자기소개글
              if (artistProfile != null && artistProfile.bio != null && artistProfile.bio!.isNotEmpty)
                Text(
                  artistProfile.bio!,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              const SizedBox(height: 8),
              // 스튜디오 정보 섹션 (사업자회원만)
              if (studioAddress != null || availableRegions != null || availableStyles != null)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (studioAddress != null)
                      _buildInfoIcon(
                        context,
                        icon: FontAwesomeIcons.locationDot,
                        hint: '스튜디오 주소: $studioAddress',
                      ),
                    if (availableRegions != null)
                      _buildInfoIcon(
                        context,
                        icon: FontAwesomeIcons.map,
                        hint: '작업가능 지역: $availableRegions',
                      ),
                    if (availableStyles != null)
                      _buildInfoIcon(
                        context,
                        icon: FontAwesomeIcons.palette,
                        hint: '작업가능 스타일: $availableStyles',
                      ),
                  ],
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
                          ? Icon(Icons.person, size: 30, color: Colors.grey.shade600)
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
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
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
