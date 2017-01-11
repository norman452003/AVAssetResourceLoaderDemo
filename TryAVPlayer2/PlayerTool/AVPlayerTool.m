//
//  AVPlayerTool.m
//  TryAVPlayer2
//
//  Created by gongxin on 17/1/10.
//  Copyright © 2017年 gongxin. All rights reserved.
//

#import "AVPlayerTool.h"
#import "GXVideoPlayerTask.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface AVPlayerTool () <AVAssetResourceLoaderDelegate,GXVideoPlayerTaskDelegate>
@property (nonatomic, strong ,readwrite) AVPlayer *player;
@property (nonatomic, strong) NSURL *originalURL;
@property (nonatomic, strong) NSURL *schemeURL;

@property (nonatomic, strong) NSMutableArray *pendingArray;
@property (nonatomic, copy  ) NSString       *videoPath;
@property (nonatomic, strong) GXVideoPlayerTask *task;
@property (nonatomic, strong) AVPlayerItem *item;
@property (nonatomic, assign) BOOL hasCache;
@property (nonatomic, strong) NSDictionary *infoDict;
@property (nonatomic, strong) NSData *cacheData;


@end

@implementation AVPlayerTool


#pragma mark - public method

+ (instancetype)sharedPlayerTool{
    static AVPlayerTool *tool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [AVPlayerTool new];
    });
    return tool;
}

- (void)playWithURL:(NSURL *)url{
    
    self.pendingArray = [NSMutableArray array];
    self.originalURL = url;
    NSString *document = NSTemporaryDirectory();
    _videoPath = [document stringByAppendingPathComponent:self.originalURL.absoluteString.lastPathComponent];
    self.schemeURL = [self addSchemeToURL:url];
    AVURLAsset *asset = [AVURLAsset assetWithURL:self.schemeURL];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    self.item = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [AVPlayer playerWithPlayerItem:self.item];
    [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    [self.item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:NULL];
    
    __weak typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (weakSelf.resourcePlayProgress) {
            CGFloat current = CMTimeGetSeconds(time);
            CGFloat duration = CMTimeGetSeconds(weakSelf.item.duration);
            weakSelf.resourcePlayProgress(current/duration);
        }
    }];
    
    [self checkLocalCache];
}

- (void)pause{
    [self.player pause];
}

- (void)seekToPlayValue:(CGFloat)value{
    CMTime duration = self.item.duration;
    CMTime time = CMTimeMake(value * duration.value, duration.timescale);
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:time completionHandler:^(BOOL finished) {
        if (finished) {
            [weakSelf.player play];
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if (object == self.item && [keyPath isEqualToString:@"status"]) {
        if (self.item.status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"ready to play");
            [self.player play];
        }else{
            NSLog(@"pause");
            [self.player pause];
        }
    }else if (object == self.item && [keyPath isEqualToString:@"loadedTimeRanges"]){
        [self dealWithPlayerItemProgress];
    }
}

- (NSURL *)addSchemeToURL:(NSURL *)url{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    components.scheme = @"streaming";
    return [components URL];
}

#pragma mark - resourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    if (self.hasCache) {
        loadingRequest.contentInformationRequest.contentLength = [[self.infoDict valueForKey:@"length"] longLongValue];
        loadingRequest.contentInformationRequest.contentType = [self.infoDict valueForKey:@"type"];
        loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
        
        NSRange range = NSMakeRange(loadingRequest.dataRequest.currentOffset, loadingRequest.dataRequest.requestedLength);
        NSData *subData = [self.cacheData subdataWithRange:range];
        [loadingRequest.dataRequest respondWithData:subData];
        [loadingRequest finishLoading];
        
        return YES;
    }
    [self.pendingArray addObject:loadingRequest];
    [self dealWithLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self.pendingArray removeObject:loadingRequest];
}

- (void)dealWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    
    NSRange range = NSMakeRange((NSUInteger)loadingRequest.dataRequest.currentOffset, NSUIntegerMax);
    if (self.task.downLoadingOffset > 0) {
        [self processPendingRequests];
    }
    
    if (!self.task) {
        self.task = [[GXVideoPlayerTask alloc] initWithURL:self.schemeURL];
        self.task.delegate = self;
        [self.task setUrl:self.originalURL offset:0];
    } else {
        // 如果新的rang的起始位置比当前缓存的位置还大300k，则重新按照range请求数据
        if (self.task.offset + self.task.downLoadingOffset + 1024 * 300 < range.location ||
            // 如果往回拖也重新请求
            range.location < self.task.offset) {
            [self.task setUrl:self.originalURL offset:range.location];
        }
    }
}

- (void)processPendingRequests
{
    NSMutableArray *requestsCompleted = [NSMutableArray array];  //请求完成的数组
    //每次下载一块数据都是一次请求，把这些请求放到数组，遍历数组
    for (AVAssetResourceLoadingRequest *loadingRequest in self.pendingArray)
    {
        [self fillInContentInformation:loadingRequest.contentInformationRequest]; //对每次请求加上长度，文件类型等信息
        
        BOOL didRespondCompletely = [self respondWithDataForRequest:loadingRequest.dataRequest]; //判断此次请求的数据是否处理完全
        if (didRespondCompletely) {
//            NSLog(@"loadingRequest finish%lld",loadingRequest.dataRequest.currentOffset);
            
            [requestsCompleted addObject:loadingRequest];  //如果完整，把此次请求放进 请求完成的数组
            [loadingRequest finishLoading];
        }
    }
    
    [self.pendingArray removeObjectsInArray:requestsCompleted];   //在所有请求的数组中移除已经完成的
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
    if (self.hasCache) {
        return;
    }
    NSString *mimeType = self.task.mimeType;
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(mimeType), NULL);
    contentInformationRequest.byteRangeAccessSupported = YES;
    contentInformationRequest.contentType = CFBridgingRelease(contentType);
    contentInformationRequest.contentLength = self.task.videoLength;
}

- (BOOL)respondWithDataForRequest:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    long long startOffset = dataRequest.requestedOffset;
    
    if (dataRequest.currentOffset != 0) {
        startOffset = dataRequest.currentOffset;
    }
    
    if ((self.task.offset +self.task.downLoadingOffset) < startOffset)
    {
        //NSLog(@"NO DATA FOR REQUEST");
        return NO;
    }
    
    if (startOffset < self.task.offset) {
        return NO;
    }
    
    NSData *filedata = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_videoPath] options:NSDataReadingMappedIfSafe error:nil];
    
    // This is the total data we have from startOffset to whatever has been downloaded so far
    NSUInteger unreadBytes = self.task.downLoadingOffset - ((NSInteger)startOffset - self.task.offset);
    
    // Respond with whatever is available if we can't satisfy the request fully yet
    NSUInteger numberOfBytesToRespondWith = MIN((NSUInteger)dataRequest.requestedLength, unreadBytes);
    
    [dataRequest respondWithData:[filedata subdataWithRange:NSMakeRange((NSUInteger)startOffset- self.task.offset, (NSUInteger)numberOfBytesToRespondWith)]];

    long long endOffset = startOffset + dataRequest.requestedLength;
    BOOL didRespondFully = (self.task.offset + self.task.downLoadingOffset) >= endOffset;
    
    return didRespondFully;
}

- (void)didReceiveVideoDataWithTask:(GXVideoPlayerTask *)task{
    [self processPendingRequests];
}

- (void)didFinishLoadingWithTask:(GXVideoPlayerTask *)task{

}


- (void)dealWithPlayerItemProgress{
    NSArray *timeRanges = [self.item loadedTimeRanges];
    if (!timeRanges.count) {
        return;
    }
    CMTimeRange timeRange = [timeRanges.firstObject CMTimeRangeValue];
    float startTime = CMTimeGetSeconds(timeRange.start);
    float durationTime = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval timeRangeInterval = startTime + durationTime;
    float totalDuration = CMTimeGetSeconds(self.item.duration);
    float loadItemProgress = timeRangeInterval/totalDuration;
    if (self.resourceLoadProgress) {
        self.resourceLoadProgress(loadItemProgress);
    }
}

- (void)checkLocalCache{
    if ([[NSFileManager defaultManager] fileExistsAtPath:_videoPath]) {
        NSString *infoCache = [[[NSTemporaryDirectory() stringByAppendingPathComponent:self.originalURL.absoluteString.lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"info"];
        self.infoDict = [[NSDictionary alloc] initWithContentsOfFile:infoCache];
        self.cacheData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_videoPath] options:NSDataReadingMappedIfSafe error:nil];
        long resourceLength = [self.infoDict[@"length"] longValue];
        if (resourceLength == self.cacheData.length) {
            self.hasCache = YES;
        }
    }
}

@end
