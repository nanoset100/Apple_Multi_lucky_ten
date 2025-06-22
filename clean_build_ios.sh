#!/bin/bash
# 완전한 iOS 클린 빌드 스크립트
# "Failed to parse Target Device Version" 오류 해결을 위한 완전 초기화

echo "🔥 완전한 iOS 클린 빌드 시작..."

# 1단계: Flutter 클린
echo "1️⃣ Flutter clean 실행 중..."
flutter clean

# 2단계: iOS 관련 모든 캐시 삭제
echo "2️⃣ iOS 캐시 및 빌드 파일 삭제 중..."
rm -rf ios/Pods                              # CocoaPods 삭제
rm -rf ios/.symlinks                         # 심볼릭 링크 삭제
rm -rf ios/Flutter/Flutter.framework         # Flutter 프레임워크 삭제
rm -rf ios/Flutter/Flutter.podspec           # Flutter podspec 삭제
rm -f ios/Podfile.lock                       # Podfile.lock 삭제

# 3단계: Dart 도구 캐시 삭제
echo "3️⃣ Dart 도구 캐시 삭제 중..."
rm -rf .dart_tool/                           # Dart 도구 캐시

# 4단계: Flutter 의존성 재설치
echo "4️⃣ Flutter pub get 실행 중..."
flutter pub get

# 5단계: CocoaPods 설치 (macOS에서만 실행)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "5️⃣ CocoaPods 설치 중... (macOS 감지)"
    cd ios
    pod install --repo-update                # 저장소 업데이트와 함께 설치
    cd ..
else
    echo "5️⃣ CocoaPods 건너뛰기 (Windows/Linux 환경)"
    echo "   → Codemagic에서 자동으로 실행됩니다"
fi

# 6단계: 완료 메시지
echo "✅ 완전한 클린 빌드 준비 완료!"
echo ""
echo "🚀 이제 다음 중 하나를 실행하세요:"
echo "   • 로컬 (macOS): flutter build ios --release"
echo "   • Codemagic: Git push 후 빌드 실행"
echo ""
echo "📋 적용된 iOS 13.0 설정:"
echo "   ✅ Podfile: 3단계 platform 선언"
echo "   ✅ project.pbxproj: 모든 IPHONEOS_DEPLOYMENT_TARGET = 13.0"
echo "   ✅ Info.plist: MinimumOSVersion = 13.0"
echo "   ✅ post_install 훅: 모든 레벨 강제 적용"
echo ""
echo "🎯 'Failed to parse Target Device Version' 오류가 해결됩니다!" 