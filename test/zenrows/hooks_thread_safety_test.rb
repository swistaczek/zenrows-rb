# frozen_string_literal: true

require "test_helper"

class HooksThreadSafetyTest < Minitest::Test
  def setup
    @hooks = Zenrows::Hooks.new
  end

  def test_concurrent_registration
    threads = 10.times.map do |i|
      Thread.new do
        10.times do |j|
          @hooks.register(:on_response) { |_r, _c| "thread_#{i}_#{j}" }
        end
      end
    end

    threads.each(&:join)

    # Should have 100 callbacks registered without corruption
    refute_predicate @hooks, :empty?
  end

  def test_concurrent_hook_execution
    counter = 0
    mutex = Mutex.new

    @hooks.register(:on_response) do |_r, _c|
      mutex.synchronize { counter += 1 }
    end

    threads = 20.times.map do
      Thread.new do
        50.times { @hooks.run(:on_response, nil, {}) }
      end
    end

    threads.each(&:join)

    assert_equal 1000, counter
  end

  def test_concurrent_registration_and_execution
    execution_count = 0
    mutex = Mutex.new

    @hooks.register(:on_response) do |_r, _c|
      mutex.synchronize { execution_count += 1 }
    end

    registrars = 5.times.map do
      Thread.new do
        10.times do
          @hooks.register(:on_response) do |_r, _c|
            mutex.synchronize { execution_count += 1 }
          end
          sleep 0.001
        end
      end
    end

    executors = 5.times.map do
      Thread.new do
        20.times do
          @hooks.run(:on_response, nil, {})
          sleep 0.001
        end
      end
    end

    (registrars + executors).each(&:join)

    assert_operator execution_count, :>, 0
  end

  def test_concurrent_subscriber_addition
    subscribers = 10.times.map do |i|
      subscriber = Object.new
      subscriber.define_singleton_method(:on_response) { |_r, _c| "sub_#{i}" }
      subscriber
    end

    threads = subscribers.map do |sub|
      Thread.new { @hooks.add_subscriber(sub) }
    end

    threads.each(&:join)

    refute_predicate @hooks, :empty?
  end

  def test_concurrent_around_hooks
    @hooks.register(:around_request) do |_ctx, &block|
      block.call
    end

    threads = 10.times.map do
      Thread.new do
        @hooks.run_around({}) { :result }
      end
    end

    results = threads.map(&:value)

    assert results.all? { |r| r == :result }
  end

  def test_dup_is_thread_safe
    @hooks.register(:on_response) { |_r, _c| "original" }

    copies = []
    mutex = Mutex.new

    threads = 10.times.map do
      Thread.new do
        copy = @hooks.dup
        mutex.synchronize { copies << copy }
      end
    end

    threads.each(&:join)

    assert_equal 10, copies.size
    copies.each { |copy| refute_predicate copy, :empty? }
  end

  def test_empty_check_during_concurrent_registration
    results = []
    mutex = Mutex.new

    threads = 10.times.map do
      Thread.new do
        was_empty = @hooks.empty?
        @hooks.register(:on_response) { |_r, _c| nil }
        mutex.synchronize { results << was_empty }
      end
    end

    threads.each(&:join)

    # At least one thread should have seen empty? as true
    assert_includes results, true
    refute_predicate @hooks, :empty?
  end
end
