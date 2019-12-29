module RethinkDB
  module Server
    class Client
      property streams = {} of UInt64 => RethinkDB::Cursor

      def initialize(@conn : RethinkDB::Connection)
      end

      def close
        @streams.each_value &.close
        @streams.clear
      end

      def execute(query_id : UInt64, message : Array)
        begin
          answer = nil
          case message[0]
          when 1 # START
            term = ReQL::Term.parse(message[1])
            runopts = message[2]?.try &.as_h? || {} of String => JSON::Any

            result = @conn.run(term, RunOpts.new(runopts))
            case result
            when RethinkDB::Cursor
              list = result.first(40).to_a
              if list.size == 40
                @streams[query_id] = result
              end
              answer = {
                t: list.size == 40 ? 3 : 2,
                r: list,
                n: [] of String,
              }
            when RethinkDB::Datum
              answer = {
                t: 1,
                r: [result],
                n: [] of String,
              }
            else
              raise "BUG"
            end
          when 2 # CONTINUE
            result = @streams[query_id]
            list = result.first(40).to_a
            if list.size < 40
              @streams.delete query_id
            end
            answer = {
              t: list.size == 40 ? 3 : 2,
              r: list,
              n: [] of String,
            }
          when 3 # STOP
            result = @streams[query_id]?
            if result
              result.close
              @streams.delete query_id
            end
            answer = {
              t: 2,
              r: [] of String,
              n: [] of String,
            }
          when 4 # NOREPLY_WAIT
            # TODO: Wait for previous noreply operations to finish
            answer = {
              t: 4,
              r: [] of String,
              n: [] of String,
            }
          when 5 # SERVER_INFO
            answer = {
              t: 5,
              r: [@conn.server],
              n: [] of String,
            }
          else
            raise ReQL::InternalError.new "Invalid type of query: #{message.inspect}"
          end

          return answer
        rescue ex : ReQL::CompileError
          return {t: 17, r: [ex.message], b: [] of String}
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
          return {t: 18, e: error_type, r: [ex.message], b: [] of String}
        rescue ex
          ex.inspect_with_backtrace
          return {t: 18, e: 1000000, r: [ex.message], b: [] of String}
        end
      end
    end
  end
end
