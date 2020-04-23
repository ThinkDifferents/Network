//
//  ViewController.m
//  NetworkProject
//
//  Created by shiwei on 2020/4/22.
//  Copyright © 2020 shiwei. All rights reserved.
//

#import "ViewController.h"
#import "Network.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Network.netConfig
    .url(@"https://www.baidu.com")
    .params(@{})
    .getRequest();
}


@end
