module Server
  class ClientConnection
    property streams = {} of UInt64 => ReQL::Stream

    def execute(query_id : UInt64, message : Array)
      begin
        start = Time.now
        answer = nil
        case message[0]
        when 1 # START
          query = ReQL::Query.new(query_id, message[1], message[2]?.as(Hash(String, JSON::Type) | Nil))
          result = query.run
          if result.is_a? ReQL::Stream
            result.start_reading
            @streams[query_id] = result
            list = [] of ReQL::Datum::Type
            has_more = true
            40.times do
              tup = result.next_val
              unless tup
                @streams.delete query_id
                result.finish_reading
                has_more = false
                break
              end
              list << tup[0]
            end
            answer = {
              "t" => has_more ? 3 : 2,
              "r" => list,
              "n" => [] of String,
            }
          else
            answer = {
              "t" => 1,
              "r" => [result.value],
              "n" => [] of String,
            }
          end
        when 2 # CONTINUE
          result = @streams[query_id]?
          list = [] of ReQL::Datum::Type
          has_more = true
          if result
            40.times do
              tup = result.next_val
              unless tup
                @streams.delete query_id
                result.finish_reading
                has_more = false
                break
              end
              list << tup[0]
            end
          else
            has_more = false
          end
          answer = {
            "t" => has_more ? 3 : 2,
            "r" => list,
            "n" => [] of String,
          }
        when 3 # STOP
          result = @streams[query_id]?
          if result
            @streams.delete query_id
            result.finish_reading
          end
          answer = {
            "t" => 2,
            "r" => [] of String,
            "n" => [] of String,
          }
        when 4 # NOREPLY_WAIT
        when 5 # SERVER_INFO
          info = {
            "id"    => Storage::Config.server_info.name,
            "name"  => Storage::Config.server_info.name,
            "proxy" => false,
          }
          answer = {"t" => 5, "r" => [info]}
        end

        if !answer
          raise ReQL::InternalError.new "Invalid type of query."
        end

        if query && query.profile?
          answer = {
            "t" => answer["t"],
            "r" => answer["r"],
            "n" => answer["n"],
            "p" => [{"duration(ms)" => (Time.now - start).to_f * 1000}],
          }
        end

        return answer.to_json
      rescue ex : ReQL::CompileError
        return {"t" => 17, "r" => [ex.message], "b" => [] of String}.to_json
      rescue ex : ReQL::RuntimeError
        error_type = case ex
                     when ReQL::InternalError       ; 1000000
                     when ReQL::ResourceLimitError  ; 2000000
                     when ReQL::QueryLogicError     ; 3000000
                     when ReQL::NonExistenceError   ; 3100000
                     when ReQL::OpFailedError       ; 4100000
                     when ReQL::OpIndeterminateError; 4200000
                     when ReQL::UserError           ; 5000000
                     when ReQL::PermissionError     ; 6000000
                     else                             0
                     end
        return {"t" => 18, "e" => error_type, "r" => [ex.message], "b" => [] of String}.to_json
      rescue ex
        ex.inspect_with_backtrace
        return {"t" => 18, "e" => 1000000, "r" => [ex.message], "b" => [] of String}.to_json
      end

      return "BUG"
    end
  end
end
