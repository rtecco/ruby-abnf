$: << File.join(File.dirname(__FILE__), "../lib")

require 'test/unit'
require 'abnf'

class ABNFTest < Test::Unit::TestCase
  include ABNF
  
  def assert_blank(s)
    assert s.nil? || (s.class == String && s.empty?)
  end
  
  def test_variable_repetition
    assert parse(Repetition.new(3, Alpha.new), "abcdefg")
    assert parse(Repetition.new(1, Alpha.new), "a12345")
    assert_nil parse(Repetition.new(3, Alpha.new), "ab123")
    assert_nil parse(Repetition.new(1, Alpha.new), "123456")
    assert parse(Repetition.new(1..3, Alpha.new), "ab1234")
    assert_nil parse(Repetition.new(3..5, Alpha.new), "ab1234")
    assert parse(Repetition.new(0, Alpha.new), "12345")
    assert parse(Repetition.new(0..4, Alpha.new), "a1234")
    assert parse(Repetition.new(0..1, Alpha.new), "1234")
    assert parse(Repetition.new(0..1, Alpha.new), "a1234")
    assert parse(Repetition.new(0..1, Alpha.new), "ab1234")
    assert parse(Repetition.new([:at_least, 2], Alpha.new){|r| assert_equal "ab", r}, "ab1234")
    assert parse(Repetition.new([:at_least, 2], Alpha.new){|r| assert_equal "abcde", r}, "abcde12")
    assert parse(Repetition.new([:at_most, 3], Alpha.new){|r| assert_equal "abc", r}, "abcdefgh")
    assert parse(Repetition.new([:at_most, 3], Alpha.new), "12345")
    assert parse(Repetition.new([:at_most, 3], Alpha.new){|r| assert_equal "ab", r}, "ab12345")
    assert parse(Concat.new(Optional.new(Digit.new), Alpha.new), "a")
    assert parse(Concat.new(Optional.new(Digit.new), Alpha.new), "1a")
    assert parse(Repetition.new(:any, Alpha.new), "12345")
    assert parse(Repetition.new(:any, Alpha.new), "abcdefg12345")
  end
  
  def test_example_1
        
    # Phone Number
    p1 = Concat.new(Repetition.new(3, Digit.new), Char.new(?-), Repetition.new(4, Digit.new))
    assert_nil parse(p1, "22-3452")
    assert_nil parse(p1, "hello world")
    assert_nil parse(p1, "4293-603")
    assert_nil parse(p1, "")
    assert_nil parse(p1, "4293-3603")
    assert_nil parse(p1, "734-904-2840")
    assert parse(p1, "429-3603")
    
    # Phone Number w/ optional Area Code, same delimiters
    phone_number = Concat.new(Repetition.new(3, Digit.new), Char.new(?-), Repetition.new(4, Digit.new)){|pn| assert_equal "904-2840", pn}
    area_code = Concat.new(Repetition.new(3, Digit.new), Char.new(?-))
    p2 = Alternate.new(Concat.new(area_code, phone_number){|f| assert_equal "734-904-2840", f}, phone_number)
    assert_nil parse(p2, "22-3452")
    assert_nil parse(p2, "hello world")
    assert_nil parse(p2, "4293-603")
    assert_nil parse(p2, "")
    assert_nil parse(p2, "4293-3603")
    assert parse(p2, "904-2840")
    assert parse(p2, "734-904-2840")
    
    # Phone Number w/ optional Area Code, different delimiters
    area_code = Concat.new(Char.new(?(), Repetition.new(3, Digit.new), Char.new(?)))
    p3 = Concat.new(Optional.new(area_code), phone_number)
    assert parse(p3, "904-2840")
  end
end
