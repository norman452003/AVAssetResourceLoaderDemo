//
//  GXVideoPlayerTask.h
//  TryAVPlayer2
//
//  Created by gongxin on 17/1/10.
//  Copyright © 2017年 gongxin. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GXVideoPlayerTaskDelegate;

@interface GXVideoPlayerTask : NSObject

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, readonly) NSUInteger offset;

@property (nonatomic, readonly) NSUInteger videoLength;
@property (nonatomic, readonly) NSUInteger downLoadingOffset;
@property (nonatomic, strong, readonly) NSString* mimeType;
@property (nonatomic, assign) BOOL isFinishLoad;

@property (nonatomic, weak) id <GXVideoPlayerTaskDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)url;

- (void)setUrl:(NSURL *)url offset:(NSUInteger)offset;

- (void)cancel;

- (void)continueLoading;

- (void)clearData;
@end


@protocol GXVideoPlayerTaskDelegate <NSObject>

- (void)didReceiveVideoDataWithTask:(GXVideoPlayerTask *)task;
@optional
- (void)task:(GXVideoPlayerTask *)task didReceiveVideoLength:(NSUInteger)ideoLength mimeType:(NSString *)mimeType;
- (void)didFinishLoadingWithTask:(GXVideoPlayerTask *)task;
- (void)didFailLoadingWithTask:(GXVideoPlayerTask *)task WithError:(NSInteger )errorCode;

@end
