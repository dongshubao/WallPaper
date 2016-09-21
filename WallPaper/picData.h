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
    NSString *url;
    NSString *progress;
}

@property NSString *url;

@property NSString *progress;

@end
