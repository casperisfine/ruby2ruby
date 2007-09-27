#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit'
begin require 'rubygems'; rescue LoadError; end
require 'ruby2ruby'
require 'pt_testcase'

# TODO: rename file so autotest stops bitching

class TestRuby2Ruby < Test::Unit::TestCase
  def setup
    @processor = Ruby2Ruby.new
  end

  def test_proc_to_ruby
    block = proc { puts "something" }
    assert_equal %Q|proc {\n  puts("something")\n}|, block.to_ruby
  end

  def test_lit_regexp_slash
    inn = s(:lit, /blah\/blah/)
    out = '/blah\/blah/'

    assert_equal out, @processor.process(inn)

    r = eval(out)
    assert_equal(/blah\/blah/, r)
  end

  def util_thingy(type)
    s(type,
      "blah",
      s(:call, s(:lit, 1), :+, s(:array, s(:lit, 1))),
      s(:str, 'blah"blah/blah'))
  end

  def test_dregx_slash
    inn = util_thingy(:dregx)
    out = '/blah#{(1 + 1)}blah"blah\/blah/'

    assert_equal out, @processor.process(inn)

    r = eval(out)
    assert_equal(/blah2blah"blah\/blah/, r)
  end

  def test_dstr_quote
    inn = util_thingy(:dstr)
    out = '"blah#{(1 + 1)}blah\"blah/blah"'

    assert_equal out, @processor.process(inn)

    r = eval(out)
    assert_equal "blah2blah\"blah/blah", r
  end

  def test_dsym_quote
    inn = util_thingy(:dsym)
    out = ':"blah#{(1 + 1)}blah\"blah/blah"'

    assert_equal out, @processor.process(inn)

    r = eval(out)
    assert_equal :"blah2blah\"blah/blah", r
  end

  eval ParseTreeTestCase.testcases.map { |node, data|
    next if node == "vcall" # HACK

    "def test_#{node}
       pt = #{data['ParseTree'].inspect}
       rb = #{(data['Ruby2Ruby'] || data['Ruby']).inspect}

       assert_not_nil pt, \"ParseTree for #{node} undefined\"
       assert_not_nil rb, \"Ruby for #{node} undefined\"

       assert_equal rb, @processor.process(pt)
     end"
  }.join("\n")
end

##
# Converts a +target+ using a +processor+ and converts +target+ name
# in the source adding +gen+ to allow easy renaming.

def morph_and_eval(processor, target, gen)
  begin
    old_name = target.name
    new_name = target.name.sub(/\d*$/, gen.to_s)
    ruby = processor.translate(target).sub(old_name, new_name)
    eval ruby
    target.constants.each do |constant|
      eval "#{new_name}::#{constant} = #{old_name}::#{constant}"
    end
  rescue SyntaxError => e
    puts
    puts ruby
    puts
    raise e
  rescue => e
    puts
    puts ruby
    puts
    raise e
  end
end

####################
#         impl
#         old  new
#
# t  old    0    1
# e
# s
# t  new    2    3

# Self-Translation: 1st Generation - morph Ruby2Ruby using Ruby2Ruby
morph_and_eval Ruby2Ruby, Ruby2Ruby, 2
class TestRuby2Ruby1 < TestRuby2Ruby
  def setup
    @processor = Ruby2Ruby2.new
  end
end

# Self-Translation: 2nd Generation - morph TestRuby2Ruby using Ruby2Ruby
morph_and_eval Ruby2Ruby, TestRuby2Ruby, 2

# Self-Translation: 3rd Generation - test Ruby2Ruby2 with TestRuby2Ruby1
class TestRuby2Ruby3 < TestRuby2Ruby2
  def setup
    @processor = Ruby2Ruby2.new
  end
end

# Self-Translation: 4th (and final) Generation - fully circular
morph_and_eval Ruby2Ruby2, Ruby2Ruby2, 3
class TestRuby2Ruby4 < TestRuby2Ruby3
  def setup
    @processor = Ruby2Ruby3.new
  end
end
