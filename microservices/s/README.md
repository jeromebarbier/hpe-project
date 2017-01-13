# Service s

Checking if a player has already played

## Dependencies

- Python 3
- Flask (python3-flask)

## Configuration file

```
[s]
port=8094
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

    "Service": "Microservice s",
    "Version": "0.1"

}
```

## Request
POST /shutdown

### Response

Stop the application server


## Request
GET /checkPlayed?uid=<UID_ID>

## Response
```json
{
    "html": Button's HTML code
}

