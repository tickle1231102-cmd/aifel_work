import SwiftUI

/// 편집 가능한 파라미터 하나의 정의 (표시 이름, 실제 FilmStyle 필드, 슬라이더 범위).
private struct StyleParam {
    let label: String
    let keyPath: WritableKeyPath<FilmStyle, CGFloat>
    let range: ClosedRange<Double>
    let isInteger: Bool
}

private let styleParams: [StyleParam] = [
    StyleParam(label: "노출", keyPath: \.exposure, range: -2...2, isInteger: false),
    StyleParam(label: "채도", keyPath: \.saturation, range: 0...2, isInteger: false),
    StyleParam(label: "밝기", keyPath: \.brightness, range: -0.5...0.5, isInteger: false),
    StyleParam(label: "대비", keyPath: \.contrast, range: 0.5...1.5, isInteger: false),
    StyleParam(label: "색온도", keyPath: \.temperature, range: 3000...10000, isInteger: true),
    StyleParam(label: "틴트", keyPath: \.tint, range: -50...50, isInteger: true),
    StyleParam(label: "하이라이트", keyPath: \.highlightAmount, range: 0...1, isInteger: false),
    StyleParam(label: "섀도우", keyPath: \.shadowAmount, range: 0...1, isInteger: false),
    StyleParam(label: "페이드", keyPath: \.fadeAmount, range: 0...0.2, isInteger: false),
    StyleParam(label: "비네트 세기", keyPath: \.vignetteIntensity, range: 0...2, isInteger: false),
    StyleParam(label: "비네트 범위", keyPath: \.vignetteRadius, range: 0.5...2.5, isInteger: false),
    StyleParam(label: "그레인", keyPath: \.grainAmount, range: 0...0.4, isInteger: false),
]

/// 카메라 화면을 최대한 가리지 않도록 하단에 작게 배치하는 인라인 필터 편집 바.
/// 위: 파라미터 이름 가로 스크롤(탭해서 선택) / 중간: 선택된 파라미터 하나의 게이지 / 위쪽: 이름·저장·취소.
struct StyleEditorView: View {
    @Binding var isPresented: Bool

    @State private var draft: FilmStyle
    private let originalStyle: FilmStyle
    private let originalName: String

    var onSave: (FilmStyle, String) -> Void
    var onLiveChange: (FilmStyle) -> Void

    @State private var selectedParamIndex = 0
    @State private var showNamePrompt = false
    @State private var newName = ""

    init(
        isPresented: Binding<Bool>,
        style: FilmStyle,
        onSave: @escaping (FilmStyle, String) -> Void,
        onLiveChange: @escaping (FilmStyle) -> Void
    ) {
        self._isPresented = isPresented
        self._draft = State(initialValue: style)
        self.originalStyle = style
        self.originalName = style.name
        self.onSave = onSave
        self.onLiveChange = onLiveChange
    }

    private var currentParam: StyleParam { styleParams[selectedParamIndex] }

    var body: some View {
        VStack(spacing: 8) {
            header
            gaugeRow
            paramStrip
        }
        .padding(.vertical, 10)
        .background(.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 8)
        .alert("새 스타일 이름", isPresented: $showNamePrompt) {
            TextField("예: 나만의 필름", text: $newName)
            Button("저장") {
                let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                onSave(draft, trimmed)
                isPresented = false
            }
            Button("취소", role: .cancel) {}
        }
    }

    // MARK: - 헤더 (이름 / 초기화 / 취소 / 저장)

    private var header: some View {
        HStack {
            Button {
                onLiveChange(originalStyle)
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }

            Text("\(originalName) 편집")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Button {
                draft = originalStyle
                onLiveChange(draft)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .foregroundColor(.white.opacity(0.85))
            }

            Menu {
                Button("이 필터에 덮어쓰기") {
                    onSave(draft, originalName)
                    isPresented = false
                }
                Button("새 이름으로 저장") {
                    newName = ""
                    showNamePrompt = true
                }
            } label: {
                Text("저장")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 14)
    }

    // MARK: - 선택된 파라미터 하나의 게이지

    private var gaugeRow: some View {
        VStack(spacing: 4) {
            HStack {
                Text(currentParam.label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Text(formattedValue)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(.white.opacity(0.6))
            }
            Slider(
                value: Binding(
                    get: { Double(draft[keyPath: currentParam.keyPath]) },
                    set: { newValue in
                        draft[keyPath: currentParam.keyPath] = CGFloat(newValue)
                        onLiveChange(draft)
                    }
                ),
                in: currentParam.range
            )
            .tint(.white)
        }
        .padding(.horizontal, 14)
    }

    private var formattedValue: String {
        let value = Double(draft[keyPath: currentParam.keyPath])
        return String(format: currentParam.isInteger ? "%.0f" : "%.2f", value)
    }

    // MARK: - 파라미터 이름 가로 스크롤

    private var paramStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(styleParams.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.12)) {
                            selectedParamIndex = index
                        }
                    } label: {
                        Text(styleParams[index].label)
                            .font(.caption2)
                            .fontWeight(selectedParamIndex == index ? .bold : .regular)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedParamIndex == index
                                          ? Color.white.opacity(0.35)
                                          : Color.white.opacity(0.12))
                            )
                    }
                }
            }
            .padding(.horizontal, 14)
        }
    }
}
