import hashes, net, sets, tables, threadpool

import protocol


type
    Client = object
        socket: Socket

proc hash(c: Client): THash =
    return int(c.socket.getFd())

type
    Server = object
      socket: Socket
      port: int
      subs: Table[string, HashSet[Client]]

proc dispatchFrame(server: Server, socket: Socket, frame: Frame) =
    case frame.proto
    of SUB:
        var subs = server.subs[frame.body]
        if not subs.isValid():
            subs = initSet[Client]()
        subs.incl(Client(socket: socket))
    of USUB:
        var subs = server.subs[frame.body]
        if subs.isValid():
            subs.excl(Client(socket: socket))
    of PUB:
        # TODO
        discard
    else:
        echo "Invalid message protocol: ", frame.proto

# Begins processing client messages.
proc clientLoop(server: Server, client: Socket) =
    while true:
        var frame: Frame
        try:
            frame = readFrame(client)
        except:
            echo "Disconnecting client"
            client.close()
            return

        server.dispatchFrame(client, frame)

# Begins accepting client connections.
proc accepterLoop(server: Server) =
    while true:
        var client = Socket()
        server.socket.accept(client)
        spawn clientLoop(server, client)

# Starts the message broker on the given port.
proc start(port: int) =
    var server = Server(port: port, subs: initTable[string, HashSet[Client]]())
    server.socket = newSocket()
    try:
        server.socket.bindAddr(port = Port(port))
        server.socket.listen()
        echo "Server listening on port ", port
        server.accepterLoop()
    finally:
        server.socket.close()

proc main() =
    let port = 8888
    start(port)

when isMainModule:
    main()
