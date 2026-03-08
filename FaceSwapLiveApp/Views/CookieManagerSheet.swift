import SwiftUI

struct CookieManagerSheet: View {
    let profile: BrowserProfile
    let viewModel: BrowserViewModel
    @Binding var cookieCount: Int
    let onImport: () -> Void
    let onExport: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isClearing: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label("Stored Cookies", systemImage: "cylinder.split.1x2")
                        Spacer()
                        Text("\(cookieCount)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Section("Actions") {
                    Button {
                        onExport()
                    } label: {
                        Label("Export Cookies", systemImage: "square.and.arrow.up")
                    }
                    .disabled(cookieCount == 0)

                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onImport()
                        }
                    } label: {
                        Label("Import Cookies", systemImage: "square.and.arrow.down")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        isClearing = true
                    } label: {
                        Label("Clear All Cookies", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Cookie Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Clear All Cookies?", isPresented: $isClearing) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    Task {
                        await CookieManager.clearCookies(for: profile.id)
                        cookieCount = 0
                    }
                }
            } message: {
                Text("This will remove all cookies and local storage for this profile.")
            }
        }
    }
}
