import SwiftUI
import VideoEditorSDK

@available(iOS 14.0, *)
struct ContentView: View {
  /// Controlling the presentation state of the camera.
  @State private var cameraPresented = false

  /// Controlling the presentation state of the video editor.
  @State private var vesdkPresented = false

  /// The video that should be presented in the `VideoEditor`.
  @State private var video = Video(url: Bundle.main.url(forResource: "Skater", withExtension: ".mp4")!)

  /// The `Video` that has been taken in the `Camera`.
  @State private var selectedVideo: Video?

  /// The `PhotoEditModel` used to restore a previous state in the `VideoEditor`.
  @State private var photoEditModel: PhotoEditModel?

  var body: some View {
    NavigationView {
      List {
        Button("Camera") {
          cameraPresented = true
        }
        .padding(5)
        Button("VideoEditor") {
          vesdkPresented = true
        }
        .padding(5)
      }
      .navigationTitle("SwiftUIExample")
      .fullScreenCover(isPresented: $vesdkPresented, content: {
        VideoEditor(video: selectedVideo ?? video, configuration: buildConfiguration(), photoEditModel: photoEditModel)
          .onDidCancel {
            vesdkPresented = false
            photoEditModel = nil
            selectedVideo = nil
          }
          .onDidFail {
            vesdkPresented = false
            photoEditModel = nil
            selectedVideo = nil
          }
          .onDidSave { _ in
            vesdkPresented = false
            photoEditModel = nil
            selectedVideo = nil
          }
          .ignoresSafeArea()
      })
      .fullScreenCover(isPresented: $cameraPresented, content: {
        Camera(configuration: buildConfiguration())
          .onDidCancel {
            cameraPresented = false
            selectedVideo = nil
          }
          .onDidSave { result in
            if let url = result.url {
              selectedVideo = Video(url: url)
            }
            self.photoEditModel = result.photoEditModel
            cameraPresented = false
          }
          .ignoresSafeArea()
      })
      .onChange(of: selectedVideo, perform: { _ in
        if selectedVideo != nil {
          vesdkPresented = true
        }
      })
    }
  }

  /// The `OpenWeatherProvider` used for the animated stickers.
  private var weatherProvider: OpenWeatherProvider = {
    let weatherProvider = OpenWeatherProvider(apiKey: nil, unit: .locale)
    weatherProvider.locationAccessRequestClosure = { locationManager in
      locationManager.requestWhenInUseAuthorization()
    }
    return weatherProvider
  }()

  /// Builds the `Configuration` used for the editor.
  private func buildConfiguration() -> Configuration {
    let configuration = Configuration { builder in
      // Configure camera
      builder.configureCameraViewController { options in
        // Just enable photos
        options.allowedRecordingModes = [.video]
        // Show cancel button
        options.showCancelButton = true
      }

      // Configure sticker tool
      builder.configureStickerToolController { options in
        // Enable personal stickers
        options.personalStickersEnabled = true
        // Enable smart weather stickers
        options.weatherProvider = self.weatherProvider
      }

      // Configure theme
      builder.theme = .dynamic
    }

    return configuration
  }
}

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
