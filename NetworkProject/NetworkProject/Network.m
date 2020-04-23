//
//  Network.m
//  InfrastructureProjects
//
//  Created by shiwei on 2020/3/21.
//  Copyright © 2020 shiwei. All rights reserved.
//

#import "Network.h"
#import <AFNetworking/AFNetworking.h>

#ifdef DEBUG
#define URLLog(FORMAT, ...)  fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define URLLog(...)
#endif

@interface HttpManager : AFHTTPSessionManager

@end

@implementation HttpManager

+ (HttpManager *)instance {
    
    static HttpManager * _instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[HttpManager alloc] _init];
    });
    return _instance;
}

- (instancetype)_init
{
    self = [super init];
    if (self) {
        self = [[HttpManager manager] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        self.operationQueue.maxConcurrentOperationCount = 5;
        
        // 设置请求数据
        self.requestSerializer = AFHTTPRequestSerializer.serializer;
        self.requestSerializer.timeoutInterval = 15;
        [self.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
        // 设置响应数据
        self.responseSerializer = AFHTTPResponseSerializer.serializer;
        self.responseSerializer.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml",@"text/html", @"application/json",@"text/plain",nil];
    }
    return self;
}

@end



@interface NetworkConfig ()

@property (nonatomic, strong) HttpManager *httpManager;
@property (nonatomic, copy, readonly) ConfigToVoid defaultConfig;

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, strong) NSMutableDictionary *paramsDictionary;
@property (nonatomic, strong) NSData *bodyData;

@property (nonatomic, copy) Progress downloadProgressValue;
@property (nonatomic, copy) Progress uploadProgressValue;
@property (nonatomic, copy) Progress progressBlockValue;

@property (nonatomic, copy) NetError netErrorBlockValue;
@property (nonatomic, copy) NetSuccess netSuccessBlockValue;
@property (nonatomic, copy) DataError dataErrorBlockValue;
@property (nonatomic, copy) DataSuccess dataSuccessBlockValue;


@end

@implementation NetworkConfig

- (ConfigToVoid)defaultConfig {
    
    return ^() {
        self.httpManager = HttpManager.instance;
        return self;
    };
}

- (ConfigToString)url {
    
    return ^(NSString *str) {
        self.urlString = str;
        return self;
    };
}

- (ConfigToDictionary)params {
    
    return ^(NSDictionary *dic) {
        self.paramsDictionary = [NSMutableDictionary dictionaryWithDictionary:dic];
        return self;
    };
}

- (ConfigToDictionary)body {
    
    return ^(NSDictionary *body) {
        self.bodyData = [NSJSONSerialization dataWithJSONObject:body options:kNilOptions error:nil];
        return self;
    };
}

- (ConfigToProgress)downloadProgress {
    
    return ^(Progress progressBlock) {
        self.downloadProgressValue = progressBlock;
        return self;
    };
}

- (ConfigToProgress)uploadProgress {
    
    return ^(Progress progressBlock) {
        self.uploadProgressValue = progressBlock;
        return self;
    };
}

- (ConfigToNetErrorBlock)netErrorBlock {
    
    return ^(NetError block) {
        self.netErrorBlockValue = block;
        return self;
    };
}

- (ConfigToNetSuccessBlock)netSuccessBlock {
    
    return ^(NetSuccess block) {
        self.netErrorBlockValue = block;
        return self;
    };
}

- (ConfigToDataErrorBlock)dataErrorBlock {
    
    return ^(DataError block) {
        self.dataErrorBlockValue = block;
        return self;
    };
}

- (ConfigToDataSuccessBlock)dataSuccessBlock {
    
    return ^(DataSuccess block) {
        self.dataSuccessBlockValue = block;
        return self;
    };
}

- (DataTaskToVoid)getRequest {
    return ^(void) {
        return [self getRequestValue];
    };
}

- (DataTaskToVoid)postRequest {
    return ^(void) {
        return [self postRequestValue];
    };
}

- (NSURLSessionDataTask *)getRequestValue {
    
    if (!self.urlString || !self.urlString.length) {
        NSLog(@"error::url is nil");
        return nil;
    }
    __weak typeof(self) wself = self;
    NSURLSessionDataTask *task = [self.httpManager GET:self.urlString parameters:self.paramsDictionary headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
        [wself dealWithProgress:downloadProgress];
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        [wself dealWithSuccessResponse:task response:responseObject requestType:0];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [wself dealWithError:task error:error requestType:0];
    }];
    return task;
}

- (NSURLSessionDataTask *)postRequestValue {
    if (!self.urlString || !self.urlString.length) {
        NSLog(@"error::url is nil");
        return nil;
    }
    NSMutableURLRequest *request = [self.httpManager.requestSerializer requestWithMethod:@"POST" URLString:self.urlString parameters:self.paramsDictionary error:nil];
    NSLog(@"log::%f", request.timeoutInterval);
    if (self.bodyData) {
        [request setHTTPBody:self.bodyData];
    }
    __weak typeof(self) wself = self;
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self.httpManager dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        
        [wself dealWithUploadProgress:uploadProgress];
        
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        
        [wself dealWithProgress:downloadProgress];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            [wself dealWithError:dataTask error:error requestType:1];
        } else {
            [wself dealWithSuccessResponse:dataTask response:responseObject requestType:1];
        }
    }];
    
    return dataTask;
}

- (void)dealWithUploadProgress:(NSProgress *)uploadProgress {
    
    if (self.uploadProgressValue) {
        self.uploadProgressValue(uploadProgress);
    }
}

- (void)dealWithProgress:(NSProgress *)downloadProgress {

    if (self.downloadProgressValue) {
        self.downloadProgressValue(downloadProgress);
    }
}

// type 1post 0 get
- (void)dealWithSuccessResponse:(NSURLSessionDataTask *)task response:(id)responseObject requestType:(NSInteger)type {
    NSError *error = nil;
    NSDictionary *data = [NSJSONSerialization JSONObjectWithData:responseObject options:kNilOptions error:&error];
    [NetworkConfig logInfo:self.urlString para:self.paramsDictionary obj:data error:nil Type:type];
    if (self.netSuccessBlockValue) {
        self.netSuccessBlockValue(task, responseObject);
    }
    if (error || !data) {
        NSLog(@"error::responseObject isn't Json");
    } else {
#pragma mark - 各个网络层返回错误码字段可能不一致
        NSString * errnoCode = [NSString stringWithFormat:@"%@", [data objectForKey:@"errno"]];
        NSString * errmsg = [NSString stringWithFormat:@"%@", [data objectForKey:@"errmsg"]];
        if ([errnoCode isEqualToString:@"0"]) {
            if (self.dataSuccessBlockValue) {
                self.dataSuccessBlockValue(data);
            }
        } else {
            if (self.dataErrorBlockValue) {
                self.dataErrorBlockValue(errnoCode, errmsg);
            }
        }
    }
}

- (void)dealWithError:(NSURLSessionDataTask *)task error:(NSError *)error requestType:(NSInteger)type {
    [NetworkConfig logInfo:self.urlString para:self.paramsDictionary obj:nil error:error Type:0];
    if (self.netErrorBlockValue) {
        self.netErrorBlockValue(task, error);
    }
}

+ (void)logInfo:(NSString *)url para:(NSDictionary *)para obj:(id)obj error:(NSError *)error Type:(NSInteger)type {
    
    if (type == 1) {
        URLLog(@"\n--------POST");
    } else {
        URLLog(@"\n--------GET");
    }
    URLLog(@"url:  %@", url);
    URLLog(@"para: %@", para);
    if (error) {
        URLLog(@"%@", [NSString stringWithFormat:@"\nerrorCode - %ld\ninfo - %@\n--------END\n", (long)error.code,error.description]);
    } else {
        URLLog(@"%@", [NSString stringWithFormat:@"responseObject = %@\n--------END\n", [self convertJSONWithDic:obj]]);
    }
}
//字典转JSON
+(NSString *)convertJSONWithDic:(NSDictionary *)dic {
    NSError *err;
    if (dic) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&err];
        if (err) {
            return @"字典转JSON出错";
        }
        NSString *dicString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dicString = [dicString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        dicString = [dicString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        dicString = [dicString stringByReplacingOccurrencesOfString:@" " withString:@""];
        dicString = [dicString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
        return dicString;
    }
    return @"";
}
@end

@implementation Network
 
static NetworkConfig *_config;

+ (NetworkConfig *)netConfig {
    
    if (_config) {
        return _config;
    }
    _config = NetworkConfig.new;
    _config.defaultConfig();
    return _config;
}

+ (void)cancelRequestWithUrl:(NSString *)url {

    NSLog(@"log::currentUrl - %@", url);
    [Network.netConfig.httpManager.dataTasks enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"log::url - %@", obj.currentRequest.URL.absoluteString);
        if ([obj.currentRequest.URL.absoluteString isEqualToString:url]) {
            [obj cancel];
            return;
        }
    }];
}

+ (void)cancelAllRequest {
    [Network.netConfig.httpManager.dataTasks enumerateObjectsUsingBlock:^(NSURLSessionDataTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cancel];
    }];
}

@end
