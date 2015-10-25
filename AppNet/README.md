## App

[Reference (Swift)](https://github.com/hyperoslo/Sync/tree/master/AppNet)

![Model](https://raw.githubusercontent.com/hyperoslo/Sync/master/AppNet/Images/app.png)

## JSON

[Reference](https://api.app.net/posts/stream/global)

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

![Model](https://raw.githubusercontent.com/hyperoslo/Sync/master/AppNet/Images/model.png)

## Sync

[Reference](https://github.com/hyperoslo/Sync/blob/master/AppNet/Networking.swift#L32-L34)

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
