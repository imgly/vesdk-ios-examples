#import "ViewController.h"
@import CoreLocation;
@import VideoEditorSDK;

@interface ViewController () <PESDKVideoEditViewControllerDelegate>

@property (nonatomic, retain) PESDKTheme *theme;
@property (nonatomic, retain) PESDKOpenWeatherProvider *weatherProvider;

@end

@implementation ViewController

@synthesize theme;
@synthesize weatherProvider;

#pragma mark - UIViewController

- (void)viewDidLoad {
  theme = PESDKTheme.dynamic;
  PESDKTemperatureFormat unit = PESDKTemperatureFormatLocale;
  weatherProvider = [[PESDKOpenWeatherProvider alloc] initWithApiKey:nil unit:unit];
  weatherProvider.locationAccessRequestClosure = ^(CLLocationManager * _Nonnull locationManager) {
    [locationManager requestWhenInUseAuthorization];
  };
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == 0) {
    [self presentVideoEditViewController];
  } else if (indexPath.row == 1) {
    theme = PESDKTheme.light;
    [self presentVideoEditViewController];
    theme = PESDKTheme.dynamic;
  } else if (indexPath.row == 2) {
    theme = PESDKTheme.dark;
    [self presentVideoEditViewController];
    theme = PESDKTheme.dynamic;
  } else if (indexPath.row == 3) {
    [self pushVideoEditViewController];
  } else if (indexPath.row == 4) {
    [self presentCameraViewController];
  }
}

- (BOOL)prefersStatusBarHidden {
  // Before changing `prefersStatusBarHidden` please read the comment below
  // in `viewDidAppear`.
  return true;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  // This is a workaround for a bug in iOS 13 on devices without a notch
  // where pushing a `UIViewController` (with status bar hidden) from a
  // `UINavigationController` (status bar not hidden or vice versa) would
  // result in a gap above the navigation bar (on the `UIViewController`)
  // and a smaller navigation bar on the `UINavigationController`.
  //
  // This is the case when a `MediaEditViewController` is embedded into a
  // `UINavigationController` and uses a different `prefersStatusBarHidden`
  // setting as the parent view.
  //
  // Setting `prefersStatusBarHidden` to `false` would cause the navigation
  // bar to "jump" after the view appeared but this seems to be the only chance
  // to fix the layout.
  //
  // For reference see: https://forums.developer.apple.com/thread/121861#378841
  [self.navigationController.view setNeedsLayout];
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
      NSMutableArray<PESDKPhotoEditMenuItem *> *menuItems = [PESDKPhotoEditMenuItem.defaultItems mutableCopy];
      [menuItems exchangeObjectAtIndex:0 withObjectAtIndex:1]; // Swap first two tools
      options.menuItems = menuItems;
    }];

    // Configure sticker tool
    [builder configureStickerToolController:^(PESDKStickerToolControllerOptionsBuilder * _Nonnull options) {
      // Enable personal stickers
      options.personalStickersEnabled = true;
      // Enable smart weather stickers
      options.weatherProvider = self.weatherProvider;
    }];

    // Configure theme
    builder.theme = self.theme;
  }];

  return configuration;
}

#pragma mark - Presentation

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
  NSURL *url = [NSBundle.mainBundle URLForResource:@"Skater" withExtension:@"mp4"];
  PESDKVideo *video = [[PESDKVideo alloc] initWithURL:url];
  [self presentViewController:[self createVideoEditViewControllerWithVideo:video] animated:YES completion:nil];
}

- (void)pushVideoEditViewController {
  NSURL *url = [NSBundle.mainBundle URLForResource:@"Skater" withExtension:@"mp4"];
  PESDKVideo *video = [[PESDKVideo alloc] initWithURL:url];
  [self.navigationController pushViewController:[self createVideoEditViewControllerWithVideo:video] animated:YES];
}

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
  cameraViewController.completionBlock = ^(PESDKCameraResult * _Nonnull result) {
    if (result.url != nil) {
      PESDKVideo *video = [[PESDKVideo alloc] initWithURL:result.url];
      PESDKPhotoEditModel *photoEditModel = [weakCameraViewController photoEditModel];
      [weakCameraViewController presentViewController:[self createVideoEditViewControllerWithVideo:video and:photoEditModel] animated:YES completion:nil];
    }
  };

  [self presentViewController:cameraViewController animated:YES completion:nil];
}

#pragma mark - VideoEditViewControllerDelegate

- (BOOL)videoEditViewControllerShouldStart:(PESDKVideoEditViewController * _Nonnull)videoEditViewController task:(PESDKVideoEditorTask * _Nonnull)task {
  // Implementing this method is optional. You can perform additional validation and interrupt the process by returning `NO`.
  return YES;
}

 - (void)videoEditViewControllerDidFinish:(PESDKVideoEditViewController * _Nonnull)videoEditViewController result:(PESDKVideoEditorResult * _Nonnull)result {
  if (videoEditViewController.navigationController != nil) {
    [videoEditViewController.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)videoEditViewControllerDidFail:(PESDKVideoEditViewController * _Nonnull)videoEditViewController error:(PESDKVideoEditorError * _Nonnull)error {
  if (videoEditViewController.navigationController != nil) {
    [videoEditViewController.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)videoEditViewControllerDidCancel:(PESDKVideoEditViewController * _Nonnull)videoEditViewController {
  if (videoEditViewController.navigationController != nil) {
    [videoEditViewController.navigationController popViewControllerAnimated:YES];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

@end
