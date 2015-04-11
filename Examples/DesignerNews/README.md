## App

[Reference](https://github.com/hyperoslo/Sync/tree/master/Examples/DesignerNews)

![Model](https://raw.githubusercontent.com/hyperoslo/Sync/master/Examples/DesignerNews/Images/app.png)

## JSON

[Reference](https://news.layervault.com/?format=json)

```json
{
  "stories":[
    {
      "id":47333,
      "title":"Site Design: Aquest",
      "vote_count":6,
      "created_at":"2015-04-06T13:16:36Z",
      "num_comments":6,
      "submitter_display_name":"Chris A.",
      "comments":[
        {
          "body":"Beautiful.",
          "created_at":"2015-04-06T13:45:20Z",
          "depth":0,
          "user_display_name":"Sam M.",
          "upvotes_count":0,
          "comments":[

          ]
        }
      ]
    }
  ]
}
```

## Model

![Model](https://raw.githubusercontent.com/hyperoslo/Sync/master/Examples/DesignerNews/Images/model.png)

## Sync

[Reference](https://github.com/hyperoslo/Sync/blob/master/Examples/DesignerNews/DesignerNews/Source/APIClient.m#L35-L40)

```objc
[Sync changes:JSON[@"stories"]
inEntityNamed:@"Story"
    dataStack:dataStack
   completion:^(NSError *error) {
       [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
   }];
```
