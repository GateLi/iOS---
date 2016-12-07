//
//  CacheItem.h
//  iOS开发缓存机制-本地缓存机制
//
//  Created by jrzhuxue on 16/12/5.
//  Copyright © 2016年 Brian_li. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CacheItem;

@protocol CacheItemDelegate <NSObject>
//下载成功执行该方法
- (void)cacheItemDelegateSucceeded:(CacheItem *)paramSender
                     withRemoteURL:(NSURL *)paramRemoteURL
         withAboutToBeReleasedData:(NSData *)paramAboutToBeReleasedData;

//下载失败执行该方法
- (void)cacheItemDelegateFailed:(CacheItem *)paramSender
                      remoteURL:(NSURL *)paramRemoteURL
                      withError:(NSError *)paramError;
@end


@interface CacheItem : NSObject
{
@public
    __unsafe_unretained id <CacheItemDelegate> _delegate;
@protected
    NSString *_remoteURL;
@private
    // 是否正在下载
    BOOL _isDownloading;
    // NSMutableData 对象
    NSMutableData *_connectionData;
    // NSURLConnection 对象
    NSURLConnection *_connection;
}
@property (nonatomic, assign) id <CacheItemDelegate> delegate;
@property (nonatomic, retain) NSString *remoteURL;
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, retain) NSMutableData *connectionData;
@property (nonatomic, retain) NSURLSession *session;

// 开始下载
- (void)startDownloadingURL:(NSString *)paramRemoteURL;
@end






















