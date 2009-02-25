$: << File.join(File.dirname(__FILE__), "../lib")

require 'test/unit'
require 'abnf'

# The rules and state for a URL parser. Taken almost verbatim from RFC 3986.
# There is no support for IP-literal, IPvFuture, or IPv6address.
# These rules are not implemented: absolute_uri, path, reserved and gen_delims although there is
# no functional reason that they couldn't be.

class URLParser  
  include ABNF

  URL = Struct.new("URL", :fragment, :host, :path, :port, :scheme, :user)
  
  # API
  
  def parse(str)
    @result = Struct::URL.new
    
    if uri_reference.match(Stream.new(str))
      @result
    else
      raise RuntimeError.new("Parse error")
    end
  end
  
  # Rules
  
  def scheme
    Concat.new(Alpha.new, Repetition.new(:any, Alternate.new(Alpha.new, Digit.new,
      Char.new(?+), Char.new(?-), Char.new(?.)))){|s| @result.scheme = s}
  end
  
  def dec_octet
    Alternate.new(Concat.new(Char.new(?2), Char.new(?5), Range.new(0x30..0x35)), # 250-255    
      Concat.new(Char.new(?2), Range.new(0x30..0x34), Digit.new), # 200-249
      Concat.new(Char.new(?1), Repetition.new(2, Digit.new)), # 100-199
      Concat.new(Range.new(0x31..0x39), Digit.new), # 10-99                  
      Digit.new) # 0-9
  end
  
  def pct_encoded
    Concat.new(Char.new(?%), HexDigit.new, HexDigit.new)
  end
  
  def sub_delims
    Alternate.new(Char.new(?!), Char.new(?$), Char.new(?&), Char.new(?'), Char.new(?(), 
      Char.new(?)), Char.new(?*), Char.new(?+), Char.new(?,), Char.new(?;), Char.new(?=))
  end
  
  def unreserved
    Alternate.new(Alpha.new, Digit.new, Char.new(?-), Char.new(?.), Char.new(?_), Char.new(?~))
  end
  
  def pchar
    Alternate.new(unreserved, pct_encoded, sub_delims, Char.new(?:), Char.new(?@))
  end
  
  def ipv4_address
    Concat.new(dec_octet, Char.new(?.), dec_octet, Char.new(?.), dec_octet, Char.new(?.), dec_octet)
  end
  
  def reg_name
    Repetition.new(:any, Alternate.new(unreserved, pct_encoded, sub_delims))
  end
  
  def host
    Alternate.new(ipv4_address, reg_name){|host| @result.host = host}
  end
  
  def port
    Repetition.new(:any, Digit.new){|port| @result.port = port.to_i}
  end
  
  def userinfo
    Repetition.new(:any, Alternate.new(unreserved, pct_encoded, sub_delims, Char.new(?:))){|u| @result.user = u}
  end
  
  def authority
    Concat.new(Optional.new(Concat.new(userinfo, Char.new(?@))), host, Optional.new(Concat.new(Char.new(?:), port)))
  end
    
  def segment
    Repetition.new(:any, pchar)
  end

  def segment_nz
    Repetition.new([:at_least, 1], pchar)
  end
  
  def segment_nz_nc # non-zero-length segment without any colon
    Repetition.new([:at_least, 1], Alternate.new(unreserved, pct_encoded, sub_delims, Char.new(?@)))
  end
      	  
  def path_abempty
    Repetition.new(:any, Concat.new(Char.new(?/), segment)){|path| @result.path = path}
  end
  
  def path_absolute
    Concat.new(Char.new(?/),
      Optional.new(Concat.new(segment_nz, Repetition.new(:any, Concat.new(Char.new(?/), segment))))){|path| @result.path = path}
  end

  def path_empty
    Repetition.new(0, pchar){|path| @result.path = path}
  end

  def path_noscheme
    Concat.new(segment_nz_nc, Repetition.new(:any, Concat.new(Char.new(?/), segment)))
  end
  
  def path_rootless
    Concat.new(segment_nz, Repetition.new(:any, Concat.new(Char.new(?/), segment))){|path| @result.path = path}
  end
    	
  def hier_part
    Alternate.new(Concat.new(Char.new(?/), Char.new(?/), authority, path_abempty),
      path_absolute,
      path_rootless,
      path_empty)
  end
  
  def query
    Repetition.new(:any, Alternate.new(pchar, Char.new(?/), Char.new(??))){|query| puts query}
  end
  
  def fragment
    Repetition.new(:any, Alternate.new(pchar, Char.new(?/), Char.new(??))){|fragment| @result.fragment = fragment}
  end
  
  def uri
    Concat.new(scheme,
      Char.new(?:),
      hier_part,
      Optional.new(Concat.new(Char.new(??), query)),
      Optional.new(Concat.new(Char.new(?#), fragment)))
  end

  def relative_part
    Alternate.new(Concat.new(Char.new(?/), Char.new(?/), authority, path_abempty),
      path_absolute,
      path_noscheme,
      path_empty)
  end
  
  def relative_ref
    Concat.new(relative_part,
      Optional.new(Concat.new(Char.new(??), query)),
      Optional.new(Concat.new(Char.new(?#), fragment)))
  end
  
  def uri_reference
    Alternate.new(uri, relative_ref)
  end
end

class ABNFTest < Test::Unit::TestCase
  include ABNF
  
  def test_url_parser
        
    #
    # URLs
        
    u = URLParser.new.parse("http://karmalab.org")
    assert u
    assert_equal "http", u.scheme
    assert_equal "karmalab.org", u.host
    assert_nil u.port
    assert_equal "", u.path
    
    u = URLParser.new.parse("http://rt@karmalab.org:9001")
    assert u
    assert_equal "http", u.scheme
    assert_equal "karmalab.org", u.host
    assert_equal 9001, u.port
    assert_equal "rt", u.user
    assert_equal "", u.path
    
    u = URLParser.new.parse("file:///tmp/file.txt")
    assert u
    assert_equal "file", u.scheme
    assert_equal "/tmp/file.txt", u.path
    assert_blank u.host
    assert_blank u.port
    assert_blank u.user
    
    u = URLParser.new.parse("http://triggit.com/j?u=rt10880&p=http://lambda/#fragment16")
    assert u
    assert_equal "http", u.scheme
    assert_equal "triggit.com", u.host
    assert_equal "/j", u.path
    assert_equal "fragment16", u.fragment
    
    u = URLParser.new.parse("about:config")
    assert u
    assert_equal "about", u.scheme
    assert_equal "config", u.path
    
    u = URLParser.new.parse("/path/to/file.html#fr23-1")
    assert u
    assert_equal "/path/to/file.html", u.path
    assert_equal "fr23-1", u.fragment
  end
end
