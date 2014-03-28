using UUID
using Msgpack

const HANDSHAKE = 0
const HEARTBEAT = 1
const TERMINATE = 2
const INVOKE    = 3
const CHUNK     = 4
const ERROR     = 5
const CHOKE     = 6

abstract Message

type MessageInfo
    Number::Int64
    Channel::Int64
end

type Handshake <: Message
    MsgInfo::MessageInfo
    Uuid::UUID.Uuid
    Handshake(ch::Int64, uuid::UUID.Uuid) = new(MessageInfo(HANDSHAKE, ch), uuid)
end

type Heartbeat <: Message
    MsgInfo::MessageInfo
    Heartbeat(ch::Int64) = new(MessageInfo(HEARTBEAT, ch))
end

type Terminate <: Message
    MsgInfo::MessageInfo
    Reason::ASCIIString
    Message::ASCIIString
    Terminate(ch::Int64, reason::ASCIIString, message::ASCIIString) = new(MessageInfo(TERMINATE, ch), reason, message)
end

type Invoke <: Message
    MsgInfo::MessageInfo
    Event::ASCIIString    
    Invoke(ch::Int64, event::ASCIIString) = new(MessageInfo(INVOKE, ch), event)
end

type Chunk <: Message
    MsgInfo::MessageInfo
    Data::Array{Uint8,1}
    Chunk(ch::Int64, data::Array{Uint8,1}) = new(MessageInfo(CHUNK, ch), data)
end

type Error <: Message
    MsgInfo::MessageInfo
    Code::Int64
    Message::ASCIIString    
    Error(ch::Int64, code::Int64, msg::ASCIIString) = new(MessageInfo(ERROR, ch), code, msg)
end

type Choke <: Message
    MsgInfo::MessageInfo
    Choke(ch::Int64) = new(MessageInfo(CHOKE, ch))
end

function pack{T<:Message}(msg::T)
	msginfo = getfield(msg, :MsgInfo)
	res = Any[getfield(msginfo, :Number), getfield(msginfo, :Channel)]
	if typeof(msg) <: Handshake
		push!(res, string(getfield(msg, :Uuid)))
	elseif typeof(msg) <: Terminate
		push!(res, string(getfield(msg, :Reason)))
		push!(res, string(getfield(msg, :Message)))
	elseif typeof(msg) <: Invoke
		push!(res, string(getfield(msg, :Event)))
	elseif typeof(msg) <: Chunk
		push!(res, getfield(msg, :Data))
	elseif typeof(msg) <: Error
		push!(res, getfield(msg, :Code))
		push!(res, string(getfield(msg, :Message)))
	end
	return Msgpack.pack(res)
end

function unpack(msg::Array{Uint8,1})
	unpkd = Msgpack.unpack(msg)
	if unpkd[1] == HANDSHAKE
		return Handshake(unpkd[2], unpkd[3])
	elseif unpkd[1] == HEARTBEAT
		return Heartbeat(unpkd[2], UUID.Uuid(unpkd[3]))
	elseif unpkd[1] == TERMINATE
		return Terminate(unpkd[2], unpkd[3], unpkd[4])
	elseif unpkd[1] == INVOKE
		return Invoke(unpkd[2], unpkd[3])
	elseif unpkd[1] == CHUNK
		return Chunk(unpkd[2], unpkd[3])
	elseif unpkd[1] == ERROR
		return Error(unpkd[2], unpkd[3], unpkd[4])
	elseif unpkd[1] == CHOKE
		return Choke(unpkd[2])
	end	
end