import SwiftUI
import PhotosUI

struct OverlayControlSheet: View {
    @Bindable var viewModel: BrowserViewModel
    @State private var imagePickerItem: PhotosPickerItem?
    @State private var videoPickerItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                sourceMediaSection
                virtualCamSection
                visualOverlaySection
            }
            .navigationTitle("Camera Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onChange(of: imagePickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.loadSource(image: image)
                }
            }
        }
        .onChange(of: videoPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                    viewModel.loadSource(videoURL: movie.url)
                }
            }
        }
    }

    private var sourceMediaSection: some View {
        Section {
            if viewModel.hasSource {
                HStack(spacing: 12) {
                    if let img = viewModel.sourceImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 42)
                            .clipShape(.rect(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 56, height: 42)
                            .overlay {
                                Image(systemName: "video.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.sourceType == .image ? "Photo loaded" : "Video loaded")
                            .font(.subheadline.weight(.medium))
                        Text("Ready to use as virtual camera")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(role: .destructive) {
                    viewModel.clearSource()
                    imagePickerItem = nil
                    videoPickerItem = nil
                } label: {
                    Label("Remove Media", systemImage: "trash")
                }
            }

            PhotosPicker(selection: $imagePickerItem, matching: .images) {
                Label("Choose Photo", systemImage: "photo.fill")
            }
            PhotosPicker(selection: $videoPickerItem, matching: .videos) {
                Label("Choose Video", systemImage: "video.fill")
            }
        } header: {
            Text("Source Media")
        } footer: {
            Text("Upload a celebrity photo or video. It will be used as your camera feed on websites.")
        }
    }

    private var virtualCamSection: some View {
        Section {
            Toggle("Inject as Camera", isOn: Binding(
                get: { viewModel.isVirtualCamActive },
                set: { viewModel.setVirtualCam(active: $0) }
            ))
            .disabled(!viewModel.hasSource)

            if viewModel.isVirtualCamActive {
                Picker("Mode", selection: Binding(
                    get: { viewModel.virtualCamMode },
                    set: { newValue in
                        viewModel.virtualCamMode = newValue
                        viewModel.updateUserScripts()
                        viewModel.syncVirtualCamToPage()
                    }
                )) {
                    ForEach(BrowserViewModel.VirtualCamMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                    Text("Websites will see \"FaceSwapLive Camera\" as a device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Virtual Camera")
        } footer: {
            if viewModel.virtualCamMode == .replaceAll {
                Text("Replace All: every camera request returns your uploaded media. Best for webcam tests and video calls.")
            } else {
                Text("Add as Device: adds \"FaceSwapLive Camera\" to the device list. Sites that let you pick a camera will show it.")
            }
        }
    }

    private var visualOverlaySection: some View {
        Section {
            Toggle("Visual Overlay", isOn: $viewModel.isOverlayActive)
                .disabled(!viewModel.hasSource)

            if viewModel.isOverlayActive {
                HStack {
                    Text("Opacity")
                        .font(.subheadline)
                    Slider(value: $viewModel.overlayOpacity, in: 0.1...1.0, step: 0.05)
                }
            }
        } header: {
            Text("Visual Overlay")
        } footer: {
            Text("Shows the uploaded media directly on top of the browser view as a visual cover.")
        }
    }
}
