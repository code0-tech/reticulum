# frozen_string_literal: true

require "securerandom"
require "json"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/blank"

# Top-level namespace for the CodeZero QA framework.
#
# Loading this file wires up the whole framework (runtime, support, resources, pages).
# Specs only need `require "qa"` (done for them by spec_helper).
module QA
  # Runtime: configuration, API/browser clients, logging, seeding.
  module Runtime
    autoload :Env,        "qa/runtime/env"
    autoload :Logger,     "qa/runtime/logger"
    autoload :ApiClient,  "qa/runtime/api_client"
    autoload :Browser,    "qa/runtime/browser"
    autoload :Seed,       "qa/runtime/seed"
  end

  # Support: small cross-cutting helpers.
  module Support
    autoload :Waiter, "qa/support/waiter"
    autoload :Retrier, "qa/support/retrier"
  end

  # Resource: GraphQL API factories (orgs, namespaces, projects, flows, runtimes, actions).
  module Resource
    autoload :Base,         "qa/resource/base"
    autoload :Project,      "qa/resource/project"
    # --- added by Fork 1, following qa/resource/project.rb ---
    autoload :User,         "qa/resource/user"
    autoload :Organization, "qa/resource/organization"
    autoload :Namespace,    "qa/resource/namespace"
    autoload :Runtime,      "qa/resource/runtime"
    autoload :Flow,         "qa/resource/flow"
    autoload :Action,       "qa/resource/action"
  end

  # Page: Capybara page objects over the sculptor UI.
  module Page
    autoload :Base, "qa/page/base"

    module Auth
      autoload :Login, "qa/page/auth/login"
    end

    # --- added by Fork 1, following qa/page/auth/login.rb ---
    module Dashboard
      autoload :Overview, "qa/page/dashboard/overview"
    end

    module Project
      autoload :Create, "qa/page/project/create"
      autoload :Show,   "qa/page/project/show"
    end

    module Flow
      autoload :Builder, "qa/page/flow/builder"
      autoload :Create,  "qa/page/flow/create"
    end
  end
end
