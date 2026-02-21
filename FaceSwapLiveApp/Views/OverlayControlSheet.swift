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
                Section {
                    if viewModel.isOverlayActive {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(viewModel.overlayMediaType == .video ? "Video overlay active" : "Image overlay active")
                                .font(.subheadline)
                        }

                        HStack {
                            Text("Opacity")
                                .font(.subheadline)
                            Slider(value: $viewModel.overlayOpacity, in: 0.1...1.0, step: 0.05)
                        }

                        Button(role: .destructive) {
                            viewModel.clearOverlay()
                            dismiss()
                        } label: {
                            Label("Remove Overlay", systemImage: "trash")
                        }
                    } else {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                            Text("No overlay active")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Virtual Camera Overlay")
                }

                Section {
                    PhotosPicker(selection: $imagePickerItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.fill")
                    }
                    PhotosPicker(selection: $videoPickerItem, matching: .videos) {
                        Label("Choose Video", systemImage: "video.fill")
                    }
                } header: {
                    Text("Upload Media")
                } footer: {
                    Text("Upload a celebrity photo or video to overlay on web content.")
                }
            }
            .navigationTitle("Overlay Controls")
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
                    viewModel.loadOverlayImage(image)
                    dismiss()
                }
            }
        }
        .onChange(of: videoPickerItem) { _, item in
            guard let item else { return }
            Task {
                if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                    viewModel.loadOverlayVideo(movie.url)
                    dismiss()
                }
            }
        }
    }
}
