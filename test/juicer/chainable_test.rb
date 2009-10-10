require "test_helper"

class Host
  include Juicer::Chainable

  def initialize(msg = nil)
    @msg = msg || ""
  end

  def dummy(ios)
    ios.print @msg
  end

  chain_method :dummy

  def unchained(ios)
    ios.print @msg
  end

  def abortable(ios, abort = false)
    ios.print @msg
    abort_chain if abort
  end

  chain_method :abortable
end

class Dummy
end

class TestChainable < Test::Unit::TestCase
  def test_next_initial_state
    host = Host.new
    assert host.respond_to?(:next_in_chain), "Host should respond to next_in_chain()"
    assert_nil host.next_in_chain, "Next command should be nil for newly created object"
  end

  def test_set_next
    host = Host.new
    host2 = Host.new
    host.next_in_chain = host2
    assert_equal host2, host.next_in_chain

    host3 = host.next_in_chain = Host.new
    assert_not_equal host3, host
    assert_not_equal host3, host2
    assert_equal host3, host.next_in_chain
  end

  def test_set_next_return_value
    host = Host.new
    host2 = host.set_next(Host.new)

    assert_not_equal host2, host
    assert_equal host2, host.next_in_chain
  end

  def test_set_next_return_self_if_next_nil
    host = Host.new

    assert_not_nil host.set_next(nil)
    assert_equal host, host.set_next(nil)
  end

  def test_simple_chain
    host = Host.new("a")
    host2 = host.next_in_chain = Host.new("b")
    ios = StringIO.new
    host.dummy(ios)

    assert_equal "ab", ios.string
  end

  def test_unchained_method
    host = Host.new("a")
    host2 = host.next_in_chain = Host.new("b")
    ios = StringIO.new
    host.unchained(ios)

    assert_equal "a", ios.string
  end

  def test_abort_chain
    host = Host.new("a")
    host2 = host.next_in_chain = Host.new("b")
    ios = StringIO.new

    host.abortable(ios)
    assert_equal "ab", ios.string

    host.abortable(ios, true)
    assert_equal "aba", ios.string
  end
end
