//
//  picData.h
//  WallPaper
//
//  Created by 董淑宝 on 16/9/21.
//  Copyright © 2016年 董淑宝. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface picData : NSObject
{
    NSString *file_id;
    NSString *url;
    double progress;
    NSURLSessionDownloadTask *downLoadTask;
}

@property NSString *file_id;

@property NSString *url;

@property double progress;

@property NSURLSessionDownloadTask *downLoadTask;

@end
