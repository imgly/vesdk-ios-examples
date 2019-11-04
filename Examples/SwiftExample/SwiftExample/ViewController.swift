//  This file is part of the VideoEditor Software Development Kit.
//  Copyright (C) 2016-2019 img.ly GmbH <contact@img.ly>
//  All rights reserved.
//  Redistribution and use in source and binary forms, without
//  modification, are permitted provided that the following license agreement
//  is approved and a legal/financial contract was signed by the user.
//  The license agreement can be found under the following link:
//  https://www.videoeditorsdk.com/LICENSE.txt

import UIKit
import VideoEditorSDK

private enum Selection: Int {
  case camera = 0
  case editor = 1
  case editorWithLightTheme = 2
  case editorWithDarkTheme = 3
  case embeddedEditor = 4
  case customized = 5
}

class ViewController: UITableViewController {

  // MARK: - UITableViewDelegate

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.row {
    case Selection.camera.rawValue:
      presentCameraViewController()
    case Selection.editor.rawValue:
      presentVideoEditViewController()
    case Selection.editorWithLightTheme.rawValue:
      theme = .light
      presentVideoEditViewController()
      theme = ViewController.defaultTheme
    case Selection.editorWithDarkTheme.rawValue:
      theme = .dark
      presentVideoEditViewController()
      theme = ViewController.defaultTheme
    case Selection.embeddedEditor.rawValue:
      pushVideoEditViewController()
    case Selection.customized.rawValue:
      presentCustomizedCameraViewController()
    default:
      break
    }
  }

  // MARK: - Configuration

  private static let defaultTheme: Theme = {
    if #available(iOS 13.0, *) {
      return .dynamic
    } else {
      return .dark
    }
  }()

  private var theme = defaultTheme

  private func buildConfiguration() -> Configuration {
    let configuration = Configuration { builder in
      // Configure camera
      builder.configureCameraViewController { options in
        // Just enable videos
        options.allowedRecordingModes = [.video]
        // Show cancel button
        options.showCancelButton = true
      }

      // Configure editor
      builder.configureVideoEditViewController { options in
        var menuItems = PhotoEditMenuItem.defaultItems
        menuItems.swapAt(0, 1) // Swap first two tools

        options.menuItems = menuItems
      }

      // Configure sticker tool
      builder.configureStickerToolController { options in
        // Enable personal stickers
        options.personalStickersEnabled = true
      }

      // Configure theme
      builder.theme = self.theme
    }

    return configuration
  }

  // MARK: - Presentation

  private func presentCameraViewController() {
    let configuration = buildConfiguration()
    let cameraViewController = CameraViewController(configuration: configuration)
    cameraViewController.modalPresentationStyle = .fullScreen
    cameraViewController.locationAccessRequestClosure = { locationManager in
      locationManager.requestWhenInUseAuthorization()
    }
    cameraViewController.cancelBlock = {
      self.dismiss(animated: true, completion: nil)
    }
    cameraViewController.completionBlock = { [unowned cameraViewController] _, url in
      if let url = url {
        let video = Video(url: url)
        let photoEditModel = cameraViewController.photoEditModel
        cameraViewController.present(self.createVideoEditViewController(with: video, and: photoEditModel), animated: true, completion: nil)
      }
    }

    present(cameraViewController, animated: true, completion: nil)
  }

  private func createVideoEditViewController(with video: Video, and photoEditModel: PhotoEditModel = PhotoEditModel()) -> VideoEditViewController {
    let configuration = buildConfiguration()

    // Create a video edit view controller
    let videoEditViewController = VideoEditViewController(videoAsset: video, configuration: configuration, photoEditModel: photoEditModel)
    videoEditViewController.modalPresentationStyle = .fullScreen
    videoEditViewController.delegate = self

    return videoEditViewController
  }

  private func presentVideoEditViewController() {
    guard let url = Bundle.main.url(forResource: "Skater", withExtension: "mp4") else {
      return
    }

    let video = Video(url: url)
    present(createVideoEditViewController(with: video), animated: true, completion: nil)
  }

  private func pushVideoEditViewController() {
    guard let url = Bundle.main.url(forResource: "Skater", withExtension: "mp4") else {
      return
    }

    let video = Video(url: url)
    navigationController?.pushViewController(createVideoEditViewController(with: video), animated: true)
  }

  private func presentCustomizedCameraViewController() {
    let configuration = Configuration { builder in
      // Setup global colors
      builder.theme.backgroundColor = self.whiteColor
      builder.theme.menuBackgroundColor = UIColor.lightGray

      self.customizeCameraController(builder)
      self.customizeVideoEditorViewController(builder)
      self.customizeTextTool()
    }

    let cameraViewController = CameraViewController(configuration: configuration)
    cameraViewController.modalPresentationStyle = .fullScreen
    cameraViewController.locationAccessRequestClosure = { locationManager in
      locationManager.requestWhenInUseAuthorization()
    }

    // Set a global tint color, that gets inherited by all views
    if let window = UIApplication.shared.delegate?.window! {
      window.tintColor = redColor
    }

    cameraViewController.completionBlock = { [unowned cameraViewController] _, url in
      if let url = url {
        let video = Video(url: url)
        let photoEditModel = cameraViewController.photoEditModel
        cameraViewController.present(self.createCustomizedVideoEditViewController(with: video, configuration: configuration, and: photoEditModel), animated: true, completion: nil)
      }
    }

    present(cameraViewController, animated: true, completion: nil)
  }

  private func createCustomizedVideoEditViewController(with video: Video, configuration: Configuration, and photoEditModel: PhotoEditModel) -> VideoEditViewController {
    let videoEditViewController = VideoEditViewController(videoAsset: video, configuration: configuration, photoEditModel: photoEditModel)
    videoEditViewController.modalPresentationStyle = .fullScreen
    videoEditViewController.view.tintColor = UIColor(red: 0.11, green: 0.44, blue: 1.00, alpha: 1.00)
    videoEditViewController.toolbar.backgroundColor = UIColor.gray
    videoEditViewController.delegate = self

    return videoEditViewController
  }

  // MARK: - Customization

  fileprivate let whiteColor = UIColor(red: 0.941, green: 0.980, blue: 0.988, alpha: 1)
  fileprivate let redColor = UIColor(red: 0.988, green: 0.173, blue: 0.357, alpha: 1)
  fileprivate let blueColor = UIColor(red: 0.243, green: 0.769, blue: 0.831, alpha: 1)

  fileprivate func customizeTextTool() {
    let fonts = [
      Font(displayName: "Arial", fontName: "ArialMT", identifier: "Arial"),
      Font(displayName: "Helvetica", fontName: "Helvetica", identifier: "Helvetica"),
      Font(displayName: "Avenir", fontName: "Avenir-Heavy", identifier: "Avenir-Heavy"),
      Font(displayName: "Chalk", fontName: "Chalkduster", identifier: "Chalkduster"),
      Font(displayName: "Copperplate", fontName: "Copperplate", identifier: "Copperplate"),
      Font(displayName: "Noteworthy", fontName: "Noteworthy-Bold", identifier: "Notewortyh")
    ]

    FontImporter.all = fonts
  }

  fileprivate func customizeCameraController(_ builder: ConfigurationBuilder) {
    builder.configureCameraViewController { options in
      // Enable/Disable some features
      options.cropToSquare = true
      options.showFilterIntensitySlider = false
      options.tapToFocusEnabled = false

      // Use closures to customize the different view elements
      options.cameraRollButtonConfigurationClosure = { button in
        button.layer.borderWidth = 2.0
        button.layer.borderColor = self.redColor.cgColor
      }

      options.timeLabelConfigurationClosure = { label in
        label.textColor = self.redColor
      }

      options.recordingModeButtonConfigurationClosure = { button, _ in
        button.setTitleColor(UIColor.gray, for: .normal)
        button.setTitleColor(self.redColor, for: .selected)
      }

      // Force a selfie camera
      options.allowedCameraPositions = [.front]

      // Disable flash
      options.allowedFlashModes = [.off]
    }
  }

  fileprivate func customizeVideoEditorViewController(_ builder: ConfigurationBuilder) {
    // Customize the main editor
    builder.configureVideoEditViewController { options in
      options.titleViewConfigurationClosure = { titleView in
        if let titleLabel = titleView as? UILabel {
          titleLabel.text = "Selfie-Editor"
        }
      }

      options.actionButtonConfigurationClosure = { cell, _ in
        cell.contentTintColor = UIColor.red
      }
    }
  }
}

extension ViewController: VideoEditViewControllerDelegate {
  func videoEditViewController(_ videoEditViewController: VideoEditViewController, didFinishWithVideoAt url: URL?) {
    dismiss(animated: true, completion: nil)
  }

  func videoEditViewControllerDidFailToGenerateVideo(_ videoEditViewController: VideoEditViewController) {
    dismiss(animated: true, completion: nil)
  }

  func videoEditViewControllerDidCancel(_ videoEditViewController: VideoEditViewController) {
    dismiss(animated: true, completion: nil)
  }
}
