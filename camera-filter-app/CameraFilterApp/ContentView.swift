import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()
    @State private var showSavedToast = false
    @State private var styles: [FilmStyle] = FilmStyleStore.allStyles()
    @State private var isEditingStyle = false
    @State private var editingStyle: FilmStyle = .original

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.isAuthorized {
                cameraPreview
            } else if camera.authorizationDenied {
                permissionDeniedView
            } else {
                ProgressView("카메라 권한 확인 중...")
                    .tint(.white)
                    .foregroundColor(.white)
            }

            VStack {
                topBar
                Spacer()
                if isEditingStyle {
                    StyleEditorView(
                        isPresented: $isEditingStyle,
                        style: editingStyle,
                        onSave: { newStyle, name in
                            FilmStyleStore.save(newStyle, as: name)
                            styles = FilmStyleStore.allStyles()
                            if let match = styles.first(where: { $0.name == name }) {
                                camera.selectedStyle = match
                            }
                        },
                        onLiveChange: { updated in
                            camera.selectedStyle = updated
                        }
                    )
                    .padding(.bottom, 8)
                } else {
                    filterStrip
                }
                shutterBar
            }

            if showSavedToast {
                VStack {
                    Spacer()
                    Text("사진 앱에 저장됨")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 140)
                }
                .transition(.opacity)
            }
        }
        .onAppear { camera.checkPermissions() }
        .onDisappear { camera.stopSession() }
        .onChange(of: camera.didSavePhoto) { saved in
            guard saved else { return }
            withAnimation { showSavedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showSavedToast = false }
                camera.didSavePhoto = false
            }
        }
    }

    // MARK: - 카메라 미리보기

    private var cameraPreview: some View {
        GeometryReader { proxy in
            if let cgImage = camera.currentFrame {
                Image(decorative: cgImage, scale: 1.0, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                Color.black
            }
        }
        .ignoresSafeArea()
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
            Text("카메라 접근 권한이 필요합니다")
                .foregroundColor(.white)
                .font(.headline)
            Text("설정 앱 > 개인정보 보호 > 카메라에서 권한을 허용해주세요.")
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 상단 바

    private var topBar: some View {
        HStack {
            Button {
                editingStyle = camera.selectedStyle
                isEditingStyle = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.black.opacity(0.35), in: Circle())
            }
            Spacer()
            Button {
                camera.flipCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.black.opacity(0.35), in: Circle())
            }
        }
        .padding()
    }

    // MARK: - 필터 선택 스트립

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(styles) { style in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            camera.selectedStyle = style
                        }
                    } label: {
                        Text(style.name)
                            .font(.caption)
                            .fontWeight(camera.selectedStyle == style ? .bold : .regular)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(camera.selectedStyle == style
                                          ? Color.white.opacity(0.35)
                                          : Color.black.opacity(0.25))
                            )
                    }
                    .onLongPressGesture {
                        camera.selectedStyle = style
                        editingStyle = style
                        isEditingStyle = true
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 12)
    }

    // MARK: - 셔터 바

    private var shutterBar: some View {
        HStack {
            Spacer()
            Button {
                camera.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 76, height: 76)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 64, height: 64)
                }
            }
            Spacer()
        }
        .padding(.bottom, 30)
    }
}

#Preview {
    ContentView()
}
