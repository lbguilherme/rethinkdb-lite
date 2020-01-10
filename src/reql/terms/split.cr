require "../term"

module ReQL
  class SplitTerm < Term
    infix_inspect "split"

    def check
      expect_args 1, 3
    end
  end

  class Evaluator
    def eval(term : SplitTerm)
      str = eval(term.args[0]).string_value

      sep = nil
      if term.args.size >= 2
        sep = eval(term.args[1]).string_or_nil_value
      end

      max = nil
      if term.args.size >= 3
        max = eval(term.args[2]).int64_value.to_i32
      end

      if sep == ""
        arr = if max && max < str.size
                str.chars.first(max).map &.to_s + [str[max..-1]]
              else
                str.chars.map &.to_s
              end
        arr.reject! { |x| x == "" }
      elsif sep.nil?
        sep = /\s+/
        str = str.sub(/^#{sep}/, "")
        arr = if max
                str.split(sep, max + 1)
              else
                str.split(sep)
              end
        if arr.size > 0
          arr[0] = arr[0].strip
        end
        if arr.size > 0 && (!max || arr.size <= max)
          arr[-1] = arr[-1].strip
        end
        arr.reject! { |x| x == "" }
      else
        arr = if max
                str.split(sep, max + 1)
              else
                str.split(sep)
              end
      end

      Datum.new(arr.map &.as(Datum::Type))
    end
  end
end
