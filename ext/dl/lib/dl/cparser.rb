module DL
  # Methods for parsing C struct and C prototype signatures.
  module CParser
    # Parses a C struct's members
    #
    # Example:
    #
    #   parse_struct_signature(['int i', 'char c'])
    #   => [[DL::TYPE_INT, DL::TYPE_CHAR], ["i", "c"]]
    #
    def parse_struct_signature(signature, tymap=nil)
      if( signature.is_a?(String) )
        signature = signature.split(/\s*,\s*/)
      end
      mems = []
      tys  = []
      signature.each{|msig|
        tks = msig.split(/\s+(\*)?/)
        ty = tks[0..-2].join(" ")
        member = tks[-1]

        case ty
        when /\[(\d+)\]/
          n = $1.to_i
          ty.gsub!(/\s*\[\d+\]/,"")
          ty = [ty, n]
        when /\[\]/
          ty.gsub!(/\s*\[\]/, "*")
        end

        case member
        when /\[(\d+)\]/
          ty = [ty, $1.to_i]
          member.gsub!(/\s*\[\d+\]/,"")
        when /\[\]/
          ty = ty + "*"
          member.gsub!(/\s*\[\]/, "")
        end

        mems.push(member)
        tys.push(parse_ctype(ty,tymap))
      }
      return tys, mems
    end

    # Parses a C prototype signature
    #
    # Example:
    #
    #   include DL::CParser
    #   => Object
    #
    #   parse_signature('double sum(double, double)')
    #   => ["sum", DL::TYPE_DOUBLE, [DL::TYPE_DOUBLE, DL::TYPE_DOUBLE]]
    #
    def parse_signature(signature, tymap=nil)
      tymap ||= {}
      signature = signature.gsub(/\s+/, " ").strip
      case signature
      when /^([\w@\*\s]+)\(([\w\*\s\,\[\]]*)\)$/
        ret = $1
        (args = $2).strip!
        ret = ret.split(/\s+/)
        args = args.split(/\s*,\s*/)
        func = ret.pop
        if( func =~ /^\*/ )
          func.gsub!(/^\*+/,"")
          ret.push("*")
        end
        ret  = ret.join(" ")
        return [func, parse_ctype(ret, tymap), args.collect{|arg| parse_ctype(arg, tymap)}]
      else
        raise(RuntimeError,"can't parse the function prototype: #{signature}")
      end
    end

    # Given a String of C type +ty+, return the corresponding DL constant.
    #
    # +ty+ can also accept an Array of C type Strings, and will returned in a
    # corresponding Array.
    #
    # If Hash +tymap+ is provided, +ty+ is expected to be the key, and the
    # value will be the C type to be looked up.
    #
    # Example:
    #
    #   parse_ctype('int')
    #   => DL::TYPE_INT
    #
    #   parse_ctype('double')
    #   => DL::TYPE_DOUBLE
    #
    #   parse_ctype('unsigned char')
    #   => -DL::TYPE_CHAR
    #
    def parse_ctype(ty, tymap=nil)
      tymap ||= {}
      case ty
      when Array
        return [parse_ctype(ty[0], tymap), ty[1]]
      when "void"
        return TYPE_VOID
      when "char"
        return TYPE_CHAR
      when "unsigned char"
        return  -TYPE_CHAR
      when "short"
        return TYPE_SHORT
      when "unsigned short"
        return -TYPE_SHORT
      when "int"
        return TYPE_INT
      when "unsigned int", 'uint'
        return -TYPE_INT
      when "long"
        return TYPE_LONG
      when "unsigned long"
        return -TYPE_LONG
      when "long long"
        if( defined?(TYPE_LONG_LONG) )
          return TYPE_LONG_LONG
        else
          raise(RuntimeError, "unsupported type: #{ty}")
        end
      when "unsigned long long"
        if( defined?(TYPE_LONG_LONG) )
          return -TYPE_LONG_LONG
        else
          raise(RuntimeError, "unsupported type: #{ty}")
        end
      when "float"
        return TYPE_FLOAT
      when "double"
        return TYPE_DOUBLE
      when "size_t"
        return TYPE_SIZE_T
      when "ssize_t"
        return TYPE_SSIZE_T
      when "ptrdiff_t"
        return TYPE_PTRDIFF_T
      when "intptr_t"
        return TYPE_INTPTR_T
      when "uintptr_t"
        return TYPE_UINTPTR_T
      when /\*/, /\[\s*\]/
        return TYPE_VOIDP
      else
        if( tymap[ty] )
          return parse_ctype(tymap[ty], tymap)
        else
          raise(DLError, "unknown type: #{ty}")
        end
      end
    end
  end
end
