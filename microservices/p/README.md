# Service p

Gets the picture corresponding to the provided user id

## Dependencies

- Python 3
- Flask (python3-flask)
- Swiftclient

## Configuration file

```
[p]
port=8092
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

    "Service": "Microservice p",
    "Version": "1.0"

}
```

## Request
GET /id

### Response

Return image and price name

```json
{

    "img": "/9j/4AAQSkZJRgABAQEASABIAAD/7RPqUGhvdG9zaG9wIDMuMAA4QklNBCUAAAAAABAAAAAAAAAAAAAAAAAAAAAAOEJJTQPtAAAAAAAQAEgAAAABAAIASAAAAAEAAjhCSU0EJgAAAAAADgAAAAAAAAAAAAA/gAAAOEJJTQQNAAAAAAAEAAAAHjh...
    "name": "usbkey.jpg"

}
```

## Request
POST /shutdown

### Response

Stop the application server

