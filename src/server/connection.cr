module Server
  class ClientConnection
    property streams = {} of UInt64 => ReQL::Stream
  end
end
