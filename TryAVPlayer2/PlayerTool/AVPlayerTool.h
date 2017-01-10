//
//  AVPlayerTool.h
//  TryAVPlayer2
//
//  Created by gongxin on 17/1/10.
//  Copyright © 2017年 gongxin. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVPlayerTool : NSObject

@property (nonatomic, strong ,readonly) AVPlayer *player;

+ (instancetype)sharedPlayerTool;

- (void)playWithURL:(NSURL *)url;



@end
