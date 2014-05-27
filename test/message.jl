using Base.Test
using Cocaine
using Msgpack

const ch = 99
const msg1 = "MSG1"
const msg2 = "MSG2"
const uuid = "d4387e2a-ed30-4ba1-a26f-6493926db859"

msg = Cocaine.Handshake(ch, uuid)
p = Cocaine.pack(msg)
u = Msgpack.unpack(p)
@test u[1] == Cocaine.HANDSHAKE
@test u[2] == ch
@test u[3][1] == uuid

msg = Cocaine.Handshake(ch, uuid)
p = Cocaine.pack(msg)
u = Cocaine.unpack(p)
@test typeof(msg) == typeof(u)
@test msg.MsgInfo.Id == u.MsgInfo.Id
@test msg.MsgInfo.Session == u.MsgInfo.Session
@test msg.Uuid == u.Uuid

msg = Cocaine.Heartbeat(ch)
p = Cocaine.pack(msg)
u = Cocaine.unpack(p)
@test typeof(msg) == typeof(u)
@test msg.MsgInfo.Session == u.MsgInfo.Session
@test msg.MsgInfo.Id == u.MsgInfo.Id

msg = Cocaine.Choke(ch)
p = Cocaine.pack(msg)
u = Cocaine.unpack(p)
@test typeof(msg) == typeof(u)
@test msg.MsgInfo.Session == u.MsgInfo.Session

msg = Cocaine.Terminate(ch, -1, msg2)
p = Cocaine.pack(msg)
u = Cocaine.unpack(p)
@test typeof(msg) == typeof(u)
@test msg.MsgInfo.Id == u.MsgInfo.Id
@test msg.MsgInfo.Session == u.MsgInfo.Session
@test msg.Reason == u.Reason
@test msg.Message == u.Message

msg = Cocaine.Invoke(ch, msg1)
p = Cocaine.pack(msg)
u = Cocaine.unpack(p)
@test typeof(msg) == typeof(u)
@test msg.MsgInfo.Id == u.MsgInfo.Id
@test msg.MsgInfo.Session == u.MsgInfo.Session
@test msg.Event == u.Event

msg = Cocaine.Error(ch, ch, msg1)
p = Cocaine.pack(msg)
u = Cocaine.unpack(p)
@test typeof(msg) == typeof(u)
@test msg.MsgInfo.Id == u.MsgInfo.Id
@test msg.MsgInfo.Session == u.MsgInfo.Session
@test msg.Code == u.Code
@test msg.Message == u.Message

msg = Cocaine.Chunk(ch, p)
pc = Cocaine.pack(msg)
uc = Cocaine.unpack(pc)
@test typeof(msg) == typeof(uc)
@test msg.MsgInfo.Id == uc.MsgInfo.Id
@test msg.MsgInfo.Session == uc.MsgInfo.Session
@test msg.Data == uc.Data

msg = Cocaine.Internal(ch, ch, msg1)
p = Cocaine.pack(msg)
u = Cocaine.unpack(p)
@test typeof(msg) == typeof(u)
@test msg.MsgInfo.Id == u.MsgInfo.Id
@test msg.MsgInfo.Session == u.MsgInfo.Session
@test msg.Code == u.Code
@test msg.Message == u.Message
