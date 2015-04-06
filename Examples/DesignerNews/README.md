## JSON

[Source](https://news.layervault.com/?format=json)

```json
{
  "meta":{
    "min_id":"57030525",
    "code":200,
    "max_id":"57030547",
    "more":true
  },
  "data":[
    {
      "created_at":"2015-04-06T15:07:06Z",
      "text":"Hello World!",
      "id":"57030547",
      "user":{
        "username":"albarjeel1",
        "created_at":"2015-03-28T13:01:31Z",
        "id":"347326"
      }
    }
  ]
}
```

## Model

![Model](https://raw.githubusercontent.com/hyperoslo/Sync/master/Examples/DesignerNews/Images/designer-news-model.png)

## Sync

```objc
[Sync changes:[JSON valueForKey:@"stories"]
inEntityNamed:@"Story"
    dataStack:dataStack
   completion:^(NSError *error) {
       [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
   }];
```
