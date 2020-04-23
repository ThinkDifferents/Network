//
//  Network.h
//  InfrastructureProjects
//
//  Created by shiwei on 2020/3/21.
//  Copyright © 2020 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NetworkConfig, HttpManager;

NS_ASSUME_NONNULL_BEGIN

typedef void(^Progress) (NSProgress *progress);
typedef void(^NetError) (NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error);
typedef void(^NetSuccess) (NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject);
typedef void(^DataError) (NSString *errCode, NSString *errmsg);
typedef void(^DataSuccess) (id data);

typedef NetworkConfig * _Nonnull (^ConfigToVoid) (void);

typedef NetworkConfig * _Nonnull (^ConfigToString) (NSString *str);
typedef NetworkConfig * _Nonnull (^ConfigToDictionary) (NSDictionary *dic);

typedef NetworkConfig * _Nonnull (^ConfigToProgress) (Progress progressBlock);

typedef NetworkConfig * _Nonnull (^ConfigToNetSuccessBlock) (NetSuccess netSuccessBlock);
typedef NetworkConfig * _Nonnull (^ConfigToNetErrorBlock) (NetError netErrorBlock);

typedef NetworkConfig * _Nonnull (^ConfigToDataSuccessBlock) (DataSuccess dataSuccessBlock);
typedef NetworkConfig * _Nonnull (^ConfigToDataErrorBlock) (DataError dataErrorBlock);

typedef NSURLSessionDataTask * _Nonnull (^DataTaskToVoid) (void);

@interface NetworkConfig : NSObject

@property (nonatomic, copy, readonly) ConfigToString url;
@property (nonatomic, copy, readonly) ConfigToDictionary params;
@property (nonatomic, copy, readonly) ConfigToDictionary header;
@property (nonatomic, copy, readonly) ConfigToDictionary body;

@property (nonatomic, copy, readonly) ConfigToProgress downloadProgress;
@property (nonatomic, copy, readonly) ConfigToProgress uploadProgress;

@property (nonatomic, copy, readonly) ConfigToNetSuccessBlock netSuccessBlock;
@property (nonatomic, copy, readonly) ConfigToNetErrorBlock netErrorBlock;

@property (nonatomic, copy, readonly) ConfigToDataSuccessBlock dataSuccessBlock;
@property (nonatomic, copy, readonly) ConfigToDataErrorBlock dataErrorBlock;


@property (nonatomic, copy, readonly) DataTaskToVoid getRequest;
@property (nonatomic, copy, readonly) DataTaskToVoid postRequest;

@end

@interface Network : NSObject

+ (NetworkConfig *)netConfig;

/// 取消url对应的请求
/// @param url 请求url
+ (void)cancelRequestWithUrl:(NSString *)url;

/// 取消所有网络请求
+ (void)cancelAllRequest;

@end

NS_ASSUME_NONNULL_END
