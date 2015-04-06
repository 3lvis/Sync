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

## Model

![Model](https://raw.githubusercontent.com/hyperoslo/Sync/master/Examples/AppNet/Images/appnet-model.png)

## JSON

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
      "canonical_url":"https://alpha.app.net/albarjeel1/post/57030547",
      "machine_only":false,
      "user":{
        "username":"albarjeel1",
        "locale":"en_US",
        "created_at":"2015-03-28T13:01:31Z",
        "canonical_url":"https://alpha.app.net/albarjeel1",
        "timezone":"Asia/Dubai",
        "id":"347326",
        "name":"albarjeel"
      },
      "thread_id":"57030547",
      "pagination_id":"57030547"
    }
  ]
}
```

