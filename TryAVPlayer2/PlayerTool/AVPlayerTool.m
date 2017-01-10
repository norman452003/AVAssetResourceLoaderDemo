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
@property (nonatomic, strong) NSMutableArray *pendingArray;
@property (nonatomic, copy  ) NSString       *videoPath;
@property (nonatomic, strong) GXVideoPlayerTask *task;
@end

@implementation AVPlayerTool

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
    NSURL *schemeURL = [self addSchemeToURL:url];
    AVURLAsset *asset = [AVURLAsset assetWithURL:schemeURL];
    [asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    self.player = [AVPlayer playerWithPlayerItem:item];
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
//    NSString *document = NSTemporaryDirectory();
//    _videoPath = [document stringByAppendingPathComponent:self.originalURL.absoluteString.lastPathComponent];
    _videoPath = [document stringByAppendingPathComponent:@"temp.mp4"];
    
}

- (NSURL *)addSchemeToURL:(NSURL *)url{
    NSString *urlStr = [NSString stringWithFormat:@"head:%@",url];
    return [NSURL URLWithString:urlStr];
}

#pragma mark - resourceLoaderDelegate
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self.pendingArray addObject:loadingRequest];
    [self dealWithLoadingRequest:loadingRequest];
    return YES;
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest{
    [self.pendingArray removeObject:loadingRequest];
}

- (void)dealWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    NSURL *interceptedURL = [loadingRequest.request URL];
    NSRange range = NSMakeRange((NSUInteger)loadingRequest.dataRequest.currentOffset, NSUIntegerMax);
    NSLog(@"1======%@",NSStringFromRange(range));
    if (self.task.downLoadingOffset > 0) {
        [self processPendingRequests];
    }
    
    if (!self.task) {
        self.task = [[GXVideoPlayerTask alloc] init];
        self.task.delegate = self;
        [self.task setUrl:self.originalURL offset:0];
    } else {
        // 如果新的rang的起始位置比当前缓存的位置还大300k，则重新按照range请求数据
        if (self.task.offset + self.task.downLoadingOffset + 1024 * 300 < range.location ||
            // 如果往回拖也重新请求
            range.location < self.task.offset) {
            NSLog(@"2======%@",NSStringFromRange(range));
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
            NSLog(@"%@",loadingRequest);
            
            [requestsCompleted addObject:loadingRequest];  //如果完整，把此次请求放进 请求完成的数组
            [loadingRequest finishLoading];
            
        }
    }
    
    [self.pendingArray removeObjectsInArray:requestsCompleted];   //在所有请求的数组中移除已经完成的
}

- (void)fillInContentInformation:(AVAssetResourceLoadingContentInformationRequest *)contentInformationRequest
{
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

@end
