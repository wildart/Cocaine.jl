using Msgpack

const HANDSHAKE = 0
const HEARTBEAT = 1
const TERMINATE = 2
const INVOKE    = 3
const CHUNK     = 4
const ERROR     = 5
const CHOKE     = 6
const INTERNAL  = 255

abstract Message

type MessageInfo
    Id::Int64
    Session::Int64
end

type Handshake <: Message
    MsgInfo::MessageInfo
    Uuid::String
    Handshake(ch::Int64, uuid::String) = new(MessageInfo(HANDSHAKE, ch), uuid)
end

type Heartbeat <: Message
    MsgInfo::MessageInfo
    Heartbeat(ch::Int64) = new(MessageInfo(HEARTBEAT, ch))
end

type Terminate <: Message
    MsgInfo::MessageInfo
    Reason::Int
    Message::String
    Terminate(ch::Int64, reason::Int, message::String) = new(MessageInfo(TERMINATE, ch), reason, message)
end

type Invoke <: Message
    MsgInfo::MessageInfo
    Event::String    
    Invoke(ch::Int64, event::String) = new(MessageInfo(INVOKE, ch), event)
end

type Chunk <: Message
    MsgInfo::MessageInfo
    Data::Vector{Uint8}
    Chunk(ch::Int64, data::Vector{Uint8}) = new(MessageInfo(CHUNK, ch), data)
end

type Error <: Message
    MsgInfo::MessageInfo
    Code::Int64
    Message::String    
    Error(ch::Int64, code::Int64, msg::String) = new(MessageInfo(ERROR, ch), code, msg)
end

type Choke <: Message
    MsgInfo::MessageInfo
    Choke(ch::Int64) = new(MessageInfo(CHOKE, ch))
end

type Internal <: Message
    MsgInfo::MessageInfo
    Code::Int64
    Message::String    
    Internal(ch::Int64, code::Int64, msg::String) = new(MessageInfo(INTERNAL, ch), code, msg)
end

function pack{T<:Message}(msg::T)
	msginfo = getfield(msg, :MsgInfo)
	res = Any[getfield(msginfo, :Id), getfield(msginfo, :Session)]
	payload = Any[]
	if typeof(msg) <: Handshake
		push!(payload, string(getfield(msg, :Uuid)))
	elseif typeof(msg) <: Terminate
		push!(payload, getfield(msg, :Reason))
		push!(payload, string(getfield(msg, :Message)))
	elseif typeof(msg) <: Invoke
		push!(payload, string(getfield(msg, :Event)))
	elseif typeof(msg) <: Chunk
		push!(payload, bytestring(getfield(msg, :Data)))
	elseif typeof(msg) <: Error || typeof(msg) <: Internal
		push!(payload, getfield(msg, :Code))
		push!(payload, string(getfield(msg, :Message)))
	end	
	push!(res, payload)	
	return Msgpack.pack(res)
end

function unpack(msg::Array{Uint8,1})
	unpkd = Msgpack.unpack(msg)
	if unpkd[1] == HANDSHAKE
		return Handshake(unpkd[2], unpkd[3][1])
	elseif unpkd[1] == HEARTBEAT
		return Heartbeat(unpkd[2])
	elseif unpkd[1] == TERMINATE
		return Terminate(unpkd[2], unpkd[3][1], unpkd[3][2])
	elseif unpkd[1] == INVOKE
		return Invoke(unpkd[2], unpkd[3][1])
	elseif unpkd[1] == CHUNK
		return Chunk(unpkd[2], convert(Vector{Uint8}, unpkd[3][1]))
	elseif unpkd[1] == ERROR
		return Error(unpkd[2], unpkd[3][1], unpkd[3][2])
	elseif unpkd[1] == CHOKE
		return Choke(unpkd[2])
	elseif unpkd[1] == INTERNAL
		return Internal(unpkd[2], unpkd[3][1], unpkd[3][2])
	end	
end

id(msg::Message) = msg.MsgInfo.Id
sessionid(msg::Message) = msg.MsgInfo.Session