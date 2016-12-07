//
//  CachedDownloadManager.m
//  iOS开发缓存机制-本地缓存机制
//
//  Created by jrzhuxue on 16/12/5.
//  Copyright © 2016年 Brian_li. All rights reserved.
//

#import "CachedDownloadManager.h"

const NSString *CachedKeyExpiryDate = @"CachedKeyExpiryDate";
const NSString *CachedKeyDownloadEndDate = @"CachedKeyDownloadEndDate";
const NSString *CachedKeyDownloadStartDate = @"CachedKeyDownloadStartDate";
const NSString *CachedKeyLocalURL = @"CachedKeyLocalURL";
const NSString *CachedKeyExpiresInSeconds = @"CachedKeyExpiresInSeconds";

@implementation CachedDownloadManager
+ (instancetype)defaultCacheManager
{
    static CachedDownloadManager *downloadManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (downloadManager == nil) {
            downloadManager = [[CachedDownloadManager alloc] init];
        }
        [downloadManager initCacheDictionary];
    });
    
    return downloadManager;
}

- (NSString *)documentsDirectoryWithTrailingSlash:(BOOL)trailingSlash
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    if (trailingSlash) {
        return [documentPath stringByAppendingString:@"/"];
    }
    return documentPath;
}

- (void)initCacheDictionary {
    // 初始化缓存字典
    NSString *documentsDirectory = [self documentsDirectoryWithTrailingSlash:YES];
    // 生产缓存字典的路径
    self.cacheDictionaryPath = [documentsDirectory stringByAppendingString:@"CachedDownloads.dic"];
    // 创建一个NSFileManager 类
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 判断是否存在缓存字典的数据
    if ([fileManager fileExistsAtPath:self.cacheDictionaryPath] == YES) {
        NSLog(@"%@", self.cacheDictionaryPath);
        
        //加载缓存字典中的数据
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:
                                           self.cacheDictionaryPath];
        
        self.cacheDictionary = [dictionary mutableCopy];
        
        //移除没哟下载完成的缓存数据
        //[self removeCorruptedCachedItems];
    } else {
        //创建一个新的缓存字典
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc]  init];
        
        self.cacheDictionary = [dictionary mutableCopy];
    }
}

- (BOOL)download:(NSString *)paramURLAsString
    urlMustExpireInSeconds:(NSTimeInterval)paramURLMustExpireInSeconds
    updateExpiryDateIfInCache:(BOOL)paramUpdateExpiryDateIfInCache
{
    BOOL result = NO;
    /* 使用下面这些变量帮助我们理解缓存逻辑 */
    //文件是否已经被缓存
    BOOL    fileHasBeenCached = NO;
    //缓存是否过期
    BOOL    cachedFileHasExpired = NO;
    //缓存文件是否存在
    BOOL    cachedFileExists = NO;
    //缓存文件能否被加载
    BOOL    cachedFileDataCanBeLoaded = NO;
    //缓存文件数据
    NSData  *cachedFileData = nil;
    //缓存文件是否完全下载
    BOOL    cachedFileIsFullyDownloaded = NO;
    //缓存文件是否已经下载
    BOOL    cachedFileIsBeingDownloaded = NO;
    //过期时间
    NSDate    *expiryDate = nil;
    //下载结束时间
    NSDate    *downloadEndDate = nil;
    //下载开始时间
    NSDate    *downloadStartDate = nil;
    //本地缓存路径
    NSString  *localURL = nil;
    //有效时间
    NSNumber  *expiresInSeconds = nil;
    NSDate    *now = [NSDate date];
    
    
    if (self.cacheDictionary == nil || [paramURLAsString length] == 0){
        return NO;
    }
    
    paramURLAsString = [paramURLAsString lowercaseString];
    //根据url，从字典中获取缓存项的相关数据
    NSMutableDictionary *itemDictionary = [self.cacheDictionary objectForKey:paramURLAsString];
    
    if (itemDictionary != nil){
        fileHasBeenCached = YES;
    }
    //如果文件已经被缓存，则从缓存项相关数据中获取相关的值
    if (fileHasBeenCached == YES){
        // 过期日期
        expiryDate = [itemDictionary objectForKey:CachedKeyExpiryDate];
        // 下载结束日期
        downloadEndDate = [itemDictionary objectForKey:CachedKeyDownloadEndDate];
        // 下载开始日期
        downloadStartDate = [itemDictionary objectForKey:CachedKeyDownloadStartDate];
        // 存储的本地路径
        localURL = [itemDictionary objectForKey:CachedKeyLocalURL];
        // 有效时间
        expiresInSeconds = [itemDictionary objectForKey:CachedKeyExpiresInSeconds];
        
        //如果下载开始和结束时间不为空，表示文件全部被下载
        if (downloadEndDate != nil && downloadStartDate != nil){
            cachedFileIsFullyDownloaded = YES;
        }
        
        /* 如果expiresInSeconds不为空，downloadEndDate为空，表示文件已经正在下载 */
        if (expiresInSeconds != nil && downloadEndDate == nil){
            cachedFileIsBeingDownloaded = YES;
        }
        
        /* 判断缓存是否过期 */
        if (expiryDate != nil && [now timeIntervalSinceDate:expiryDate] > 0.0){
            cachedFileHasExpired = YES;
        }
        
        /* 如果文件没有过期 */
        if (cachedFileHasExpired == NO){
            /* 如果缓存文件没有过期，加载缓存文件，并且更新过期时间 */
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            if ([fileManager fileExistsAtPath:localURL] == YES){
                cachedFileExists = YES;
                cachedFileData = [NSData dataWithContentsOfFile:localURL];
                if (cachedFileData != nil){
                    cachedFileDataCanBeLoaded = YES;
                } /* if (cachedFileData != nil){ */
            } /* if ([fileManager fileExistsAtPath:localURL] == YES){ */
            
            
            /* 更新缓存时间 */
            
            if (paramUpdateExpiryDateIfInCache == YES){
                
                NSDate *newExpiryDate = [NSDate dateWithTimeIntervalSinceNow:
                paramURLMustExpireInSeconds];
                
                NSLog(@"Updating the expiry date from %@ to %@.",
                      expiryDate,
                      newExpiryDate);
                
                [itemDictionary setObject:newExpiryDate
                                   forKey:CachedKeyExpiryDate];
                
                NSNumber *expires =
                [NSNumber numberWithFloat:paramURLMustExpireInSeconds];
                
                [itemDictionary setObject:expires
                                   forKey:CachedKeyExpiresInSeconds];
            }
            
        } /* if (cachedFileHasExpired == NO){ */
    }
    
    
    
    if (cachedFileIsBeingDownloaded == YES){
        NSLog(@"这个文件已经正在下载...");
        return(YES);
    }
    
    if (fileHasBeenCached == YES){
        
        if (cachedFileHasExpired == NO
            && cachedFileExists == YES
            && cachedFileDataCanBeLoaded == YES
            && [cachedFileData length] > 0
            && cachedFileIsFullyDownloaded == YES){
            
            /* 如果文件有缓存而且没有过期 */
            
            NSLog(@"文件有缓存而且没有过期.");
            
            [self.delegate cachedDownloadManagerSucceeded:self
                                                remoteURL:[NSURL URLWithString:paramURLAsString]
                                                 localURL:[NSURL URLWithString:localURL]
                                    aboutToBeReleasedData:cachedFileData
                                             isCachedData:YES];
            
            return(YES);
            
        } else {
            /* 如果文件没有被缓存/获取缓存失败,删除之前的无效缓存 */
            NSLog(@"文件没有缓存.");
            [self.cacheDictionary removeObjectForKey:paramURLAsString];
            [self saveCacheDictionary];
        } /* if (cachedFileHasExpired == NO && */
        
    } /* if (fileHasBeenCached == YES){ */
    
    /* 去下载文件 */
    
    NSNumber *expires =
    [NSNumber numberWithFloat:paramURLMustExpireInSeconds];
    
    NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
    
    [newDictionary setObject:expires forKey:CachedKeyExpiresInSeconds];
    
    
    localURL = [paramURLAsString stringByAddingPercentEscapesUsingEncoding:
                NSUTF8StringEncoding];
    localURL = [localURL stringByReplacingOccurrencesOfString:@"://"
                                                   withString:@""];
    localURL = [localURL stringByReplacingOccurrencesOfString:@"/"
                                                   withString:@"{1}quot;"];
    localURL = [localURL stringByAppendingPathExtension:@"cache"];
    NSString *documentsDirectory = [self documentsDirectoryWithTrailingSlash:NO];
    localURL = [documentsDirectory stringByAppendingPathComponent:localURL];

    [newDictionary setObject:localURL forKey:CachedKeyLocalURL];

    [newDictionary setObject:now forKey:CachedKeyDownloadStartDate];

    [self.cacheDictionary setObject:newDictionary forKey:paramURLAsString];

    [self saveCacheDictionary];

    CacheItem *item = [[CacheItem alloc] init];
    [item setDelegate:self];
    [item startDownloadingURL:paramURLAsString];

    return(result);
    
}


- (BOOL)saveCacheDictionary
{
    return [self.cacheDictionary writeToFile:self.cacheDictionaryPath atomically:YES];
}


#pragma mark - CacheItemDelegate
//下载成功执行该方法
- (void)cacheItemDelegateSucceeded:(CacheItem *)paramSender
                     withRemoteURL:(NSURL *)paramRemoteURL
         withAboutToBeReleasedData:(NSData *)paramAboutToBeReleasedData
{
    //从缓存字典中获取该缓存项的相关数据
    NSMutableDictionary *dictionary = [self.cacheDictionary objectForKey:[paramRemoteURL absoluteString]];
    
    //取得当前时间
    NSDate *now = [NSDate date];
    //获取有效时间
    NSNumber *expiresinSeconds = [dictionary objectForKey:CachedKeyExpiresInSeconds];
    //转换成NSTimeInterval
    NSTimeInterval expirySeconds = [expiresinSeconds floatValue];
    //修改字典中缓存项的下载结束时间
    [dictionary setObject:[NSDate date] forKey:CachedKeyDownloadEndDate];
    //修改字典中缓存项的缓存过期时间
    [dictionary setObject:[now dateByAddingTimeInterval:expirySeconds] forKey:CachedKeyExpiryDate];
    
    //保存缓存字典
    [self saveCacheDictionary];
    
    NSString *localURL = [dictionary objectForKey:CachedKeyLocalURL];
    NSLog(@"localURL: %@", localURL);
    
    
    //将下载的数据保存到磁盘
    if ([paramAboutToBeReleasedData writeToFile:localURL atomically:YES]) {
        NSLog(@"缓存文件到磁盘成功!!");
    } else {
        NSLog(@"缓存文件到磁盘失败!!");
    }
    
    //执行缓存管理的委托方法
    [self.delegate cachedDownloadManagerSucceeded:self
                                        remoteURL:paramRemoteURL
                                         localURL:[NSURL URLWithString:localURL]
                            aboutToBeReleasedData:paramAboutToBeReleasedData
                                     isCachedData:NO];
}

//下载失败执行该方法
- (void)cacheItemDelegateFailed:(CacheItem *)paramSender
                      remoteURL:(NSURL *)paramRemoteURL
                      withError:(NSError *)paramError
{
    //从缓存字典中移除缓存项，并发送一个委托
    if (self.delegate != nil) {
        NSMutableDictionary *dictionary = [self.cacheDictionary objectForKey:[paramRemoteURL absoluteString]];
        
        NSString *localURL = [dictionary objectForKey:CachedKeyLocalURL];
        
        [self.delegate cachedDownloadManagerFailed:self
                                         remoteURL:paramRemoteURL
                                          localURL:[NSURL URLWithString:localURL]
                                         withError:paramError];
        
        [self.cacheDictionary removeObjectForKey:[paramRemoteURL absoluteString]];
    }
}
@end





















