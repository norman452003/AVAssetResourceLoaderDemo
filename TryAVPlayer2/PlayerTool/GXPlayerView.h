//
//  GXPlayerView.h
//  TryAVPlayer2
//
//  Created by gongxin on 17/1/10.
//  Copyright © 2017年 gongxin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface GXPlayerView : UIView

- (void)setPlayer:(AVPlayer *)player;

- (void)setLoaderProgress:(CGFloat)progress;
- (void)setPlayProgress:(CGFloat)progress;


@property (nonatomic, copy) void (^dragBegin)();
@property (nonatomic, copy) void (^dragEnd)(CGFloat value);

@end
