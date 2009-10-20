require File.dirname(__FILE__) + '/../lib/chronic'
require 'test/unit'

class TestChronic < Test::Unit::TestCase

	def setup
		# Wed Aug 16 14:00:00 UTC 2006
		@now = Time.local(2006, 8, 16, 14, 0, 0, 0)
	end

	def test_post_normalize_am_pm_aliases
		# affect wanted patterns

		tokens = [Chronic::Token.new("5:00"), Chronic::Token.new("morning")]
		tokens[0].tag(Chronic::RepeaterTime.new("5:00"))
		tokens[1].tag(Chronic::RepeaterDayPortion.new(:morning))

		assert_equal :morning, tokens[1].tags[0].type

		tokens = Chronic.dealias_and_disambiguate_times(tokens, {})

		assert_equal :am, tokens[1].tags[0].type
		assert_equal 2, tokens.size

		# don't affect unwanted patterns

		tokens = [Chronic::Token.new("friday"), Chronic::Token.new("morning")]
		tokens[0].tag(Chronic::RepeaterDayName.new(:friday))
		tokens[1].tag(Chronic::RepeaterDayPortion.new(:morning))

		assert_equal :morning, tokens[1].tags[0].type

		tokens = Chronic.dealias_and_disambiguate_times(tokens, {})

		assert_equal :morning, tokens[1].tags[0].type
		assert_equal 2, tokens.size
	end

	def test_guess
		span = Chronic::Span.new(Time.local(2006, 8, 16, 0), Time.local(2006, 8, 17, 0))
		assert_equal Time.local(2006, 8, 16, 12), Chronic.guess(span)

		span = Chronic::Span.new(Time.local(2006, 8, 16, 0), Time.local(2006, 8, 17, 0, 0, 1))
		assert_equal Time.local(2006, 8, 16, 12), Chronic.guess(span)

		span = Chronic::Span.new(Time.local(2006, 11), Time.local(2006, 12))
		assert_equal Time.local(2006, 11, 16), Chronic.guess(span)
	end
	
	def test_date_string
	  assert_equal("9pm", Chronic.date_string("9pm"))
	  assert_equal("9/27/2009", Chronic.date_string("9/27/2009"))
	  assert_equal("9/27/2009", Chronic.date_string("Meeting 9/27/2009"))
	  assert_equal("today", Chronic.date_string("Meeting today"))
	end
	
	def test_tokenize_ignores_trailing_tokens
	  # tokenize will keep tokens like "at" in the string "Meeting 9/27/2009 at the bar" even though it is
	  # not part of the date
	  tokens = Chronic.tokenize("9/27/2009 at")
	  assert_nil(tokens[-1].get_tag(Chronic::Separator), "The last token in this string should not be tagged")
	  assert_equal("9/27/2009", Chronic.date_string("9/27/2009 at"))
	  
	  # test a string with two of the same separator -- one of which will be tagged, one will not
	  separator_test = "Meeting 9/27/2009 at 7pm at the bar"
	  tokens = Chronic.tokenize(separator_test)
	  assert_not_nil(tokens[6].get_tag(Chronic::Separator))
	  assert_nil(tokens[9].get_tag(Chronic::Separator))
	  assert_equal("Meeting at the bar", Chronic.strip_tokens(separator_test))
	  assert_equal("9/27/2009 at 7pm", Chronic.date_string(separator_test), "date_string does not return the correct date string for <#{separator_test}>")
	  
	  # because the trailing "at" separator here is not tagged anymore, it will be part of the strip_tokens string
	  assert_equal("Meeting at the bar", Chronic.strip_tokens("Meeting 9/27/2009 at the bar"))
	end
end
