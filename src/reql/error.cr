module ReQL
  class ClientError < Exception
  end

  class CompileError < Exception
  end

  class DriverCompileError < CompileError
  end

  class RuntimeError < Exception
  end

  class InternalError < RuntimeError
  end

  class ResourceLimitError < RuntimeError
  end

  class QueryLogicError < RuntimeError
  end

  class NonExistenceError < RuntimeError
  end

  class OpFailedError < RuntimeError
  end

  class OpIndeterminateError < RuntimeError
  end

  class UserError < RuntimeError
  end

  class PermissionError < RuntimeError
  end
end
