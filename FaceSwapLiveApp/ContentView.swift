import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Camera", systemImage: "camera.fill") {
                LiveSwapView()
            }
            Tab("Browser", systemImage: "globe") {
                BrowserFaceSwapView()
            }
        }
        .preferredColorScheme(.dark)
    }
}
