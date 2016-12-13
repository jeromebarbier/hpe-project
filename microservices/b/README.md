# Service b

Button widget allowing the customer to play

## Dependencies

- Python 3
- Flask (python3-flask)

## Configuration file

```
[b]
port=8090
tmpfile=/tmp
tempo=5
debug=False
```

* Port: Tcp port number used by the server.
* tmpfile: Location of the temporary price imaged.
* tempo: Latency introduced.
* debug: Add information to log file to debug the app.

## API

### Request
GET /

### Response

Return service name and version

```json
{

    "Service": "Microservice b",
    "Version": "0.1"

}
```

## Request
POST /shutdown

### Response

Stop the application server


## Request
GET /button?uid=<UID_ID>

## Response
```json
{

    "html": Button's HTML code
    "js"  : Button's JS code

}

JS code includes the following functions, usable by selecting the button (jQuery("#elButton"))
1. enable : Enables the button
2. disable : Disables the button
3. playedTrigger(function) : Declare the function to run when the user had click on the button AND when the gift had been determined (basically, refresh service P)
