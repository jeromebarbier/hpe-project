# Service i

The purpose of this service is to define if the player win something.
A price is ramdomly selected, and an image is generated with the id of the player.
The ourput is a json with the price and the image data.

## Dependencies

- Python 3
- Imagemagick
- Flask (python3-flask)

## Configuration file

```
[i]
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

    "Service": "Microservice i",
    "Version": "0.1"

}
```

## Request
GET /play/id

### Response

Return the id if it exists in users database, else 0

```json
{
    "auth": id
}
```

## Request
POST /shutdown

### Response

Stop the application server

