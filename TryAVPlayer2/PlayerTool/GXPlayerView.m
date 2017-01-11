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
@property (nonatomic, strong) UIView *lineView;


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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.slideView insertSubview:self.lineView atIndex:1];
    });
}

- (void)setLoaderProgress:(CGFloat)progress{
    self.lineView.width = progress * self.width;
}

- (void)setPlayProgress:(CGFloat)progress{
    self.slideView.value = progress;
}

- (UISlider *)slideView{
    if (_slideView == nil) {
        _slideView = [[UISlider alloc] initWithFrame:CGRectMake(0, self.bottom - 40, self.width, 31)];
        [_slideView addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [_slideView addTarget:self action:@selector(dragInside) forControlEvents:UIControlEventTouchDragInside];
        [_slideView addTarget:self action:@selector(dragOutside) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _slideView;
}

- (UIView *)lineView{
    if (_lineView == nil) {
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, _slideView.height * 0.5, 0, 1)];
        _lineView.backgroundColor = [UIColor blackColor];
    }
    return _lineView;
}

- (void)touchDown{
    if (self.dragBegin) {
        self.dragBegin();
    }
}

- (void)dragInside{
}

- (void)dragOutside{
    if (self.dragEnd) {
        self.dragEnd(self.slideView.value);
    }
}

@end
