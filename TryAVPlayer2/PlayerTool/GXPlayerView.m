//
//  GXPlayerView.m
//  TryAVPlayer2
//
//  Created by gongxin on 17/1/10.
//  Copyright © 2017年 gongxin. All rights reserved.
//

#import "GXPlayerView.h"

@implementation GXPlayerView

+ (Class)layerClass{
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)layer{
    [(AVPlayerLayer *)self.layer setPlayer:layer];
}

@end
