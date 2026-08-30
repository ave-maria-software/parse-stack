# DIVERGENCE — lineage and changes

Maintained fork of `parse-stack`, the Parse Server SDK for Ruby (MIT).

## Lineage

- **Original upstream**: [modernistik/parse-stack](https://github.com/modernistik/parse-stack)
  (MIT). Effectively unmaintained — last gem release 1.9.1 (2020), last commit 2023.
- **Base of this fork**: [mobilecause/parse-stack](https://github.com/mobilecause/parse-stack)
  master @ `0cfe218` (v1.11.0), chosen over other community lineages because it already carries
  the **faraday 2** port (standalone, no faraday_middleware) and removed the
  active_model_serializers requires from lib/.
- **Fixes folded in from other lineages**: remaining Ruby-3 fixes (equivalent to
  [gigtown/parse-stack](https://github.com/gigtown/parse-stack)) and the float-coercion fix from
  [elamonica/parse-stack](https://github.com/elamonica/parse-stack).

## Changes on top of the base (v2.0.0)

1. **Revert of the `:id → :object_id` operator rename** in `Operation.register` (the handler
   stayed registered under `:id`, so the renamed operator resolved to nil — and it overrode
   Ruby's core `Symbol#object_id`).
2. **Fix implicit `Proc.new`** (removed in Ruby 3.0) in `webhook_function` and `save_all`.
3. **`Minitest` namespace shim** in test_helper (the legacy `MiniTest` spelling left
   `refute_raises` unloaded under minitest ≥ 5, silently turning 4 tests into no-ops).
4. **Gemspec**: `activemodel/activesupport '>= 6.1', '< 9'`, `faraday '>= 2', '< 3'`,
   `rack '>= 2.2', '< 4'`, no `active_model_serializers` (nothing in lib/ requires it —
   only `ActiveModel::Serializers::JSON`, which ships inside activemodel),
   `required_ruby_version '>= 3.3'`. Version **2.0.0**.
5. **`:int`/`:number` property aliases map to `:float`**, not `:integer`: Parse Numbers are
   doubles, and the integer coercion truncated floats on the write path
   (modernistik/parse-stack#73, reported 2022, never answered upstream).

## Repository invariants

- **The test suite stays offline.** No VCR cassettes, recorded fixtures, or network calls
  against live Parse applications — recorded fixtures can embed credentials, and Parse
  master keys generally cannot be rotated.
- **Nobody pushes to the public mirror by hand.** The only writer is the publish workflow,
  which scans the entire publishable history (hash-based credential check + gitleaks) before
  every push. Repository rules enforce this with no human bypass.
- `.secret-hashes` contains only SHA256 digests (harmless by themselves). For local
  early feedback: `git config core.hooksPath .githooks`.

## Resyncing with the community

```bash
git remote add mobilecause https://github.com/mobilecause/parse-stack
git fetch mobilecause && git merge mobilecause/master   # or selective cherry-picks
```

Other lineages with useful work: `gigtown/parse-stack` (branch `latest-versions-2026`, active,
Ruby 4-ready — note it changes behavior of `first_or_create`, GeoPoint range handling and
`User.session` error handling; review before merging wholesale) and `hspindell/parse-stack`
(targeted fixes).

## Roadmap (v2.1 — behavior changes, each shipped and soaked separately)

1. Class registry: an explicitly declared model always wins over an auto-generated one
   (today `auto_generate_models!` can shadow a declared class depending on load order,
   and `find_class` caches the winner forever).
2. Raise on unhandled 5xx statuses (502/504/520-530 currently fall through JSON parsing and
   surface as an EMPTY result set, indistinguishable from "no records"); `Query#fetch!`
   should stop swallowing errors with a bare `puts`.
3. Sane default network timeouts (today the Net::HTTP default of ~60s applies unless callers
   pass `faraday:` options).
4. Deterministic, configurable internal retry (today: hidden retries with a randomly sampled
   backoff delay that multiplies with any caller-side retry).
5. `persisted?`/`to_param` should depend only on `@id` (a partial fetch currently makes
   `to_param` return nil, breaking URL helpers and flipping `form_for` to POST).
6. Minor: raise/warn when a `:string`-defaulted property receives a non-String; symmetric
   `:integer` coercion on read; cap or warn on `.results` without an explicit limit;
   `attr_reader :conn` on `Parse::Client`.
