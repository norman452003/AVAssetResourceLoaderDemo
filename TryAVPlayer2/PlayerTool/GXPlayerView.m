//
//  GXPlayerView.m
//  TryAVPlayer2
//
//  Created by gongxin on 17/1/10.
//  Copyright © 2017年 gongxin. All rights reserved.
//

#import "GXPlayerView.h"
#import "UIView+frameAdjust.h"

@interface GXPlayerView ()

@property (nonatomic, strong) UISlider *slideView;


@end

@implementation GXPlayerView

+ (Class)layerClass{
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)layer{
    [(AVPlayerLayer *)self.layer setPlayer:layer];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    [self addSubview:self.slideView];
}

- (UISlider *)slideView{
    if (_slideView == nil) {
        _slideView = [[UISlider alloc] initWithFrame:CGRectMake(0, self.bottom - 40, self.width, 31)];
        CGFloat lineY = _slideView.height * 0.5;
        UIView *progressLine = [[UIView alloc] initWithFrame:CGRectMake(0, lineY, 0, 1)];
        progressLine.backgroundColor = [UIColor blackColor];
        [_slideView insertSubview:progressLine atIndex:1];
    }
    return _slideView;
}

@end
