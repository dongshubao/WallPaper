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
    
    array = [NSMutableArray new];
    
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

-(IBAction)changeWallPaper:(id)sender {
    
    NSArray *files = [[[NSFileManager alloc] init] contentsOfDirectoryAtPath:self.picPath.stringValue error:nil];
    //NSLog(@"%@", files);

    NSMutableArray *jpgList = [NSMutableArray new];
    
    for(NSString *file in files){
        if([file hasSuffix:@".jpg"]){
            [jpgList addObject:file];
        }
    }
    //NSLog(@"%d", [@"haha" hasSuffix:@".jpg"]);
    if([jpgList count]){
        NSString *path = [[NSString alloc] initWithFormat:@"%@/%@",self.picPath.stringValue,[jpgList objectAtIndex:arc4random() % [jpgList count]]];
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/osascript";
        NSString *command = [[NSString alloc] initWithFormat:@"tell application \"Finder\" to set desktop picture to POSIX file \"%@\"",path];
        //NSLog(@"%@", command);
        NSArray *arguments = [NSArray arrayWithObjects: @"-e", command, nil];
        [task setArguments: arguments];
        // 新建输出管道作为Task的输出
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardOutput: pipe];
         
         // 开始task
        NSFileHandle *file = [pipe fileHandleForReading];
        [task launch];
         
        // 获取运行结果
        NSData *data = [file readDataToEndOfFile];
        NSLog(@"%@", [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
    }
    else{
        [self alert:@"通知" withInformative:@"当前文件夹无图片，请先下载图片到当前文件夹！"];
    }
}


- (IBAction)browsePath:(id)sender {
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];

    [openDlg setCanChooseDirectories:YES];
    [openDlg setCanChooseFiles:NO];
    [openDlg setCanCreateDirectories:YES];
    [openDlg setTitle:@"请选择保存位置"];

    if ( [openDlg runModal] == NSModalResponseOK )
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
        double progress = [data progress];
        if (progress == 0)
            [cell setTitle:@"等待中"];
        else{
            [cell setTitle:[[NSString alloc] initWithFormat:@"%d%%",(int)progress]];
        }
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
}


-(void)refresh{
    [picTable reloadData];
    int count = 0;
    double sum = 0;
    for(picData *p in array){
        sum = sum + p.progress;
        if ((int)p.progress == 100)
            count++;
    }
    double percent = sum / [array count];
    self.dumpProgress.doubleValue = percent;
    self.dumpNum.stringValue =[[NSString alloc]initWithFormat:@"%d", (int)[array count] - count];
}


-(NSURLSessionDownloadTask *)downLoadPic:(NSString *) urlStr withID:(NSString *) file_id
{
    //urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL * url = [NSURL URLWithString:urlStr];
    
    //专门用来管理session的类(可以配置全局访问网络的参数), 是一个单例的类
    NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    //delegateQueue: 指定一个回调方法执行的线程,   也可以是nil也是子线程
    NSURLSession * session_progress = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    
    NSURLSessionDownloadTask *downLoadTask = [session_progress downloadTaskWithURL:url];
    //标记下载任务
    [downLoadTask setTaskDescription:file_id];
    return downLoadTask;
    //[downLoadTask resume];
}


-(void)startDownLoad{

    for(picData *p in array){
        if(p.downLoadTask.state == 1){
            [p.downLoadTask resume];
            break;
        }
    }
    
}


-(int)getArrayIndexByFile_id:(NSString *) file_id {
    picData *data = [picData new];
    for(int index = 0;index<[array count];index++){
        data = [array objectAtIndex:index];
        if (data.file_id==file_id)
            return index;
    }
    return -1;
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    //建议使用的文件名，一般跟服务器端的文件名一致
    NSString *file = [self.picPath.stringValue stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    file = [file stringByReplacingOccurrencesOfString:@".html" withString:@""];
    // AtPath : 剪切前的文件路径     // ToPath : 剪切后的文件路径
    [[NSFileManager defaultManager] moveItemAtPath :location.path toPath:file error : nil];
    //NSLog(@"Done");
    
    //同步调用主线程
    dispatch_sync(dispatch_get_main_queue(), ^{
        //[array removeObjectAtIndex:[self getArrayIndexByFile_id:downloadTask.taskDescription]];
        [self startDownLoad];
    });
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    /*
     bytesWritten               本次写入的字节数
     totalBytesWritten          已经写入的字节数
     totalBytesExpectedToWrite  下载文件总字节数
     */

    double progress = (double)totalBytesWritten * 100 / totalBytesExpectedToWrite;

    //同步调用主线程
    dispatch_sync(dispatch_get_main_queue(), ^{
        picData *p = array[[self getArrayIndexByFile_id:downloadTask.taskDescription]];
        //NSLog(@"description = %@",downloadTask.taskDescription);
        p.progress = progress;
        //NSLog(@"index:%d progress:%f",index,progress);
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
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self alert:[[NSString alloc] initWithFormat:@"%ld", error.code] withInformative:error.localizedDescription];
            });
        } else {
            //NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
            //NSLog(@"responseCode:%ld", responseCode);
            result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString* jsonString = result;
            //将字符串写到缓冲区。
            NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            //解析json数据，使用系统方法 JSONObjectWithData:  options: error:
            NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
            
            NSArray *picList = [dic objectForKey:@"data"];
            
            int arrayOriCount = 0;
            
            if (array!=NULL){
                arrayOriCount = (int)[array count];
            }
            
            if ([picList count]){
            
                for(int i = 0; i< [picList count]; i++){
                    
                    NSString *file_id = [picList[i] objectForKey:@"file_id"];
                    NSString *url = [[picList[i] objectForKey:@"image"] objectForKey:@"original"];
                    
                    picData *data = [picData new];
                    [data setFile_id:file_id];
                    [data setUrl:url];
                    [data setProgress:0];
                    [data setDownLoadTask:[self downLoadPic:url withID:file_id]];
                    
                    [array addObject:data];
                }
                [picTable reloadData];

                //调用主线程 开始下载 并 刷新进度条
                dispatch_sync(dispatch_get_main_queue(), ^{
                    for(int i = 0; i < 10; i++)
                        [self startDownLoad];
                    
                    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refresh)  userInfo:nil repeats:YES];
                });
            }
            else{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self alert:@"无内容" withInformative:@"请检查网络或者日期！"];
                });
            }
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
