using Cocaine
using Msgpack
using UUID

const ch = 99
const msg1 = "MSG1"
const msg2 = "MSG2"
const uuid = UUID.v1()

msg = Cocaine.Handshake(ch, uuid)
p = Cocaine.pack(msg)
u = Msgpack.unpack(p)
@assert u[1] == Cocaine.HANDSHAKE
@assert u[2] == ch
@assert u[3] == string(uuid)

msg = Cocaine.Heartbeat(ch)
p = Cocaine.pack(msg)
u = Msgpack.unpack(p)
@assert u[1] == Cocaine.HEARTBEAT
@assert u[2] == ch

msg = Cocaine.Terminate(ch, msg1, msg2)
p = Cocaine.pack(msg)
u = Msgpack.unpack(p)
@assert u[1] == Cocaine.TERMINATE
@assert u[2] == ch
@assert u[3] == msg1
@assert u[4] == msg2

msg = Cocaine.Invoke(ch, msg1)
p = Cocaine.pack(msg)
u = Msgpack.unpack(p)
@assert u[1] == Cocaine.INVOKE
@assert u[2] == ch
@assert u[3] == msg1

msg = Cocaine.Chunk(ch, p)
pc = Cocaine.pack(msg)
uc = Msgpack.unpack(pc)
@assert uc[1] == Cocaine.CHUNK
@assert uc[2] == ch
@assert uc[3] == p

msg = Cocaine.Error(ch, ch, msg1)
p = Cocaine.pack(msg)
u = Msgpack.unpack(p)
@assert u[1] == Cocaine.ERROR
@assert u[2] == ch
@assert u[3] == ch
@assert u[4] == msg1

msg = Cocaine.Choke(ch)
p = Cocaine.pack(msg)
u = Msgpack.unpack(p)
@assert u[1] == Cocaine.CHOKE
@assert u[2] == ch

msg_unpk = Cocaine.unpack(p)
@assert msg.MsgInfo.Number == msg_unpk.MsgInfo.Number
@assert msg.MsgInfo.Channel == msg_unpk.MsgInfo.Channel


