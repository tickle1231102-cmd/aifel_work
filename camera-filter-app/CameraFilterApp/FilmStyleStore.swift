import CoreImage
import Foundation

/// FilmStyle을 JSON으로 직렬화하기 위한 DTO. CIColor 자체는 Codable이 아니라서
/// 틴트 색상은 [R, G, B] 배열로 풀어서 저장한다.
struct FilmStyleData: Codable {
    var name: String
    var exposure: Double
    var saturation: Double
    var brightness: Double
    var contrast: Double
    var temperature: Double
    var tint: Double
    var highlightAmount: Double
    var shadowAmount: Double
    var shadowTintColor: [Double]?
    var shadowTintOpacity: Double
    var highlightTintColor: [Double]?
    var highlightTintOpacity: Double
    var fadeAmount: Double
    var vignetteIntensity: Double
    var vignetteRadius: Double
    var grainAmount: Double
    var showDateStamp: Bool

    init(_ style: FilmStyle) {
        name = style.name
        exposure = Double(style.exposure)
        saturation = Double(style.saturation)
        brightness = Double(style.brightness)
        contrast = Double(style.contrast)
        temperature = Double(style.temperature)
        tint = Double(style.tint)
        highlightAmount = Double(style.highlightAmount)
        shadowAmount = Double(style.shadowAmount)
        shadowTintColor = style.shadowTintColor.map { [Double($0.red), Double($0.green), Double($0.blue)] }
        shadowTintOpacity = Double(style.shadowTintOpacity)
        highlightTintColor = style.highlightTintColor.map { [Double($0.red), Double($0.green), Double($0.blue)] }
        highlightTintOpacity = Double(style.highlightTintOpacity)
        fadeAmount = Double(style.fadeAmount)
        vignetteIntensity = Double(style.vignetteIntensity)
        vignetteRadius = Double(style.vignetteRadius)
        grainAmount = Double(style.grainAmount)
        showDateStamp = style.showDateStamp
    }

    func makeStyle() -> FilmStyle {
        var s = FilmStyle(name: name)
        s.exposure = CGFloat(exposure)
        s.saturation = CGFloat(saturation)
        s.brightness = CGFloat(brightness)
        s.contrast = CGFloat(contrast)
        s.temperature = CGFloat(temperature)
        s.tint = CGFloat(tint)
        s.highlightAmount = CGFloat(highlightAmount)
        s.shadowAmount = CGFloat(shadowAmount)
        if let c = shadowTintColor, c.count == 3 {
            s.shadowTintColor = CIColor(red: CGFloat(c[0]), green: CGFloat(c[1]), blue: CGFloat(c[2]))
        }
        s.shadowTintOpacity = CGFloat(shadowTintOpacity)
        if let c = highlightTintColor, c.count == 3 {
            s.highlightTintColor = CIColor(red: CGFloat(c[0]), green: CGFloat(c[1]), blue: CGFloat(c[2]))
        }
        s.highlightTintOpacity = CGFloat(highlightTintOpacity)
        s.fadeAmount = CGFloat(fadeAmount)
        s.vignetteIntensity = CGFloat(vignetteIntensity)
        s.vignetteRadius = CGFloat(vignetteRadius)
        s.grainAmount = CGFloat(grainAmount)
        s.showDateStamp = showDateStamp
        return s
    }
}

/// 사용자가 슬라이더로 조정한 필터 값을 기기에 저장/복원한다.
/// - 기본 제공 프리셋과 같은 이름으로 저장하면 "덮어쓰기" (그 프리셋의 파라미터가 교체된다).
/// - 새 이름으로 저장하면 필터 목록 뒤에 커스텀 스타일로 추가된다.
enum FilmStyleStore {
    private static let overridesKey = "com.camerafilterapp.styleOverrides.v1"
    private static let customOrderKey = "com.camerafilterapp.customStyleOrder.v1"

    private static func loadOverrides() -> [String: FilmStyleData] {
        guard let data = UserDefaults.standard.data(forKey: overridesKey),
              let dict = try? JSONDecoder().decode([String: FilmStyleData].self, from: data) else {
            return [:]
        }
        return dict
    }

    private static func writeOverrides(_ dict: [String: FilmStyleData]) {
        guard let encoded = try? JSONEncoder().encode(dict) else { return }
        UserDefaults.standard.set(encoded, forKey: overridesKey)
    }

    /// style을 name이라는 키로 저장한다. 기본 프리셋 이름과 같으면 그 프리셋을 덮어쓰는 효과,
    /// 새 이름이면 순수 커스텀 항목으로 추가된다.
    static func save(_ style: FilmStyle, as name: String) {
        var overrides = loadOverrides()
        var data = FilmStyleData(style)
        data.name = name
        overrides[name] = data
        writeOverrides(overrides)

        let builtInNames = Set(FilmStyle.builtIn.map(\.name))
        if !builtInNames.contains(name) {
            var order = UserDefaults.standard.stringArray(forKey: customOrderKey) ?? []
            if !order.contains(name) {
                order.append(name)
                UserDefaults.standard.set(order, forKey: customOrderKey)
            }
        }
    }

    static func deleteCustom(named name: String) {
        var overrides = loadOverrides()
        overrides.removeValue(forKey: name)
        writeOverrides(overrides)

        var order = UserDefaults.standard.stringArray(forKey: customOrderKey) ?? []
        order.removeAll { $0 == name }
        UserDefaults.standard.set(order, forKey: customOrderKey)
    }

    /// 기본 프리셋에 저장된 오버라이드를 반영하고, 순수 커스텀 스타일을 뒤에 이어붙인 전체 목록.
    static func allStyles() -> [FilmStyle] {
        let overrides = loadOverrides()
        let builtInNames = Set(FilmStyle.builtIn.map(\.name))

        let merged = FilmStyle.builtIn.map { style -> FilmStyle in
            overrides[style.name]?.makeStyle() ?? style
        }

        let customOrder = UserDefaults.standard.stringArray(forKey: customOrderKey) ?? []
        let customOnly = customOrder
            .filter { !builtInNames.contains($0) }
            .compactMap { overrides[$0]?.makeStyle() }

        return merged + customOnly
    }

    /// name이 사용자가 만든 순수 커스텀 스타일인지 (기본 프리셋이 아닌지) 여부.
    static func isCustom(_ name: String) -> Bool {
        !FilmStyle.builtIn.map(\.name).contains(name)
    }
}
