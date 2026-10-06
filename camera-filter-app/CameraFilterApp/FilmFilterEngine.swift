import CoreImage
import CoreGraphics
import CoreText
import Foundation

/// FilmStyle 파라미터를 실제 CIFilter 파이프라인으로 실행하는 엔진.
/// UIKit에 의존하지 않고 CoreImage/CoreGraphics/CoreText만 사용하므로
/// iOS 앱과 macOS 커맨드라인 양쪽에서 동일하게 동작·검증 가능하다.
enum FilmFilterEngine {

    /// - Parameters:
    ///   - includeDateStamp: 실시간 프리뷰에서는 매 프레임 텍스트 렌더링 비용을 피하기 위해 false로 호출하고,
    ///     실제 촬영 결과물에는 true로 호출해 날짜 스탬프를 굽는다.
    static func apply(_ style: FilmStyle, to inputImage: CIImage, includeDateStamp: Bool) -> CIImage {
        let extent = inputImage.extent
        var image = inputImage

        // 1. 노출 / 채도 / 밝기 / 대비
        if style.exposure != 0 {
            image = image.applyingFilter("CIExposureAdjust", parameters: ["inputEV": style.exposure])
        }
        image = image.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: style.saturation,
            kCIInputBrightnessKey: style.brightness,
            kCIInputContrastKey: style.contrast,
        ])

        // 2. 화이트 밸런스
        if style.temperature != 6500 || style.tint != 0 {
            image = image.applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: 6500, y: 0),
                "inputTargetNeutral": CIVector(x: style.temperature, y: style.tint),
            ])
        }

        // 3. 하이라이트 / 섀도우 복원 (필름 특유의 눌린 하이라이트, 뜬 섀도우)
        if style.highlightAmount != 1.0 || style.shadowAmount != 0 {
            image = image.applyingFilter("CIHighlightShadowAdjust", parameters: [
                "inputHighlightAmount": style.highlightAmount,
                "inputShadowAmount": style.shadowAmount,
            ])
        }

        // 4. 분리톤(스플릿 토닝): 어두운 영역과 밝은 영역에 각각 다른 색을 입힌다.
        //    밝기 마스크를 미리 한 번만 계산해 재사용한다.
        if style.shadowTintColor != nil || style.highlightTintColor != nil {
            let luminance = luminanceMask(of: image)
            if let shadowTint = style.shadowTintColor, style.shadowTintOpacity > 0 {
                let shadowMask = luminance.applyingFilter("CIColorInvert")
                image = maskedTint(shadowTint, mask: shadowMask, opacity: style.shadowTintOpacity, over: image)
            }
            if let highlightTint = style.highlightTintColor, style.highlightTintOpacity > 0 {
                image = maskedTint(highlightTint, mask: luminance, opacity: style.highlightTintOpacity, over: image)
            }
        }

        // 5. 페이드 (블랙 레벨을 살짝 들어올려 바랜 필름 느낌)
        if style.fadeAmount > 0 {
            image = image.applyingFilter("CIColorMatrix", parameters: [
                "inputBiasVector": CIVector(x: style.fadeAmount, y: style.fadeAmount, z: style.fadeAmount, w: 0),
            ])
        }

        // 6. 비네트
        if style.vignetteIntensity > 0 {
            image = image.applyingFilter("CIVignette", parameters: [
                kCIInputIntensityKey: style.vignetteIntensity,
                kCIInputRadiusKey: style.vignetteRadius,
            ])
        }

        image = image.cropped(to: extent)

        // 7. 필름 그레인
        if style.grainAmount > 0 {
            image = applyGrain(amount: style.grainAmount, to: image, extent: extent)
        }

        // 8. 날짜 스탬프 (최종 촬영본에만)
        if includeDateStamp && style.showDateStamp {
            image = applyDateStamp(to: image, extent: extent)
        }

        return image.cropped(to: extent)
    }

    // MARK: - 분리톤 블렌드

    /// 이미지의 밝기(luminance)를 그레이스케일로 뽑아낸다. 분리톤 마스크의 재료로 쓴다.
    private static func luminanceMask(of image: CIImage) -> CIImage {
        let weights = CIVector(x: 0.2126, y: 0.7152, z: 0.0722, w: 0)
        return image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": weights,
            "inputGVector": weights,
            "inputBVector": weights,
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
        ])
    }

    /// mask(그레이스케일, 0=효과 없음~1=최대)로 세기를 조절하며 color를 image에 입힌다.
    /// 섀도우 틴트는 반전된 밝기 마스크를, 하이라이트 틴트는 밝기 마스크를 그대로 넘겨
    /// 어두운/밝은 영역에만 각각의 색이 실리도록 한다.
    private static func maskedTint(_ color: CIColor, mask: CIImage, opacity: CGFloat, over image: CIImage) -> CIImage {
        let tintLayer = CIImage(color: color).cropped(to: image.extent)
        let scaledMask = mask.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: opacity, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: opacity, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: opacity, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
        ])
        return tintLayer.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: image,
            kCIInputMaskImageKey: scaledMask,
        ])
    }

    // MARK: - 그레인

    /// 매 프레임 랜덤 노이즈를 새로 생성하면 비용이 크므로, 해상도별로 한 번 만든 노이즈를 캐싱해 재사용한다.
    private static var cachedNoise: (size: CGSize, image: CIImage)?

    private static func grainNoise(for extent: CGRect) -> CIImage {
        if let cached = cachedNoise, cached.size == extent.size {
            return cached.image
        }
        let raw = CIFilter(name: "CIRandomGenerator")!.outputImage!.cropped(to: extent)
        let grayscale = raw.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0,
            kCIInputContrastKey: 1,
        ])
        cachedNoise = (extent.size, grayscale)
        return grayscale
    }

    private static func applyGrain(amount: CGFloat, to image: CIImage, extent: CGRect) -> CIImage {
        let noise = grainNoise(for: extent)
        let scaledNoise = noise.applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: amount),
        ])
        return scaledNoise.applyingFilter("CISoftLightBlendMode", parameters: [
            kCIInputBackgroundImageKey: image,
        ]).cropped(to: extent)
    }

    // MARK: - 날짜 스탬프

    private static func applyDateStamp(to image: CIImage, extent: CGRect) -> CIImage {
        guard let stampCGImage = renderDateStampImage(size: extent.size) else { return image }
        let stampCIImage = CIImage(cgImage: stampCGImage)
        return stampCIImage.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: image,
        ])
    }

    private static func renderDateStampImage(size: CGSize) -> CGImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yy MM dd"
        let text = formatter.string(from: Date())

        let fontSize = size.height * 0.032
        let font = CTFontCreateWithName("Courier-Bold" as CFString, fontSize, nil)
        let color = CGColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 0.92)

        let attrString = NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color,
        ])
        let line = CTLineCreateWithAttributedString(attrString)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)

        let margin = size.width * 0.045
        let x = size.width - bounds.width - margin
        let y = size.height * 0.06

        ctx.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, ctx)

        return ctx.makeImage()
    }
}
