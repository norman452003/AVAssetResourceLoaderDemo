//
//  ViewController.m
//  TryAVPlayer2
//
//  Created by gongxin on 17/1/10.
//  Copyright © 2017年 gongxin. All rights reserved.
//

#import "ViewController.h"
#import "AVPlayerTool.h"
#import "GXPlayerView.h"
@import AVFoundation;

@interface ViewController ()

@property (nonatomic, strong) GXPlayerView *playerView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setUpPlayer];
}

- (void)setUpPlayer{
    
    //http://s.same.com/track/3502224-151991e8.mp3
    //https://mvvideo5.meitudata.com/56ea0e90d6cb2653.mp4
    //http://data.5sing.kgimg.com/G061/M0A/03/13/HZQEAFb493iAOeg5AHMiAfzZU0E739.mp3
    //http://m9.play.vp.autohome.com.cn/flvs/FF91E122A113F07F/2017-01-10/5C76C412F39F59A3-400.m3u8?key=A4B06DC2ACB0F89AED56648DF9D54099&time=1484120350
    [[AVPlayerTool sharedPlayerTool] playWithURL:[NSURL URLWithString:@"http://s.same.com/track/3502224-151991e8.mp3"]];
    self.playerView = [[GXPlayerView alloc] initWithFrame:self.view.bounds];
    self.playerView.backgroundColor = [UIColor lightGrayColor];
    [self.playerView setPlayer:[AVPlayerTool sharedPlayerTool].player];
    [self.view addSubview:self.playerView];
    
    __weak typeof(self) weakSelf = self;
    [AVPlayerTool sharedPlayerTool].resourceLoadProgress = ^(CGFloat progress){
        [weakSelf.playerView setLoaderProgress:progress];
    };
    
    [AVPlayerTool sharedPlayerTool].resourcePlayProgress = ^(CGFloat progress){
        [weakSelf.playerView setPlayProgress:progress];
    };
    
    self.playerView.dragBegin = ^{
        [weakSelf handleSlideBeginEvent];
    };
    
    self.playerView.dragEnd = ^(CGFloat value){
        [weakSelf handleSlideEndEventWithValue:value];
    };
    
}

- (void)handleSlideBeginEvent{
    [[AVPlayerTool sharedPlayerTool] pause];
}

- (void)handleSlideEndEventWithValue:(CGFloat)value{
    [[AVPlayerTool sharedPlayerTool] seekToPlayValue:value];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
