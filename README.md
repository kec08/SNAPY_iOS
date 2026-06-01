# SNAPY - 친구들과 공유하는 진짜 일상

<p align="center">
  <img src="https://github.com/user-attachments/assets/de644267-394f-462e-8310-571126459166" alt="SNAPY" width="878"/>
</p>

<p align="center">
  <strong>"듀얼 카메라로 담은 보정 없는 하루, 친구들과 나눠보세요."</strong>
</p>

<p align="center">
  <a href="https://apps.apple.com/kr/app/스내피-snapy/id6761876306">
    <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="App Store" height="40"/>
  </a>
</p>

---

## 스크린샷

<p align="center">
  <img src="https://github.com/user-attachments/assets/7a6d80ab-8cb1-4e09-8ba4-6debb9caee77" width="22%"/>
  <img src="https://github.com/user-attachments/assets/d375e85c-2a2d-4f77-8ee7-c45733c34bbd" width="22%"/>
  <img src="https://github.com/user-attachments/assets/0a358e23-5444-4a0c-8f88-afadf8b79516" width="22%"/>
  <img src="https://github.com/user-attachments/assets/5d9d83fa-8d45-4d07-aa71-26ca5f92e9f9" width="22%"/>
</p>
<p align="center">
  <img src="https://github.com/user-attachments/assets/fdec046a-84a5-4dad-b372-f6a05a2cbe24" width="22%"/>
  <img src="https://github.com/user-attachments/assets/478188cb-6613-49d1-83d5-a4aee424725b" width="22%"/>
  <img src="https://github.com/user-attachments/assets/4fcb447a-59de-4d1e-ad53-27cc7bec715f" width="22%"/>
  <img src="https://github.com/user-attachments/assets/2a155adc-1656-47b1-99b8-626966ab0ec2" width="22%"/>
</p>

---

## 소개

**SNAPY**는 사진으로 소통하는 일상 공유 SNS입니다.

듀얼 카메라로 전면·후면을 동시에 촬영하고, 하루를 아침·점심·저녁으로 나누어 기록합니다.
필터와 보정 없이, 있는 그대로의 순간을 친구들과 나눠보세요.

## 주요 기능

### 1. 듀얼 카메라 동시 촬영
> 셔터 한 번이면 전면과 후면이 동시에. 내가 보는 풍경과 그 순간의 나를 하나에 담아요.

- `AVCaptureMultiCamSession` 기반 전면·후면 동시 촬영
- 메인 화면 + PIP(소형 화면) 이중 프리뷰
- PIP 드래그 이동, 전면/후면 전환 지원
- MultiCam 미지원 기기 자동 폴백

### 2. 시간대별 앨범
> 하루를 아침, 점심, 저녁 세 타임으로 나누어 기록해요.

- 촬영 시각에 따라 아침(6-11시), 점심(12-16시), 저녁(17-24시) 자동 배정
- 추가 촬영 2장까지, 하루 최대 5장
- 날짜별 자동 정리, 캘린더에서 월별 기록 확인

### 3. 피드 & 스토리
> 오늘의 앨범을 피드에 게시하고, 24시간 스토리로 일상을 나눠보세요.

- 커서 기반 무한 스크롤 피드
- 24시간 자동 만료 스토리
- 좋아요, 이미지·이모지·음성 댓글
- 더블탭 하트 애니메이션 + 햅틱 피드백

### 4. 음성 댓글
> 텍스트 대신 목소리로 반응하세요.

- AAC 포맷 녹음 + 실시간 파형 애니메이션
- 재생 시 실제 오디오 데이터 기반 파형 UI
- 이미지·이모지 댓글과 함께 통합 관리

### 5. 방명록
> 친구의 프로필에 사진 방명록을 남겨보세요.

- 갤러리에서 사진 선택 후 방명록 등록
- 3열 그리드 전체보기
- 작성자 프로필 사진 표시

### 6. 친구 & 연락처 동기화
> 연락처를 연동하면 SNAPY를 사용하는 친구를 자동으로 찾아줘요.

- 연락처 전화번호 기반 친구 자동 매칭
- 겹친구 추천, 친구 검색
- 친구 요청 보내기/수락/거절/취소

### 7. 스트릭
> 매일 사진을 올리면 스트릭이 쌓여요.

- 연속 촬영일수 기록
- 5일 연속 달성 시 특별 아이콘 활성화

### 8. 신고 & 차단
> 안전한 커뮤니티를 위한 기능이에요.

- 8가지 신고 사유 선택
- 유저 차단/해제/목록 관리
- 차단 상태에 따른 프로필 UI 5단계 분기

## 기술 스택

| 구분 | 기술 |
|------|------|
| UI | Swift, SwiftUI |
| 아키텍처 | MVVM |
| 비동기 | async/await, Combine |
| 네트워크 | Moya, Alamofire |
| 이미지 | Kingfisher |
| 카메라 | AVFoundation (MultiCamSession) |
| 오디오 | AVFoundation (AVAudioRecorder, AVAudioPlayer) |
| 인증 | Google Sign-In, Apple Sign-In, JWT |
| 연락처 | Contacts Framework |
| 저장 | UserDefaults |

## 프로젝트 구조

```
SNAPY_iOS/
├── App/
│   ├── SNAPY_iOSApp.swift           # @main 엔트리
│   ├── AppDelegate.swift            # APNs 설정
│   ├── RootView.swift               # 화면 라우팅 (스플래시→로그인→메인)
│   └── MainTabView.swift            # 탭 바 (홈/친구/카메라/앨범/프로필)
│
├── Feature/
│   ├── Home/                        # 홈 피드, 스토리, 게시하기
│   ├── Camera/                      # 듀얼 카메라 촬영, PIP, 미리보기
│   ├── Album/                       # 앨범, 캘린더, 스트릭
│   ├── Friend/                      # 친구 검색, 추천, 요청, 프로필
│   ├── Profile/                     # 내 프로필, 설정, 차단 관리
│   ├── Comment/                     # 텍스트·이미지·음성 댓글
│   ├── Notification/                # 알림 목록
│   ├── Login/                       # 이메일·Google·Apple 로그인
│   ├── SignUp/                      # 회원가입 (이메일→비밀번호→전화번호→프로필)
│   ├── Common/                      # 공용 컴포넌트 (FeedCard, Report, 스켈레톤)
│   └── Splash/                      # 스플래시 화면
│
├── Model/
│   └── Core/
│       ├── Extension/               # Color, Date, UIImage 확장
│       └── Network/
│           ├── API/                  # Moya TargetType (Album, Auth, Feed 등 12개)
│           ├── DTO/                  # 서버 응답 모델 (12개)
│           ├── Service/              # 비즈니스 로직 (12개 서비스)
│           └── Token/               # JWT 저장·검증·자동 갱신
│
└── Assets.xcassets/                  # 이미지 및 컬러 리소스
```

## 아키텍처

```
┌──────────────────┐
│      View         │  SwiftUI 화면 + 제스처
├──────────────────┤
│    ViewModel      │  @MainActor @Published 상태 관리
├──────────────────┤
│     Service       │  Moya 기반 API 호출 + 토큰 자동 갱신
├──────────────────┤
│    API / DTO      │  TargetType enum + Codable 응답 모델
└──────────────────┘
```

View → ViewModel → Service → API 흐름을 일관되게 유지하며, 모든 Service에 `requestWithRefresh()` 헬퍼를 적용해 401 응답 시 토큰 갱신 후 자동 재시도합니다.

## 앱 다운로드

<p align="center">
  <a href="https://apps.apple.com/kr/app/스내피-snapy/id6761876306">
    <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="App Store" height="40"/>
  </a>
</p>

## 개발 정보

- iOS 전담 개발 (백엔드 별도)
- SwiftUI + MVVM 아키텍처
- 60개 API 엔드포인트 연동

## 라이선스

이 프로젝트는 Gyeongbuk Software Highschool 캡스톤 프로젝트로, 무단 복제 및 배포를 금합니다.
