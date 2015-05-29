//
//  ViewController.m
//  RDTSampleGeoAndMotion
//
//  Created by 高浜 一道 on 2015/05/29.
//  Copyright (c) 2015年 ROADTO. All rights reserved.
//

#import "ViewController.h"

#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface ViewController () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLCircularRegion *geoRegion;
@property (nonatomic, strong) CMMotionActivityManager *motionActivityManager;
@property (nonatomic, strong) UITextView *textViewDebug;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //CLLocationManager初期化
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    self.locationManager.activityType = CLActivityTypeFitness;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.distanceFilter = 100.0;
    self.locationManager.delegate = self;
    
    //Region初期化
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(37.324540, -122.041241);//アメリカ（クパチーノ）
    CLLocationDistance radiusOnMeter = 100.0;//範囲指定
    self.geoRegion = [[CLCircularRegion alloc] initWithCenter:coordinate
                                                       radius:radiusOnMeter
                                                   identifier:@"jp.roadto.ROADTO-Geo"];
    
    //位置情報の許可状況に合わせて動作開始
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        // iOS8
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusNotDetermined:
                NSLog(@"位置情報の許可が未設定なのでユーザに確認する");
                [self.locationManager requestAlwaysAuthorization];
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
                NSLog(@"「常に許可」されている");
                break;
            case kCLAuthorizationStatusAuthorizedWhenInUse:
            case kCLAuthorizationStatusDenied:
            case kCLAuthorizationStatusRestricted:
                NSLog(@"「常に許可」されていない");
                break;
        }
    } else {
        // iOS7以下
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark - CLLocationManagerDelegate
// アプリの位置情報の許可状態ステータスが変更されたときに通知される
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            NSLog(@"「常に許可」");
            [self.locationManager startMonitoringForRegion:self.geoRegion];
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            NSLog(@"「常に許可」されなかった");
            break;
    }
}

//領域監視がスタートしたときに通知
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    //現在の領域状態を確認
    [self.locationManager requestStateForRegion:region];
}

//領域内に入ったときに通知
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"領域内になったよ");
    
    //モーションセンサー 開始（バックグラウンド時にモーションセンサーをトリガーして動作させる）
    [self startMotionActivity];
}

//領域の状態について通知。状態が変わるたびに呼び出される。
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    switch (state) {
        case CLRegionStateInside:
            NSLog(@"領域内");
            
            //モーションセンサー 開始
            [self startMotionActivity];
            
            break;
        case CLRegionStateOutside:
            NSLog(@"領域外");
            break;
        case CLRegionStateUnknown:
            NSLog(@"わからない");
            break;
        default:
            break;
    }
}

//領域から出たことを通知
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"領域外になったよ");
    
    //モーションセンサー 停止
    [self stopMotionActivity];
}

#pragma mark - モーションセンサー
//モーションセンサー 初期化
- (CMMotionActivityManager *)getActivityManager {
    if (!self.motionActivityManager) {
        self.motionActivityManager = [[CMMotionActivityManager alloc] init];
    }
    return self.motionActivityManager;
}

//モーションセンサー 開始
- (void)startMotionActivity {
    NSLog(@"モーションセンサー 開始");
    
    //iOS7,8ともに必要
    [self.locationManager startUpdatingLocation];    //←キモ
    
    if([CMMotionActivityManager isActivityAvailable]){
        NSOperationQueue *queue = [NSOperationQueue mainQueue];
        CMMotionActivityManager *motionActivityManager = [self getActivityManager];
        [motionActivityManager startActivityUpdatesToQueue:queue withHandler:^(CMMotionActivity *motionActivity){
            
            //do something
            NSString *log = [NSString stringWithFormat:@"motion %@", motionActivity.walking ? @"そうだね。プロテインだね。" : @"んーんーんー。"];
            NSLog(log);
            [self showDebug:log];
        }];
    }
}

//モーションセンサー 停止
- (void)stopMotionActivity {
    NSLog(@"モーションセンサー 停止");
    CMMotionActivityManager *motionActivityManagerUpdate = [self getActivityManager];
    [motionActivityManagerUpdate stopActivityUpdates];
}

#pragma mark - デバッグ用レイヤー表示
- (void)showDebug:(NSString *)logMsg {
    if (!self.textViewDebug) {
        self.textViewDebug = [[UITextView alloc]init];
        CGRect rect = [[UIScreen mainScreen] bounds];
        rect.origin.y = 20;
        rect.size.height -= 20;
        self.textViewDebug.frame = rect;
        self.textViewDebug.backgroundColor = [UIColor blackColor];
        self.textViewDebug.alpha = 0.5;
        self.textViewDebug.textColor = [UIColor whiteColor];
        self.textViewDebug.editable = NO;
        [self.view addSubview:self.textViewDebug];
    }
    
    NSString *str = self.textViewDebug.text;
    if (str.length > 1500) {
        str = [str substringToIndex:1500];
    }
    self.textViewDebug.text = [NSString stringWithFormat:@"%@\n%@", logMsg, str];
}

@end
