# frozen_string_literal: true
require_relative '../test_helper'

module Opus::Types::Test
  class ConfigurationTest < Critic::Unit::UnitTest
    before do
      @mod = Module.new do
        extend T::Sig
        # Make it public for testing only
        public_class_method :sig
      end
    end

    class CustomReceiver
      def self.receive(*); end
    end

    describe 'disable_runtime_typecheck!' do
      before do
        @old_t = ::T

        T::Configuration.disable_runtime_typecheck!
      end

      after do
        Object.send(:remove_const, :T)
        ::T = @old_t
      end

      it 'does not check sig' do
        mod = Module.new do
          extend T::Sig

          sig {params(x: Integer).void}
          def self.foo(x); end
        end

        mod.foo("hello")
      end

      it 'does not check T.must' do
        val = T.must(nil)

        assert_nil(val)
      end

      it 'does not check T.let' do
        val = T.let("1", Integer)

        assert_equal("1", val)
      end

      it 'does not check T.cast' do
        val = T.cast("1", Integer)

        assert_equal("1", val)
      end

      it 'does not check T.assert_type!' do
        T.assert_type!("1", Integer)
      end

      it 'does not check abstract' do
        mod = Module.new do
          extend T::Sig
          extend T::Helpers

          abstract!

          sig {abstract.returns(Object)}
          def self.foo; end
        end

        mod.foo
      end

      it 'does not check interface' do
        base = Module.new do
          extend T::Sig
          extend T::Helpers
          interface!

          sig {abstract.void}
          def foo; end
        end

        klass = Class.new do
          include base
        end

        klass.new.foo
      end

      it 'does not check struct' do
        struct = Class.new(T::Struct) do
          prop :x, Integer
          const :y, String
        end

        a = struct.new(x: "hello", y: 10)
        a.x = "foobar"
        assert_equal("foobar", a.x)
        assert_equal(10, a.y)

        assert_raises do
          a.y = 20
        end
      end
    end

    describe 'inline_type_error_handler' do
      describe 'when in default state' do
        it 'T.must raises an error' do
          assert_raises(TypeError) do
            T.must(nil)
          end
        end

        it 'T.let raises an error' do
          assert_raises(TypeError) do
            T.let(1, String)
          end
        end
      end

      describe 'when overridden' do
        before do
          T::Configuration.inline_type_error_handler = lambda do |*args|
            CustomReceiver.receive(*args)
          end
        end

        after do
          T::Configuration.inline_type_error_handler = nil
        end

        it 'handles a T.must error' do
          CustomReceiver.expects(:receive).once.with do |error|
            error.is_a?(TypeError)
          end
          assert_nil(T.must(nil))
        end

        it 'handles a T.let error' do
          CustomReceiver.expects(:receive).once.with do |error|
            error.is_a?(TypeError)
          end
          assert_equal(1, T.let(1, String))
        end
      end
    end

    describe 'sig_builder_error_handler' do
      describe 'when in default state' do
        it 'raises an error' do
          @mod.sig {returns(Symbol).void}
          def @mod.foo
            :bar
          end
          ex = assert_raises(ArgumentError) do
            @mod.foo
          end
          assert_includes(
            ex.message,
            "You can't call .void after calling .returns."
          )
        end
      end

      describe 'when overridden' do
        before do
          T::Configuration.sig_builder_error_handler = lambda do |*args|
            CustomReceiver.receive(*args)
          end
        end

        after do
          T::Configuration.sig_builder_error_handler = nil
        end

        it 'handles a sig builder error' do
          CustomReceiver.expects(:receive).once.with do |error, location|
            error.message == "You can't call .void after calling .returns." &&
              error.is_a?(T::Private::Methods::DeclBuilder::BuilderError) &&
              location.is_a?(Thread::Backtrace::Location)
          end
          @mod.sig {returns(Symbol).void}
          def @mod.foo
            :bar
          end
          assert_equal(:bar, @mod.foo)
        end
      end
    end

    describe 'sig_validation_error_handler' do
      describe 'when in default state' do
        it 'raises an error' do
          @mod.sig {override.returns(Symbol)}
          def @mod.foo
            :bar
          end
          ex = assert_raises(RuntimeError) do
            @mod.foo
          end
          assert_includes(
            ex.message,
            "You marked `foo` as .override, but that method doesn't already exist"
          )
        end
      end

      describe 'when overridden' do
        before do
          T::Configuration.sig_validation_error_handler = lambda do |*args|
            CustomReceiver.receive(*args)
          end
        end

        after do
          T::Configuration.sig_validation_error_handler = nil
        end

        it 'handles a sig build error' do
          CustomReceiver.expects(:receive).once.with do |error, opts|
            error.message.include?("You marked `foo` as .override, but that method doesn't already exist") &&
              error.is_a?(RuntimeError) &&
              opts.is_a?(Hash) &&
              opts[:method].is_a?(UnboundMethod) &&
              opts[:declaration].is_a?(T::Private::Methods::Declaration) &&
              opts[:signature].is_a?(T::Private::Methods::Signature)
          end

          @mod.sig {override.returns(Symbol)}
          def @mod.foo
            :bar
          end
          assert_equal(:bar, @mod.foo)
        end
      end
    end

    describe 'call_validation_error_handler' do
      describe 'when in default state' do
        it 'raises an error' do
          @mod.sig {params(a: String).returns(Symbol)}
          def @mod.foo(a)
            :bar
          end
          ex = assert_raises(TypeError) do
            @mod.foo(1)
          end
          assert_includes(
            ex.message,
            "Parameter 'a': Expected type String, got type Integer with value 1"
          )
        end
      end

      describe 'when overridden' do
        before do
          T::Configuration.call_validation_error_handler = lambda do |*args|
            CustomReceiver.receive(*args)
          end
        end

        after do
          T::Configuration.call_validation_error_handler = nil
        end

        it 'handles a sig error' do
          CustomReceiver.expects(:receive).once.with do |signature, opts|
            signature.is_a?(T::Private::Methods::Signature) &&
              opts.is_a?(Hash) &&
              opts[:name] == :a &&
              opts[:kind] == 'Parameter' &&
              opts[:type].name == 'String' &&
              opts[:value] == 1 &&
              opts[:location].is_a?(Thread::Backtrace::Location) &&
              opts[:message].include?("Expected type String, got type Integer with value 1")
          end
          @mod.sig {params(a: String).returns(Symbol)}
          def @mod.foo(a)
            :bar
          end
          assert_equal(:bar, @mod.foo(1))
        end
      end
    end

    describe 'scalar_types' do
      describe 'when overridden' do
        before do
          T::Configuration.scalar_types = ['foo']
        end

        after do
          T::Configuration.scalar_types = nil
        end

        it 'contains the correct values' do
          assert_equal(T::Configuration.scalar_types, Set.new(['foo']))
        end

        it 'requires string values' do
          ex = assert_raises(ArgumentError) do
            T::Configuration.scalar_types = [1, 2, 3]
          end
          assert_includes(ex.message, "Provided values must all be class name strings.")
        end
      end
    end
  end
end
