# Dependency Notes

Static string-scan notes from audit. These are *not* removals; verify runtime usage, initializers, rake tasks, and dynamic loading before acting.

## JavaScript Packages (package.json)

| Package | Version | Scope | Note |
| :-- | :-- | :-- | :-- |
| `@formkit/core` | `^1.6.7` | `dependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@iconify-json/logos` | `^1.2.3` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@iconify-json/lucide` | `^1.2.68` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@iconify-json/material-symbols` | `^1.2.10` | `dependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@iconify-json/ph` | `^1.2.1` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@iconify-json/ri` | `^1.2.3` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@iconify-json/teenyicons` | `^1.2.1` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@intlify/eslint-plugin-vue-i18n` | `^3.2.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@radix-ui/react-slot` | `^1.2.4` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@size-limit/file` | `^8.2.4` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@types/canvas-confetti` | `^1.9.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@types/react` | `^19.2.8` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@types/react-dom` | `^19.2.3` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@vitest/coverage-v8` | `3.0.5` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `@vue/compiler-sfc` | `^3.5.8` | `dependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `class-variance-authority` | `^0.7.1` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `clsx` | `^2.1.1` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `core-js` | `3.38.1` | `dependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `eslint-config-airbnb-base` | `15.0.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `eslint-config-prettier` | `^9.1.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `eslint-interactive` | `^11.1.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `eslint-plugin-html` | `7.1.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `eslint-plugin-import` | `2.30.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `eslint-plugin-prettier` | `5.2.1` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `eslint-plugin-vitest-globals` | `^1.5.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `eslint-plugin-vue` | `^9.28.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `html2canvas` | `^1.4.1` | `dependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `husky` | `^7.0.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `lint-staged` | `^16.2.7` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `opus-recorder` | `^8.0.5` | `dependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `prettier` | `^3.3.3` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `react-dom` | `^19.2.3` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `size-limit` | `^8.2.4` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `tailwind-merge` | `^3.4.0` | `devDependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `video.js` | `7.18.1` | `dependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `videojs-record` | `4.5.0` | `dependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |
| `videojs-wavesurfer` | `3.8.0` | `dependencies` | Not referenced in app/assets/config string scan; verify build tooling and dynamic imports. |

## Ruby Gems (Gemfile)

| Gem | Version | Note |
| :-- | :-- | :-- |
| `active_record_query_trace` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `activerecord-import` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `administrate-field-belongs_to_search` | `>= 0.9.0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `ai-agents` | `>= 0.7.0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `annotaterb` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `attr_extras` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `aws-actionmailbox-ses` | `~> 0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `aws-sdk-s3` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `azure-storage-blob` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `barnes` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `brakeman` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `bundle-audit` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `byebug` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `climate_control` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `csv-safe` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `database_cleaner` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `devise-secure_password` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `devise-two-factor` | `>= 5.0.0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `dotenv-rails` | `>= 3.0.0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `email-provider-info` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `email_reply_trimmer` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `factory_bot_rails` | `>= 6.4.3` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `faraday_middleware-aws-sigv4` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `flag_shih_tzu` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `foreman` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `gmail_xoauth` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `google-cloud-dialogflow-v2` | `>= 0.24.0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `google-cloud-storage` | `>= 1.48.0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `google-cloud-translate-v3` | `>= 0.7.0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `groupdate` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `grpc` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `haikunator` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `hairtrigger` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `hashie` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `html2text` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `image_processing` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `iso-639` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `json_schemer` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `kaminari` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `line-bot-api` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `maxminddb` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `meta_request` | `>= 0.8.3` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `mock_redis` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `net-smtp` | `~> 0.3.4` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `omniauth-google-oauth2` | `>= 1.1.3` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `omniauth-rails_csrf_protection` | `~> 1.0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `omniauth-saml` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `opensearch-ruby` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `opentelemetry-exporter-otlp` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `opentelemetry-sdk` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `pdf-reader` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `procore-sift` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `pry-rails` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `redis-namespace` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `responders` | `>= 3.1.1` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `reverse_markdown` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `rqrcode` | `~> 3.2` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `rspec-rails` | `>= 6.1.5` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `rspec_junit_formatter` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `rubocop-factory_bot` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `rubocop-performance` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `rubocop-rails` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `rubocop-rspec` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `ruby-openai` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `ruby_llm-schema` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `scss_lint` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `seed_dump` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `shopify_api` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `shoulda-matchers` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `sidekiq_alive` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `simplecov` | `>= 0.21` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `simplecov_json_formatter` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `spring-watcher-listen` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `squasher` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `stackprof` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `telephone_number` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `test-prof` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `tidewave` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `time_diff` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `twilio-ruby` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `twitty` | `~> 0.1.5` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `tzinfo-data` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `valid_email2` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `vite_rails` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `web-console` | `>= 4.2.1` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `web-push` | `>= 3.0.1` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `webmock` | `unspecified` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
| `wisper` | `2.0.0` | Not referenced in app/lib/config string scan; verify initializers, tasks, and runtime hooks. |
