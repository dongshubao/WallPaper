//
//  ViewController.h
//  WallPaper
//
//  Created by 董淑宝 on 16/9/16.
//  Copyright © 2016年 董淑宝. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController <NSURLSessionDelegate,NSTableViewDelegate,NSTableViewDataSource>

@property (weak) IBOutlet NSDatePicker *picDate;

@property (weak) IBOutlet NSTextField *picPath;

@property (weak) IBOutlet NSProgressIndicator *dumpProgress;

@property (weak) IBOutlet NSTextField *dumpNum;

@property (weak) IBOutlet NSTableView *picTable;

@property (nonatomic, strong) NSTimer *refreshTimer;

@property NSMutableArray *array;

@end

