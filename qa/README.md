# CodeZero QA — end-to-end test framework

End-to-end (E2E) tests for the CodeZero platform, modelled on the
[GitLab QA framework](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa).

The suite drives a **running** CodeZero deployment (the full stack that `reticulum`
packages: nginx → sculptor / sagittarius, and the nats → aquila → taurus → action
runtime). It is deliberately decoupled from the build so the exact same specs run
against a locally booted `docker-compose` stack, the `terraform/docker` stack, or a
remote environment such as staging.

## How a test is shaped

Three layers, same idea as GitLab QA:

1. **Resource layer** (`qa/resource/`) — API factories over Sagittarius GraphQL
   (`POST /graphql`). Create/read/delete orgs, namespaces, projects, flows, runtimes,
   actions. This is how a test arranges state cheaply and how it makes *backend* and
   *runtime* assertions (runtime status, execution results, module/function definitions).
2. **Page layer** (`qa/page/`) — Capybara page objects over the sculptor UI. This is the
   GitLab-style "open a page and do stuff" layer. sculptor annotates interactive elements
   with **`data-qa-selector="<name>"`** (90+ across auth / dashboard / flow-builder), so page
   objects reference those stable names — never CSS/text. Page objects use the `*_element`
   helpers in `Page::Base`, which build `[data-qa-selector="..."]` queries. The resource
   layer still arranges prerequisites and makes the backend/runtime assertions.

   Known selector groups (see `data-qa-selector` in sculptor for the authoritative list):
   - **auth**: `auth-login-{email,password,send}`, `auth-register-*`, `auth-complete-profile-*`,
     `auth-email-*`, `auth-password-*`
   - **dashboard**: `dashboard-navigation`, `dashboard-namespace-*`,
     `dashboard-organization-create-{name,send}`,
     `dashboard-namespace-project-create-{name,description,send}`, `dashboard-project-*`,
     `dashboard-flow-*`
   - **flow builder**: `flow-builder-{canvas,node,trigger,tabs,parameter,setting}`,
     `flow-builder-control-panel-{add,delete,execute}`,
     `flow-builder-manual-execution-{form,input,trigger}`
   - **flow create**: `flow-create-{form,name,send,list,template-mode,...}`
3. **Specs** (`qa/specs/features/`) — RSpec feature specs that compose the two layers.

A typical spec: fabricate prerequisites via the API, do the one thing under test (via UI
or API), then assert via GraphQL and/or the runtime.

## Running

```sh
cd qa
bundle install
bin/qa                      # run the whole suite against QA_BASE_URL
bin/qa --tag smoke          # only smoke-tagged specs
bin/qa qa/specs/features/login/login_spec.rb   # one file
```

### Environment variables (all consumed by `QA::Runtime::Env`)

| Variable | Default | Meaning |
|---|---|---|
| `QA_BASE_URL` | `http://localhost` | Base URL of the deployment under test (nginx front door). UI at `/`, GraphQL at `/graphql`. |
| `QA_GRAPHQL_PATH` | `/graphql` | GraphQL endpoint path. |
| `QA_USER_EMAIL` | `root@code0.tech` | Login email for the QA user (the stack's native `INITIAL_ROOT_MAIL`). |
| `QA_USER_PASSWORD` | `root` | Login password (`INITIAL_ROOT_PASSWORD`). |
| `QA_USER_USERNAME` | `root` | Username (login accepts email **or** username). |
| `QA_RUNTIME_TOKEN` | `runtime` | Token the seeded runtime authenticates with (`INITIAL_RUNTIME_TOKEN`). |
| `QA_SEED` | `false` | When `true`, seed the QA user + runtime before the suite. **Not needed for docker-compose** — the stack self-seeds on boot from the `INITIAL_*` env; only for environments without native seeding. |
| `QA_DEPLOYMENT` | `external` | `docker-compose` \| `terraform` \| `external`. Selects how seeding runs. |
| `QA_COMPOSE_DIR` | `../docker-compose` | Where `docker compose` is invoked for seeding (deployment `docker-compose`). |
| `QA_BROWSER` | `chrome` | Selenium browser. |
| `QA_HEADLESS` | `true` | Headless Chrome. |
| `QA_SELENIUM_URL` | _(none)_ | Remote Selenium/WebDriver URL (e.g. a `selenium/standalone-chrome` service in CI). When unset, a local driver is used. |
| `QA_WEBDRIVER_INSECURE` | `true` | Accept self-signed certs (the docker-compose stack serves HTTPS with a self-signed cert). |
| `QA_SCREENSHOTS_DIR` | `tmp/screenshots` | Where failure screenshots/HTML are written. |
| `QA_LOG_LEVEL` | `info` | `debug` \| `info` \| `warn` \| `error`. |

## Public contract (what each layer looks like — follow these when adding code)

### `QA::Runtime::ApiClient`
```ruby
client = QA::Runtime::ApiClient.new            # reads QA_BASE_URL etc. from Env
token  = client.login!                         # userLogin mutation -> stores session token
data   = client.query(<<~GQL, variables: { id: project_id })
  query($id: ProjectID!) { ... }
GQL
```
`#query`/`#mutate` return the parsed `data` hash and raise `QA::Runtime::ApiClient::Error`
on transport errors or a non-empty GraphQL `errors` array.

### `QA::Resource::Base`
Subclass and implement the create/delete GraphQL. Factory usage:
```ruby
project = QA::Resource::Project.fabricate_via_api! do |p|
  p.name = "qa-#{SecureRandom.hex(4)}"
  p.namespace = namespace
end
project.remove_via_api!
```
A subclass implements:
- attributes via `attr_accessor`
- `#api_create` → `[graphql_string, variables_hash]`
- `#process_create_response(data)` → populate `@id` etc. from the mutation result
- `#api_delete` → `[graphql_string, variables_hash]` (optional; default no-op)
See `qa/resource/project.rb` as the reference implementation.

### `QA::Page::Base`
Subclass per page. Capybara DSL plus resilient helpers
(`fill_in_field`, `click_button_text`, `wait_until`, `has_element_text?`).
Each page declares a `path` and `#on_page?`. See `qa/page/auth/login.rb` as the reference.

### Specs
Live in `qa/specs/features/<category>/<name>_spec.rb`. Tag every spec with a
scenario area and one of `:api` / `:browser` / `:orchestrated`:
```ruby
RSpec.describe 'Tenant scale', :orchestrated, product_group: :project do
  it 'creates a project', :smoke do
    ...
  end
end
```
See `qa/specs/features/login/login_spec.rb` as the reference.

## Deployment matrix & CI

The GitLab CI `qa:*` jobs boot each deployment option, seed it (`QA_SEED=true`), then run
the suite. The same jobs accept `QA_BASE_URL` pointing at an already-running environment
(no build, no seed) — that is the "run against staging" mode. See `.gitlab/ci/qa.gitlab-ci.yml`.

## Adding a test

Use the `qa-create-test` skill (`.claude/skills/`) — it scaffolds the resource, page object
and spec from the references and wires the tags.
