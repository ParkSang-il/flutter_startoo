import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'phone_input_screen.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _agreeAll = false;
  bool _agreeTerms = false; // 이용약관 (필수)
  bool _agreePrivacy = false; // 개인정보 처리방침 (필수)
  bool _agreeMarketing = false; // 마케팅 정보 수신 (선택)

  void _onAgreeAllChanged(bool? value) {
    if (value == null) return;
    setState(() {
      _agreeAll = value;
      _agreeTerms = value;
      _agreePrivacy = value;
      _agreeMarketing = value;
    });
  }

  void _onAgreeTermsChanged(bool? value) {
    if (value == null) return;
    setState(() {
      _agreeTerms = value;
      _updateAgreeAll();
    });
  }

  void _onAgreePrivacyChanged(bool? value) {
    if (value == null) return;
    setState(() {
      _agreePrivacy = value;
      _updateAgreeAll();
    });
  }

  void _onAgreeMarketingChanged(bool? value) {
    if (value == null) return;
    setState(() {
      _agreeMarketing = value;
      _updateAgreeAll();
    });
  }

  void _updateAgreeAll() {
    _agreeAll = _agreeTerms && _agreePrivacy && _agreeMarketing;
  }

  bool get _canProceed => _agreeTerms && _agreePrivacy;

  void _onNext() {
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 약관에 동의해주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 약관 동의 완료 후 휴대폰 입력 화면으로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PhoneInputScreen(isRegister: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 스크롤 가능한 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // 타이틀
                    Text(
                      '약관 동의',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '서비스 이용을 위해 약관에 동의해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 전체 동의
                    Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _agreeAll
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _agreeAll,
                            onChanged: _onAgreeAllChanged,
                            activeColor: Theme.of(context).colorScheme.primary
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '전체 동의',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 이용약관 (필수)
                    _buildAgreementItem(
                      title: '이용약관',
                      isRequired: true,
                      isAgreed: _agreeTerms,
                      onChanged: _onAgreeTermsChanged,
                      onViewDetail: () {
                        _showTermsDetail('이용약관', _getTermsContent());
                      },
                    ),
                    const SizedBox(height: 16),
                    // 개인정보 처리방침 (필수)
                    _buildAgreementItem(
                      title: '개인정보 처리방침',
                      isRequired: true,
                      isAgreed: _agreePrivacy,
                      onChanged: _onAgreePrivacyChanged,
                      onViewDetail: () {
                        _showTermsDetail('개인정보 처리방침', _getPrivacyContent());
                      },
                    ),
                    const SizedBox(height: 16),
                    // 마케팅 정보 수신 (선택)
                    _buildAgreementItem(
                      title: '마케팅 정보 수신',
                      isRequired: false,
                      isAgreed: _agreeMarketing,
                      onChanged: _onAgreeMarketingChanged,
                      onViewDetail: () {
                        _showTermsDetail('마케팅 정보 수신', _getMarketingContent());
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // 하단 고정 버튼 영역
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 25),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canProceed ? _onNext : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                    child: const Text(
                      '다음',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            blurRadius: 1,              // 그림자의 퍼짐 정도
                            color: Colors.black87, // 그림자 색상
                            offset: Offset(0.3, 0.3),      // 그림자의 위치 (x, y)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementItem({
    required String title,
    required bool isRequired,
    required bool isAgreed,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onViewDetail,
  }) {
    return Row(
      children: [
        Checkbox(
          value: isAgreed,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          isRequired ? '(필수)' : '(선택)',
          style: TextStyle(
            fontSize: 14,
            color: isRequired
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onViewDetail,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '보기',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  void _showTermsDetail(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade800,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.xmark,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 내용
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTermsContent() {
    return '''제1조 (목적)
이 약관은 스타투(이하 "회사")가 제공하는 서비스의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"란 회사가 제공하는 타투 관련 정보 및 커뮤니티 서비스를 의미합니다.
2. "이용자"란 본 약관에 동의하고 회사가 제공하는 서비스를 이용하는 회원 및 비회원을 의미합니다.
3. "회원"이란 회사에 개인정보를 제공하여 회원등록을 한 자로서, 회사의 정보를 지속적으로 제공받으며 회사가 제공하는 서비스를 계속적으로 이용할 수 있는 자를 의미합니다.

제3조 (약관의 게시와 개정)
1. 회사는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.
2. 회사는 필요한 경우 관련 법령을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.
3. 회사가 약관을 개정할 경우에는 적용일자 및 개정사유를 명시하여 현행약관과 함께 서비스의 초기화면에 그 적용일자 7일 이전부터 적용일자 전일까지 공지합니다.

제4조 (서비스의 제공 및 변경)
1. 회사는 다음과 같은 서비스를 제공합니다:
   - 타투 관련 정보 제공
   - 타투이스트 및 고객 간 매칭 서비스
   - 커뮤니티 서비스
   - 기타 회사가 추가 개발하거나 제휴계약 등을 통해 회원에게 제공하는 일체의 서비스

제5조 (서비스의 중단)
1. 회사는 컴퓨터 등 정보통신설비의 보수점검, 교체 및 고장, 통신의 두절 등의 사유가 발생한 경우에는 서비스의 제공을 일시적으로 중단할 수 있습니다.
2. 회사는 제1항의 사유로 서비스의 제공이 일시적으로 중단됨으로 인하여 이용자 또는 제3자가 입은 손해에 대하여 배상합니다. 단, 회사가 고의 또는 과실이 없음을 입증하는 경우에는 그러하지 아니합니다.

제6조 (회원가입)
1. 이용자는 회사가 정한 가입 양식에 따라 회원정보를 기입한 후 이 약관에 동의한다는 의사표시를 함으로서 회원가입을 신청합니다.
2. 회사는 제1항과 같이 회원가입을 신청한 이용자 중 다음 각 호에 해당하지 않는 한 회원으로 등록합니다:
   - 가입신청자가 이 약관에 의하여 이전에 회원자격을 상실한 적이 있는 경우
   - 등록 내용에 허위, 기재누락, 오기가 있는 경우
   - 기타 회원으로 등록하는 것이 회사의 기술상 현저히 지장이 있다고 판단되는 경우

제7조 (회원정보의 변경)
회원은 개인정보관리화면을 통하여 언제든지 본인의 개인정보를 열람하고 수정할 수 있습니다. 다만, 서비스 관리를 위해 필요한 실명, 아이디 등은 수정이 불가능합니다.

제8조 (개인정보보호)
회사는 이용자의 개인정보 수집시 서비스제공을 위하여 필요한 범위에서 최소한의 개인정보를 수집합니다.

제9조 (이용자의 의무)
1. 이용자는 다음 행위를 하여서는 안 됩니다:
   - 신청 또는 변경시 허위내용의 등록
   - 타인의 정보 도용
   - 회사가 게시한 정보의 변경
   - 회사가 정한 정보 이외의 정보(컴퓨터 프로그램 등) 등의 송신 또는 게시
   - 회사와 기타 제3자의 저작권 등 지적재산권에 대한 침해
   - 회사 및 기타 제3자의 명예를 손상시키거나 업무를 방해하는 행위
   - 외설 또는 폭력적인 메시지, 화상, 음성, 기타 공서양속에 반하는 정보를 공개 또는 게시하는 행위

제10조 (저작권의 귀속 및 이용제한)
1. 회사가 작성한 저작물에 대한 저작권 기타 지적재산권은 회사에 귀속합니다.
2. 이용자는 회사를 이용함으로써 얻은 정보 중 회사에게 지적재산권이 귀속된 정보를 회사의 사전 승낙 없이 복제, 송신, 출판, 배포, 방송 기타 방법에 의하여 영리목적으로 이용하거나 제3자에게 이용하게 하여서는 안됩니다.

제11조 (면책조항)
1. 회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다.
2. 회사는 회원의 귀책사유로 인한 서비스 이용의 장애에 대하여는 책임을 지지 않습니다.

제12조 (준거법 및 관할법원)
1. 회사와 이용자 간에 발생한 전자상거래 분쟁에 관한 소송은 제소 당시의 이용자의 주소에 의하고, 주소가 없는 경우에는 거소를 관할하는 지방법원의 전속관할로 합니다.
2. 회사와 이용자 간에 발생한 전자상거래 분쟁에 관한 소송에는 대한민국법을 적용합니다.''';
  }

  String _getPrivacyContent() {
    return '''제1조 (개인정보의 처리목적)
스타투(이하 "회사")는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 개인정보 보호법 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.

1. 회원 가입 및 관리
   - 회원 가입의사 확인, 회원제 서비스 제공에 따른 본인 식별·인증, 회원자격 유지·관리, 서비스 부정이용 방지, 각종 고지·통지, 고충처리 목적

2. 재화 또는 서비스 제공
   - 서비스 제공, 콘텐츠 제공, 맞춤 서비스 제공, 본인인증, 요금결제·정산 목적

3. 마케팅 및 광고에의 활용
   - 신규 서비스(제품) 개발 및 맞춤 서비스 제공, 이벤트 및 광고성 정보 제공 및 참여기회 제공, 인구통계학적 특성에 따른 서비스 제공 및 광고 게재 목적

제2조 (개인정보의 처리 및 보유기간)
1. 회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.
2. 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:
   - 회원 가입 및 관리: 회원 탈퇴 시까지 (단, 관계 법령 위반에 따른 수사·조사 등이 진행중인 경우에는 해당 수사·조사 종료 시까지)
   - 재화 또는 서비스 제공: 재화·서비스 공급완료 및 요금결제·정산 완료 시까지
   - 마케팅 및 광고에의 활용: 회원 탈퇴 시까지 또는 동의 철회 시까지

제3조 (처리하는 개인정보의 항목)
회사는 다음의 개인정보 항목을 처리하고 있습니다:

1. 회원 가입 및 관리
   - 필수항목: 휴대전화번호, 비밀번호, 닉네임
   - 선택항목: 이메일주소, 프로필 사진

2. 재화 또는 서비스 제공
   - 필수항목: 휴대전화번호, 결제정보
   - 선택항목: 배송지 정보

3. 인터넷 서비스 이용 과정에서 자동 수집되는 정보
   - IP주소, 쿠키, MAC주소, 서비스 이용 기록, 방문 기록, 불량 이용 기록 등

제4조 (개인정보의 제3자 제공)
회사는 정보주체의 개인정보를 제1조(개인정보의 처리목적)에서 명시한 범위 내에서만 처리하며, 정보주체의 동의, 법률의 특별한 규정 등 개인정보 보호법 제17조 및 제18조에 해당하는 경우에만 개인정보를 제3자에게 제공합니다.

제5조 (개인정보처리의 위탁)
1. 회사는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁하고 있습니다:
   - 위탁업체: (주)○○○
   - 위탁업무 내용: 서비스 제공 및 고객 지원
   - 위탁기간: 회원 탈퇴 시까지

2. 회사는 위탁계약 체결 시 개인정보 보호법 제26조에 따라 위탁업무 수행목적 외 개인정보 처리금지, 기술적·관리적 보호조치, 재위탁 제한, 수탁자에 대한 관리·감독, 손해배상 등에 관한 사항을 계약서 등 문서에 명시하고, 수탁자가 개인정보를 안전하게 처리하는지를 감독하고 있습니다.

제6조 (정보주체의 권리·의무 및 그 행사방법)
1. 정보주체는 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다:
   - 개인정보 처리정지 요구권
   - 개인정보 열람요구권
   - 개인정보 정정·삭제요구권
   - 개인정보 처리정지 요구권

2. 제1항에 따른 권리 행사는 회사에 대해 서면, 전자우편, 모사전송(FAX) 등을 통하여 하실 수 있으며 회사는 이에 대해 지체 없이 조치하겠습니다.

제7조 (개인정보의 파기)
1. 회사는 개인정보 보유기간의 경과, 처리목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체없이 해당 개인정보를 파기합니다.
2. 개인정보 파기의 절차 및 방법은 다음과 같습니다:
   - 파기절차: 회사는 파기 사유가 발생한 개인정보를 선정하고, 회사의 개인정보 보호책임자의 승인을 받아 개인정보를 파기합니다.
   - 파기방법: 회사는 전자적 파일 형태로 기록·저장된 개인정보는 기록을 재생할 수 없도록 파기하며, 종이 문서에 기록·저장된 개인정보는 분쇄기로 분쇄하거나 소각하여 파기합니다.

제8조 (개인정보 보호책임자)
1. 회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다:
   - 개인정보 보호책임자: ○○○
   - 연락처: privacy@starttoo.com

2. 정보주체께서는 회사의 서비스를 이용하시면서 발생한 모든 개인정보 보호 관련 문의, 불만처리, 피해구제 등에 관한 사항을 개인정보 보호책임자에게 문의하실 수 있습니다.

제9조 (개인정보의 안전성 확보조치)
회사는 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다:
1. 관리적 조치: 내부관리계획 수립·시행, 정기적 직원 교육 등
2. 기술적 조치: 개인정보처리시스템 등의 접근권한 관리, 접근통제시스템 설치, 고유식별정보 등의 암호화, 보안프로그램 설치
3. 물리적 조치: 전산실, 자료보관실 등의 접근통제

제10조 (개인정보 처리방침 변경)
이 개인정보 처리방침은 2024년 1월 1일부터 적용되며, 법령 및 방침에 따른 변경내용의 추가, 삭제 및 정정이 있는 경우에는 변경사항의 시행 7일 전부터 공지사항을 통하여 고지할 것입니다.''';
  }

  String _getMarketingContent() {
    return '''마케팅 정보 수신 동의

1. 수신 동의 항목
   - 이메일, SMS, 푸시 알림을 통한 마케팅 정보 수신

2. 마케팅 정보 수신 내용
   - 신규 서비스 및 이벤트 안내
   - 맞춤형 광고 및 프로모션 정보
   - 타투 관련 추천 정보

3. 동의 철회
   - 마케팅 정보 수신 동의는 언제든지 철회할 수 있습니다.
   - 앱 내 설정 메뉴에서 마케팅 정보 수신 동의를 해제할 수 있습니다.

4. 동의 거부 권리
   - 마케팅 정보 수신 동의는 선택사항이며, 동의하지 않아도 서비스 이용에 제한이 없습니다.
   - 다만, 마케팅 정보 수신 동의를 하지 않을 경우 이벤트 및 프로모션 정보를 받을 수 없습니다.''';
  }
}

