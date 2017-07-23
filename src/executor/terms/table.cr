class TableTerm < Term
  register_type TABLE

  def inspect(io)
    io << "r.table("
    @args.each_with_index do |e, i|
      e.inspect(io)
      io << ", " unless i == @args.size - 1
    end
    io << ")"
  end
end
