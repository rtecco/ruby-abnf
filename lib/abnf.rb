
# ABNF (RFC 2234) parser objects.

module ABNF
  class ::Range
    def until_end # &blk
      self.last.times{|i| yield i}
    end
  end
  
  class RangeWithInfiniteUpperBound
    def initialize(first)
      @first = first
    end
    
    def first
      @first
    end
    
    def until_end # &blk
      i = @first
      
      while true
        i += 1
        yield i
      end
    end
  end
  
  class Stream
    attr_reader :pos
    
    def initialize(s, full = nil, pos = 0)
      @s = s
      @full = full.nil? ? s : full
      @pos = pos
    end
    
    def first
      @s[0]
    end
    
    def rest
      Stream.new(@s[1..-1], @full, @pos + 1)
    end
    
    def clip(start)
      @full[start...@pos]
    end
  end
  
  #
  # Helper Classes
  
  class Satisfies
    
    # Takes a stream, returns a stream or failure. 
    def match(s)
      s.rest if predicate(s.first)
    end
  end

  class Range < Satisfies
    def initialize(r)
      @r = r
    end
  
    def predicate(c)
      @r.member?(c)
    end
  end

  #
  # Core Operators

  # Remember to place the longest matches first!
  class Alternate
    def initialize(*choices, &blk)
      @choices = choices
      @blk = blk
    end
  
    def match(strm)
      start = strm.pos
      
      @choices.each {
        |c|
        
        n_strm = c.match(strm);
        
        if n_strm
          @blk.call(n_strm.clip(start)) unless @blk.nil?
          
          return n_strm
        end
      }
      
      return nil
    end
  end

  class Concat
    def initialize(*choices, &blk)
      @choices = choices
      @blk = blk
    end
  
    def match(strm)
      c_strm = strm
      start = c_strm.pos
      
      @choices.each {
        |c|
        
        c_strm = c.match(c_strm)
        
        return nil if c_strm.nil?
      }
      
      @blk.call(c_strm.clip(start)) unless @blk.nil?
      
      return c_strm
    end
  end

  class Repetition
    
    # Spec: range (between), integer (exact), [:at_most, N], [:at_least, N], :any (zero or more)
    def initialize(spec, what, &blk)
      @spec = spec
      @what = what
      @blk = blk
    end
    
    def match(strm)
      c_strm = strm
      start = strm.pos
      
      r = \
        case @spec
        when Array # :at_least, :at_most
          option, i = @spec
          
          if option == :at_most
            (0..i)
          elsif option == :at_least
            RangeWithInfiniteUpperBound.new(i)
          end
        when Integer # Exact
          @spec..@spec
        when ::Range # Between
          @spec
        when Symbol # Any (zero or more)
          RangeWithInfiniteUpperBound.new(0)
        end
      
      r.until_end {
        |i|

        tried = @what.match(c_strm)

        if tried.nil?
          if i < r.first
            return nil
          else
            break
          end
        else
          c_strm = tried
        end
      }

      @blk.call(c_strm.clip(start)) unless @blk.nil?
      
      c_strm
    end
  end
  
  class Optional < Repetition 
    def initialize(what)
      super([:at_most, 1], what)
    end
  end
    	
  #
  # Core Rules
  #
  # I tried to preserve the RFC names where possible.

  class Char < Satisfies
    def initialize(c)
      @char = c
    end

    def predicate(c)
      c == @char
    end
  end
  
  class Alpha < Alternate; def initialize; super(Range.new(0x41..0x5A), Range.new(0x61..0x7A)) end end
  class AsciiChar < Range; def initialize; super(0x1..0x7F) end end # char
  class Bit < Alternate; def initialize; super(Char.new(?0), Char.new(?1)) end end
  class CR < Char; def initialize; super(0x0D) end end # carriage return
  class LF < Char; def initialize; super(0x0A) end end # line feed
  class CRLF < Concat; def initialize; super(CR.new, LF.new) end end # Internet standard newline
  class Ctl < Alternate; def initialize; super(Range.new(0..0x1F), Char.new(0x7F)) end end # control characters
  class Digit < Range; def initialize; super(0x30..0x39) end end
  class DQuote < Char; def initialize; super(0x22) end end # double quote
  class HTab < Char; def initialize; super(0x9) end end # horizontal tab
  class SP < Char; def initialize; super(0x20) end end # space
  class Octet < Range; def initialize; super(0..255) end end # any 8-bit data value
  class VChar < Range; def initialize; super(0x21..0x7E) end end # visible (printing) characters
  class WSP < Alternate; def initialize; super(SP.new, HTab.new) end end # whitespace
    
  class HexDigit < Alternate
    def initialize
      super(Digit.new, Range.new(0x41..0x46), Range.new(0x61..0x66))
    end
  end
  
  class LWSP < Repetition # Linear white space (past newline)
    def initialize
      super(:any, Alternate.new(WSP.new, Concat.new(CRLF.new, WSP.new)))
    end
  end
    
  def parse(parser, str)
    parser.match(Stream.new(str))
  end
end
