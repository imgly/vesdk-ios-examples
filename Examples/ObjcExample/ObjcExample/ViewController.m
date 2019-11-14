//  This file is part of the VideoEditor Software Development Kit.
//  Copyright (C) 2016-2019 img.ly GmbH <contact@img.ly>
//  All rights reserved.
//  Redistribution and use in source and binary forms, without
//  modification, are permitted provided that the following license agreement
//  is approved and a legal/financial contract was signed by the user.
//  The license agreement can be found under the following link:
//  https://www.videoeditorsdk.com/LICENSE.txt

#import "ViewController.h"
@import CoreLocation;
@import VideoEditorSDK;

@interface ViewController () <PESDKVideoEditViewControllerDelegate>

@property (nonatomic, retain) PESDKTheme *theme;

@end

@implementation ViewController

@synthesize theme;

#pragma mark - UIViewController

- (void)viewDidLoad {
  if (@available(iOS 13.0, *)) {
    theme = PESDKTheme.dynamic;
  } else {
    theme = PESDKTheme.dark;
  }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    [self presentCameraViewController];
  } else if (indexPath.row == 1) {
    [self presentVideoEditViewController];
  } else if (indexPath.row == 2) {
    theme = PESDKTheme.light;
    [self presentVideoEditViewController];
    if (@available(iOS 13.0, *)) {
      theme = PESDKTheme.dynamic;
    } else {
      theme = PESDKTheme.dark;
    }
  } else if (indexPath.row == 3) {
    theme = PESDKTheme.dark;
    [self presentVideoEditViewController];
    if (@available(iOS 13.0, *)) {
      theme = PESDKTheme.dynamic;
    } else {
      theme = PESDKTheme.dark;
    }
  } else if (indexPath.row == 4) {
    [self pushVideoEditViewController];
  }
}

#pragma mark - Configuration

- (PESDKConfiguration *)buildConfiguration {
  PESDKConfiguration *configuration = [[PESDKConfiguration alloc] initWithBuilder:^(PESDKConfigurationBuilder * _Nonnull builder) {
    // Configure camera
    [builder configureCameraViewController:^(PESDKCameraViewControllerOptionsBuilder * _Nonnull options) {
      // Just enable videos
      options.allowedRecordingModes = @[@(RecordingModeVideo)];
      // Show cancel button
      options.showCancelButton = true;
    }];

    // Configure editor
    [builder configureVideoEditViewController:^(PESDKVideoEditViewControllerOptionsBuilder * _Nonnull options) {
      NSMutableArray<PESDKPhotoEditMenuItem *> *menuItems = [[PESDKPhotoEditMenuItem defaultItems] mutableCopy];
      [menuItems exchangeObjectAtIndex:0 withObjectAtIndex:1]; // Swap first two tools
      options.menuItems = menuItems;
    }];

    // Configure sticker tool
    [builder configureStickerToolController:^(PESDKStickerToolControllerOptionsBuilder * _Nonnull options) {
      // Enable personal stickers
      options.personalStickersEnabled = true;
    }];

    // Configure theme
    builder.theme = self.theme;
  }];

  return configuration;
}

#pragma mark - Presentation

- (void)presentCameraViewController {
  PESDKConfiguration *configuration = [self buildConfiguration];
  PESDKCameraViewController *cameraViewController = [[PESDKCameraViewController alloc] initWithConfiguration:configuration];
  cameraViewController.modalPresentationStyle = UIModalPresentationFullScreen;
  cameraViewController.locationAccessRequestClosure = ^(CLLocationManager * _Nonnull locationManager) {
    [locationManager requestWhenInUseAuthorization];
  };

  __weak PESDKCameraViewController *weakCameraViewController = cameraViewController;
  cameraViewController.cancelBlock = ^{
    [self dismissViewControllerAnimated:YES completion:nil];
  };
  cameraViewController.completionBlock = ^(UIImage * _Nullable image, NSURL * _Nullable url) {
    if (url != nil) {
      PESDKVideo *video = [[PESDKVideo alloc] initWithURL:url];
      PESDKPhotoEditModel *photoEditModel = [weakCameraViewController photoEditModel];
      [weakCameraViewController presentViewController:[self createVideoEditViewControllerWithVideo:video and:photoEditModel] animated:YES completion:nil];
    }
  };

  [self presentViewController:cameraViewController animated:YES completion:nil];
}

- (PESDKVideoEditViewController *)createVideoEditViewControllerWithVideo:(PESDKVideo *)video {
  return [self createVideoEditViewControllerWithVideo:video and:[[PESDKPhotoEditModel alloc] init]];
}

- (PESDKVideoEditViewController *)createVideoEditViewControllerWithVideo:(PESDKVideo *)video and:(PESDKPhotoEditModel *)photoEditModel {
  PESDKConfiguration *configuration = [self buildConfiguration];

  // Create a video edit view controller
  PESDKVideoEditViewController *videoEditViewController = [[PESDKVideoEditViewController alloc] initWithVideoAsset:video configuration:configuration photoEditModel:photoEditModel];
  videoEditViewController.modalPresentationStyle = UIModalPresentationFullScreen;
  videoEditViewController.delegate = self;

  return videoEditViewController;
}

- (void)presentVideoEditViewController {
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"Skater" withExtension:@"mp4"];
  PESDKVideo *video = [[PESDKVideo alloc] initWithURL:url];
  [self presentViewController:[self createVideoEditViewControllerWithVideo:video] animated:YES completion:nil];
}

- (void)pushVideoEditViewController {
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"Skater" withExtension:@"mp4"];
  PESDKVideo *video = [[PESDKVideo alloc] initWithURL:url];
  [self.navigationController pushViewController:[self createVideoEditViewControllerWithVideo:video] animated:YES];
}

#pragma mark - VideoEditViewControllerDelegate

- (void)videoEditViewController:(PESDKVideoEditViewController *)videoEditViewController didFinishWithVideoAtURL:(NSURL *)url {
  if (videoEditViewController.navigationController != nil) {
    [videoEditViewController.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)videoEditViewControllerDidFailToGenerateVideo:(PESDKVideoEditViewController *)videoEditViewController {
  if (videoEditViewController.navigationController != nil) {
    [videoEditViewController.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)videoEditViewControllerDidCancel:(PESDKVideoEditViewController *)videoEditViewController {
  if (videoEditViewController.navigationController != nil) {
    [videoEditViewController.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

@end
