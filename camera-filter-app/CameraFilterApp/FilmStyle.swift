import CoreImage

/// 커스텀 필름 스타일 프리셋.
/// 컬러그레이딩(노출/대비/화이트밸런스/하이라이트-섀도우 분리톤) + 페이드 + 비네트 + 그레인 + 날짜 스탬프를
/// 조합해 "필름 카메라 앱" 특유의 룩을 만든다. 각 프리셋은 우리가 직접 튜닝한 파라미터 값으로,
/// 특정 앱의 LUT을 복제한 것이 아니라 같은 기법으로 새로 설계한 것이다.
struct FilmStyle: Identifiable {
    let id = UUID()
    let name: String

    // 기본 톤
    var exposure: CGFloat = 0
    var saturation: CGFloat = 1.0
    var brightness: CGFloat = 0
    var contrast: CGFloat = 1.0

    // 화이트 밸런스 (색온도 K / 틴트)
    var temperature: CGFloat = 6500
    var tint: CGFloat = 0

    // 하이라이트 / 섀도우 복원
    var highlightAmount: CGFloat = 1.0
    var shadowAmount: CGFloat = 0

    // 분리톤(스플릿 토닝): 섀도우/하이라이트에 각각 다른 색을 살짝 씌운다
    var shadowTintColor: CIColor?
    var shadowTintOpacity: CGFloat = 0
    var highlightTintColor: CIColor?
    var highlightTintOpacity: CGFloat = 0

    // 페이드(블랙 들뜨기) - 오래된 필름 특유의 뿌연 블랙
    var fadeAmount: CGFloat = 0

    // 비네트
    var vignetteIntensity: CGFloat = 0
    var vignetteRadius: CGFloat = 1.5

    // 필름 그레인
    var grainAmount: CGFloat = 0

    // 촬영 시 우측 하단에 필름 카메라 특유의 오렌지 날짜 스탬프 삽입
    var showDateStamp: Bool = false

    init(name: String) {
        self.name = name
    }
}

extension FilmStyle {
    static let original = FilmStyle(name: "원본")

    static let filmA: FilmStyle = {
        var s = FilmStyle(name: "필름 A")
        s.saturation = 0.9
        s.contrast = 1.05
        s.temperature = 5200
        s.tint = 4
        s.highlightAmount = 0.85
        s.shadowAmount = 0.25
        s.shadowTintColor = CIColor(red: 0.1, green: 0.3, blue: 0.22)
        s.shadowTintOpacity = 0.16
        s.highlightTintColor = CIColor(red: 1.0, green: 0.82, blue: 0.5)
        s.highlightTintOpacity = 0.16
        s.fadeAmount = 0.04
        s.vignetteIntensity = 1.1
        s.vignetteRadius = 1.3
        s.grainAmount = 0.12
        s.showDateStamp = true
        return s
    }()

    static let neonNight: FilmStyle = {
        var s = FilmStyle(name: "네온 나이트")
        s.saturation = 0.95
        s.contrast = 1.2
        s.temperature = 9500
        s.tint = -8
        s.highlightAmount = 0.85
        s.shadowAmount = 0.2
        s.shadowTintColor = CIColor(red: 0.05, green: 0.15, blue: 0.55)
        s.shadowTintOpacity = 0.4
        s.highlightTintColor = CIColor(red: 0.4, green: 0.7, blue: 1.0)
        s.highlightTintOpacity = 0.25
        s.fadeAmount = 0.02
        s.vignetteIntensity = 1.6
        s.vignetteRadius = 1.1
        s.grainAmount = 0.16
        return s
    }()

    static let vintageSepia: FilmStyle = {
        var s = FilmStyle(name: "빈티지 세피아")
        s.saturation = 0.15
        s.contrast = 0.95
        s.shadowTintColor = CIColor(red: 0.3, green: 0.18, blue: 0.08)
        s.shadowTintOpacity = 0.45
        s.highlightTintColor = CIColor(red: 0.95, green: 0.78, blue: 0.5)
        s.highlightTintOpacity = 0.4
        s.highlightAmount = 0.8
        s.shadowAmount = 0.3
        s.fadeAmount = 0.07
        s.vignetteIntensity = 1.3
        s.vignetteRadius = 1.3
        s.grainAmount = 0.22
        s.showDateStamp = true
        return s
    }()

    static let sunsetGold: FilmStyle = {
        var s = FilmStyle(name: "선셋 골드")
        s.saturation = 1.1
        s.contrast = 1.05
        s.temperature = 4200
        s.tint = -4
        s.highlightAmount = 0.7
        s.shadowAmount = 0.1
        s.shadowTintColor = CIColor(red: 0.35, green: 0.12, blue: 0.3)
        s.shadowTintOpacity = 0.25
        s.highlightTintColor = CIColor(red: 1.0, green: 0.65, blue: 0.15)
        s.highlightTintOpacity = 0.5
        s.vignetteIntensity = 0.9
        s.vignetteRadius = 1.4
        s.grainAmount = 0.08
        return s
    }()

    static let monoGrain: FilmStyle = {
        var s = FilmStyle(name: "모노 그레인")
        s.saturation = 0.0
        s.contrast = 1.25
        s.vignetteIntensity = 1.4
        s.vignetteRadius = 1.2
        s.grainAmount = 0.3
        return s
    }()

    static let pastel: FilmStyle = {
        var s = FilmStyle(name: "파스텔")
        s.saturation = 0.6
        s.brightness = 0.06
        s.contrast = 0.8
        s.temperature = 7000
        s.highlightAmount = 0.9
        s.shadowAmount = 0.45
        s.highlightTintColor = CIColor(red: 1.0, green: 0.95, blue: 1.0)
        s.highlightTintOpacity = 0.25
        s.fadeAmount = 0.1
        s.vignetteIntensity = 0.3
        s.vignetteRadius = 1.6
        s.grainAmount = 0.05
        return s
    }()

    /// 앱 기본 제공 프리셋 (사용자가 편집해도 이 원본 정의 자체는 바뀌지 않는다 — 편집 결과는 FilmStyleStore가 별도 저장).
    static let builtIn: [FilmStyle] = [.original, .filmA, .neonNight, .vintageSepia, .sunsetGold, .monoGrain, .pastel]
}

extension FilmStyle: Equatable {
    static func == (lhs: FilmStyle, rhs: FilmStyle) -> Bool { lhs.id == rhs.id }
}
