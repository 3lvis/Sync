## JSON

[Source](https://api.app.net/posts/stream/global)

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

![Model](https://raw.githubusercontent.com/hyperoslo/Sync/master/Examples/AppNet/Images/appnet-model.png)

## Sync

```swift
Sync.changes(
    json["data"] as Array,
    inEntityNamed: "Data",
    dataStack: self.dataStack,
    completion: { error in
        completion()
    }
)
```
