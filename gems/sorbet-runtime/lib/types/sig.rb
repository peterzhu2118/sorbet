# frozen_string_literal: true
# typed: strict

# Used as a mixin to any class so that you can call `sig`.
# Docs at https://sorbet.org/docs/sigs
module T::Sig
  module WithoutRuntime
    # At runtime, does nothing, but statically it is treated exactly the same
    # as T::Sig#sig. Only use it in cases where you can't use T::Sig#sig.
    def self.sig(&blk); end # rubocop:disable PrisonGuard/BanBuiltinMethodOverride

    # At runtime, does nothing, but statically it is treated exactly the same
    # as T::Sig#sig. Only use it in cases where you can't use T::Sig#sig.
    T::Sig::WithoutRuntime.sig {params(blk: T.proc.bind(T::Private::Methods::DeclBuilder).void).void}
    def self.sig(&blk); end # rubocop:disable PrisonGuard/BanBuiltinMethodOverride, Lint/DuplicateMethods
  end

  # Declares a method with type signatures and/or
  # abstract/override/... helpers. See the documentation URL on
  # {T::Helpers}
  T::Sig::WithoutRuntime.sig {params(blk: T.proc.bind(T::Private::Methods::DeclBuilder).void).void}
  def sig(&blk) # rubocop:disable PrisonGuard/BanBuiltinMethodOverride
    T::Private::Methods.declare_sig(self, &blk) if T::Configuration.enable_runtime_typecheck?
  end
end
