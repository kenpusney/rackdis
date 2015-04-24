# rackdis

In memory JSON Database with REST API

## Usage

Currently it support GET(retrive) / POST(create/update) / DELETE(delete) http method.
You can try it like 
```shell
curl -X POST -d @<JSON-FINE> http://<HOSTNAME>/<ENTRY-NAME>    #create
curl -X DELETE http://<HOSTNAME>/<ENTRY-NAME>                  #delete
curl http://<HOSTNAME>/<ENTRY-NAME>                            #retrive
```

To start the server, you should run
```racket
(serve <port-number>)
```
or you can get the result of `serve` procedure, and use it to stop the server:
```racket
;start
(define stop (serve <port-number>))
;stop
(stop)
```

## TODO

+ transactions
+ MVCC?
+ More REST method support
+ Run as daemon
