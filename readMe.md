#### 简单get请求, 不需要处理返回结果

```
Network.netConfig
.url(@"https://www.baidu.com")
.params(@{})
.getRequest();

```

#### 只处理成功结果
```
Network.netConfig
    .url(@"https://www.baidu.com")
    .dataSuccessBlock(^(id  _Nonnull data) {
        // data 为接口返回结果
    })
    .getRequest();
  ```

#### post请求需要将参数放 body
```
Network.netConfig
    .url(@"https://www.baidu.com")
    .body(@{})
    .postRequest();
```
