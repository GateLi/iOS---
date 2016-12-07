//
//  CacheItem.m
//  iOS开发缓存机制-本地缓存机制
//
//  Created by jrzhuxue on 16/12/5.
//  Copyright © 2016年 Brian_li. All rights reserved.
//

#import "CacheItem.h"

@implementation CacheItem

- (void)startDownloadingURL:(NSString *)paramRemoteURL
{
    self.session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:paramRemoteURL];
    
    //通过URL初始化task,在block内部可以直接对返回的数据进行处理
    NSURLSessionTask *task = [self.session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error == nil) {
            [self.delegate cacheItemDelegateSucceeded:self withRemoteURL:url withAboutToBeReleasedData:data];
        } else {
            [self.delegate cacheItemDelegateFailed:self remoteURL:url withError:error];
        }
    }];
    
    //启动任务
    [task resume];
}

@end
