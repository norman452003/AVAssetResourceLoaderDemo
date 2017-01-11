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
    [[AVPlayerTool sharedPlayerTool] playWithURL:[NSURL URLWithString:@"https://mvvideo5.meitudata.com/56ea0e90d6cb2653.mp4"]];
    GXPlayerView *playerView = [[GXPlayerView alloc] initWithFrame:self.view.bounds];
    playerView.backgroundColor = [UIColor lightGrayColor];
    [playerView setPlayer:[AVPlayerTool sharedPlayerTool].player];
    [self.view addSubview:playerView];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
