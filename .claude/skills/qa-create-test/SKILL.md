---
name: qa-create-test
description: Scaffold and wire a new end-to-end test into the CodeZero QA framework at reticulum/qa (Ruby/RSpec/Capybara, GitLab-QA style). Use when asked to "add a QA test", "write a reticulum e2e/QA test", "add a spec for <flow/project/action/...>", or to extend the resource/page/spec layers. Produces a GraphQL resource factory and/or a sculptor page object plus an RSpec feature spec, correctly tagged and autoloaded.
---

# Add a test to the CodeZero QA framework

The framework lives in `reticulum/qa`. It drives a **running** deployment (nginx → sculptor
UI + sagittarius GraphQL + the nats/aquila/taurus/action runtime). Read `qa/README.md` first —
it is the authoritative contract (layers, env vars, `data-qa-selector` groups).

Three layers: **Resource** (`qa/qa/resource/`, GraphQL API factories — arrange state & assert
backend/runtime), **Page** (`qa/qa/page/`, Capybara page objects over `data-qa-selector`), and
**Specs** (`qa/specs/features/<category>/<name>_spec.rb`).

## Decision rule (which layer)

- **Arrange + assert via the API** (resource layer). It is fast and deterministic: create the
  org/namespace/project/flow/runtime you need, and read back state (runtime status, execution
  result, definitions) to assert.
- **Act via the UI** (page layer) only for the capability the spec is actually about — the thing
  a user does in sculptor. Tag such specs `:browser`.
- A pure-API spec is tagged `:api`; a spec that mixes UI actions with API setup/assertions is
  tagged `:orchestrated`. Add `:smoke` to the handful of critical-path specs.

## Step-by-step

1. **Pick the scenario + category.** Choose `<category>` (e.g. `project`, `flow`, `actions`) and
   the `product_group:` metadata (e.g. `:project`, `:flow`, `:authentication`). Create
   `qa/specs/features/<category>/` if missing.

2. **Resource (if you need to create/read backend state).** Copy `templates/resource.rb.template`
   to `qa/qa/resource/<name>.rb`. Follow `qa/qa/resource/project.rb` exactly:
   - attributes via `attr_accessor`;
   - `#api_create` returns `[graphql_string, variables_hash]`;
   - `#process_create_response(data)` populates `@id` and any read-back fields;
   - `#api_delete` returns `[graphql_string, variables_hash]` for cleanup.
   - **Find the mutation name**: it is the Sagittarius mutation class path with `Mutations::`
     dropped, `::` removed, first letter lower-cased. Confirm by reading
     `/Users/raph/Documents/Code0/sagittarius/app/graphql/mutations/**`. Examples:
     `Mutations::Namespaces::Projects::Create` → `namespacesProjectsCreate`;
     `Mutations::Organizations::Create` → `organizationsCreate`;
     `Mutations::Namespaces::Projects::Flows::TriggerExecution` → `namespacesProjectsFlowsTriggerExecution`.
     (Rule source: `base_mutation.rb` `graphql_name subclass.name.delete_prefix('Mutations::').gsub('::','')`.)
   - Get the **arguments and input/ID types** from the same mutation file (e.g. `NamespaceID!`,
     `NamespaceProjectID!`). Every mutation returns `errors { message }` — always select it; the
     base class raises on a non-empty `errors` array.

3. **Page object (if the spec performs a UI action).** Copy `templates/page.rb.template` to
   `qa/qa/page/<area>/<name>.rb`. Follow `qa/qa/page/auth/login.rb`:
   - declare `path "/..."` and `view_selectors %w[...]`;
   - expose intention-revealing methods built from `Page::Base` helpers
     (`fill_element`, `click_element`, `has_element?`, `has_element_with_text?`,
     `wait_for_element`, `wait_until`).
   - **Discover real selectors** from the sculptor source (never guess):
     `grep -rhoE 'data-qa-selector=\{?"[^"]+"' <sculptor>/src | sed -E 's/.*"([^"]+)"/\1/' | sort -u`
     Known groups are listed in `qa/README.md` (auth / dashboard / flow-builder / flow-create).

4. **Register autoloads** in `qa/qa.rb`: add `autoload :<Const>, "qa/resource/<name>"` under
   `module Resource`, and/or `autoload :<Const>, "qa/page/<area>/<name>"` under the matching
   `Page::<Area>` module (create the nested `module <Area>` if new).

5. **Spec.** Copy `templates/spec.rb.template` to `qa/specs/features/<category>/<name>_spec.rb`.
   Follow `qa/specs/features/login/login_spec.rb`:
   - `RSpec.describe "<Area>", product_group: :<group> do` with a layer tag;
   - fabricate prerequisites with `QA::Resource::X.fabricate_via_api!`;
   - do the one thing under test (UI via a page object, or API);
   - assert via UI (`have_css([data-qa-selector="..."])`) and/or API (`QA::Resource` read / client query);
   - clean up in an `after` block with `remove_via_api!` (guard with `&.`).

6. **Verify.**
   ```sh
   cd reticulum/qa
   ruby -c qa/qa/resource/<name>.rb && ruby -c qa/qa/page/<area>/<name>.rb && ruby -c qa/specs/features/<category>/<name>_spec.rb
   bundle exec rspec qa/specs --dry-run        # new example(s) must appear in the list
   ```
   A real run needs a live deployment: `QA_SEED=true QA_DEPLOYMENT=docker-compose QA_BASE_URL=... bin/qa qa/specs/features/<category>/<name>_spec.rb`.

## Rules

- Never invent GraphQL fields, mutation names, or `data-qa-selector` values — read them from
  `sagittarius/app/graphql` and the sculptor source.
- Keep browser specs minimal and resilient (selectors only, generous waits via `wait_for_element`).
- Always select `errors {
                errorCode
                details {
                  ...on ActiveModelError { attribute type }
                  ...on MessageError { message }
                }
              }` in every mutation and always add cleanup.
