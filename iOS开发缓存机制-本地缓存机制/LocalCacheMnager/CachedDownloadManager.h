//
//  CachedDownloadManager.h
//  iOS开发缓存机制-本地缓存机制
//
//  Created by jrzhuxue on 16/12/5.
//  Copyright © 2016年 Brian_li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CacheItem.h"
@class CachedDownloadManager;

@protocol CachedDownloadManagerDelegate <NSObject>
- (void)cachedDownloadManagerSucceeded:(CachedDownloadManager *)paramSender
                             remoteURL:(NSURL *)paramRemoteURL
                              localURL:(NSURL *)paramLocalURL
                 aboutToBeReleasedData:(NSData *)paramAboutToBeReleasedData
                          isCachedData:(BOOL)paramIsCachedData;

- (void)cachedDownloadManagerFailed:(CachedDownloadManager *)paramSender
                          remoteURL:(NSURL *)paramRemoteURL
                           localURL:(NSURL *)paramLocalURL
                          withError:(NSError *)error;
@end

@interface CachedDownloadManager : NSObject <CacheItemDelegate>
{
@public
    __unsafe_unretained id <CachedDownloadManagerDelegate>  _delegate;
@private
    //记录缓存数据的字典
    NSMutableDictionary                *_cacheDictionary;
    //缓存的路径
    NSString                           *_cacheDictionaryPath;
}

@property (nonatomic, assign) id <CachedDownloadManagerDelegate> delegate;

@property (nonatomic, strong) NSMutableDictionary *cacheDictionary;

@property (nonatomic, copy) NSString *cacheDictionaryPath;

+ (instancetype)defaultCacheManager;

/* 保持缓存字典 */

- (BOOL) saveCacheDictionary;

/* 公有方法：下载 */

- (BOOL) download:(NSString *)paramURLAsString
        urlMustExpireInSeconds:(NSTimeInterval)paramURLMustExpireInSeconds
        updateExpiryDateIfInCache:(BOOL)paramUpdateExpiryDateIfInCache;
@end
