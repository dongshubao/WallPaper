//
//  ViewController.m
//  WallPaper
//
//  Created by 董淑宝 on 16/9/16.
//  Copyright © 2016年 董淑宝. All rights reserved.
//

#import "ViewController.h"
#import "picData.h"

@implementation ViewController

@synthesize array;
@synthesize picTable;

- (void)viewDidLoad {
    [super viewDidLoad];
    // 获取系统当前时间
    NSDate * currentDate = [NSDate date];
    //NSTimeInterval sec = [date timeIntervalSinceNow];
    //NSDate * currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    
    [self.picTable setDelegate:self];
    [self.picTable setDataSource:self];
    
    self.picDate.dateValue = currentDate;
    NSString *path = [[NSString alloc] initWithFormat:@"%@%@",[NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) lastObject],@"/WallPaper" ];
    self.picPath.stringValue = path;

    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    
    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}


- (IBAction)browePath:(id)sender {
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];

    [openDlg setCanChooseDirectories:YES];

    if ( [openDlg runModalForDirectory:nil file:nil] == NSOKButton )
    {
        NSArray* files = [openDlg filenames];
        NSString* fileName = [files objectAtIndex:0];
        self.picPath.stringValue = fileName;
    }
}



//------------------------protocol----------------------------------

//返回表格的行数
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return [array count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    /*
    NSString* columnIdentifier = [tableColumn identifier];
    //NSLog(@"%@", columnIdentifier);
    picData *identifier = [array objectAtIndex:row];
    NSLog(@"%@", [identifier valueForKey:columnIdentifier]);
    return [identifier valueForKey:columnIdentifier];
    */
    return nil;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    picData *data = [array objectAtIndex:row];
    NSString *identifier = [tableColumn identifier];
    
    if ([identifier isEqualToString:@"url"]) {
        //NSTextFieldCell *textCell = cell;
        [cell setTitle:[data url]];
    }
    else if ([identifier isEqualToString:@"progress"])
    {
        //NSProgressIndicator *textCell = cell;
        [cell setTitle:[[NSString alloc] initWithFormat:@"%d%%",[[data progress] intValue]]];
    }
}

//------------------------protocol----------------------------------

- (IBAction)dump:(id)sender {
    //设置时间输出格式：
    NSDateFormatter * df = [[NSDateFormatter alloc] init ];
    [df setDateFormat:@"yyyy-MM-dd"];
    NSString * na = [df stringFromDate:self.picDate.dateValue];
    
    NSString *httpUrl = @"http://api.lovebizhi.com/macos_v4.php";
    NSString *httpArg = [@"a=everyday&spdy=1&device=105&uuid=4276e63c48ae0961b09df4f2e0d04229&mode=0&retina=1&client_id=1008&device_id=67089839&model_id=105&size_id=0&channel_id=79979&screen_width=2880&screen_height=1800&bizhi_width=2880&bizhi_height=1800&version_code=27&language=zh-Hans&jailbreak=0&mac=&date=" stringByAppendingString:na];
    
    [self request:httpUrl withHttpArg:httpArg];
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refresh)  userInfo:nil repeats:YES];
}


-(void)refresh{
    [picTable reloadData];
    double sum = 0;
    for(picData *p in array){
        sum = sum + [p.progress doubleValue];
    }
    double percent = sum / [array count];
    self.dumpProgress.doubleValue = percent;
    self.dumpNum.stringValue =[[NSString alloc]initWithFormat:@"%d%%", (int)percent];
}


-(void)downLoadPic:(NSString *) urlStr withIndex:(NSString *) downLoadTaskDescription
{
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL * url = [NSURL URLWithString:urlStr];
    
    //专门用来管理session的类(可以配置全局访问网络的参数), 是一个单例的类
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    //delegateQueue: 指定一个回调方法执行的线程,   也可以是nil也是子线程
    NSURLSession * session_progress = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    NSURLSessionDownloadTask *downLoadTask = [session_progress downloadTaskWithURL:url];
    [downLoadTask setTaskDescription:downLoadTaskDescription];
    //发起并继续任务
    [downLoadTask resume];
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    //建议使用的文件名，一般跟服务器端的文件名一致
    NSString *file = [self.picPath.stringValue stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    
    // AtPath : 剪切前的文件路径     // ToPath : 剪切后的文件路径
    [[NSFileManager defaultManager] moveItemAtPath :location.path toPath:file error : nil];
    //NSLog(@"Done");
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    /*
     bytesWritten               本次写入的字节数
     totalBytesWritten          已经写入的字节数
     totalBytesExpectedToWrite  下载文件总字节数
     */
    
    double progress = (double)totalBytesWritten * 100 / totalBytesExpectedToWrite;
    //NSLog(@" %@ ,progress = %f",[NSThread currentThread],progress);
    
    picData *p = array[[downloadTask.taskDescription intValue]];
    p.progress = [[NSString alloc]initWithFormat:@"%f%%", progress];
    //调用主线程刷星进度条
    dispatch_async(dispatch_get_main_queue(), ^{
    });
}


-(NSString *)request_original: (NSString*)httpUrl withHttpArg: (NSString*)HttpArg  {
    NSString static *result = NULL;
    NSURLSession * session = [NSURLSession sharedSession];
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@?%@", httpUrl, HttpArg];
    NSURL* url = [NSURL URLWithString:strUrl];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Httperror: %@%ld", error.localizedDescription, error.code);
            result = NULL;
        } else {
            NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
            NSLog(@"HttpResponseCode:%ld", responseCode);
            result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }
    }];
    [task resume];
    return result;
}


-(void)request: (NSString*)httpUrl withHttpArg: (NSString*)HttpArg  {
    NSString static *result = NULL;
    NSURLSession * session = [NSURLSession sharedSession];
    NSString *strUrl = [[NSString alloc] initWithFormat:@"%@?%@", httpUrl, HttpArg];
    NSURL* url = [NSURL URLWithString:strUrl];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Httperror: %@%ld", error.localizedDescription, error.code);
            [self alert:[[NSString alloc] initWithFormat:@"%ld", error.code] withInformative:error.localizedDescription];
        } else {
            result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString* jsonString = result;
            //将字符串写到缓冲区。
            NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            //解析json数据，使用系统方法 JSONObjectWithData:  options: error:
            NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
            
            NSArray *picList = [dic objectForKey:@"data"];
            
            array = [NSMutableArray new];
            
            for(int i = 0; i< [picList count]; i++){
                
                NSString *url = [[picList[i] objectForKey:@"image"] objectForKey:@"original"];
                
                picData *data = [picData new];
                [data setUrl:url];
                [data setProgress:[[NSString alloc] initWithFormat:@"%d%%", 0]];
                [array addObject:data];
                [self downLoadPic:[[picList[i] objectForKey:@"image"] objectForKey:@"original"] withIndex:[[NSString alloc] initWithFormat:@"%d", i]];
            }
            [picTable reloadData];
        }
    }];
    [task resume];
}


-(void) alert:(NSString *)message withInformative: (NSString *)informative{
    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:message];
    [alert setInformativeText:informative];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}


@end
