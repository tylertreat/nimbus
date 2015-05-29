import net, rawsockets, strutils

const
    SUB* = uint16(0)
    USUB* = uint16(1)
    PUB* = uint16(2)

type
    Frame* = object
        proto*: uint16
        size*: uint32
        body*: string

type
    Message = object
        topicSize: uint
        topic: string
        bodySize: uint
        body: string

type
    ProtocolError = Exception

# Reads a single protocol frame. A frame is of the form protocol (2 bytes),
# body size (4 bytes), body (body-size bytes), in network-byte order.
proc readFrame*(socket: Socket): Frame {.raises: [IOError, TimeoutError, OSError].} =
    var frame = Frame()
    if socket.recv(addr frame.proto, 2) != 2:
        raise newException(IOError, "Failed to read frame protocol")
    frame.proto = uint16(ntohs(int16(frame.proto)))

    if socket.recv(addr frame.size, 4) != 4:
        raise newException(IOError, "Failed to read frame size")
    frame.size = uint32(ntohl(int32(frame.size)))

    var buf = TaintedString""
    if socket.recv(buf, int(frame.size)) != int(frame.size):
        raise newException(IOError, "Failed to read frame size")
    frame.body = buf

    return frame

# Parses a protocol-frame body as a publish message. Pubish messages consist of
# the topic length (4 bytes), followed by the topic and message, in
# network-byte order.
proc parsePublishFrame(body: string, size: int): Message {.raises: [ProtocolError] .} =
    if size < 4:
        raise newException(ProtocolError, "Invalud publish frame")

    # TODO


