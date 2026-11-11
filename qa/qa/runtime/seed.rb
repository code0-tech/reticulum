# frozen_string_literal: true

require "open3"
require "shellwords"

module QA
  module Runtime
    # Seeds a local deployment with the QA user and a runtime, so the suite has a
    # known identity to log in as and a runtime to execute flows on.
    #
    # NOTE: the docker-compose/terraform stacks already self-seed the root user +
    # runtime on first boot from INITIAL_ROOT_MAIL/PASSWORD/INITIAL_RUNTIME_TOKEN
    # (sagittarius db/fixtures/production), and the suite's default credentials match.
    # So QA_SEED is normally left false; this module is a fallback for environments
    # that lack native seeding.
    #
    # Only runs when QA_SEED=true AND QA_DEPLOYMENT is a local option
    # (docker-compose / terraform). A remote environment (external/staging) is never
    # seeded — it must be pre-provisioned with a QA user supplied via env.
    #
    # Seeding runs a Rails snippet inside the sagittarius container (`rails runner`),
    # the same mechanism CI already uses to create the boot-test runtime.
    #
    # NOTE: the Rails snippet below is the one deployment-coupled part of the suite.
    # Validate it against the live schema when first wiring CI (Fork 2 owns this).
    module Seed
      module_function

      def perform!
        unless Env.seed?
          Logger.info("QA_SEED is false; skipping seeding (assuming #{Env.user_email} already exists)")
          return
        end

        case Env.deployment
        when "docker-compose", "terraform"
          run_rails_runner(rails_script)
        else
          Logger.warn("QA_SEED=true but QA_DEPLOYMENT=#{Env.deployment}; refusing to seed a remote env")
        end
      end

      # The idempotent Rails snippet. Creates a confirmed QA user with a personal
      # namespace and a runtime whose token matches QA_RUNTIME_TOKEN.
      def rails_script
        <<~RUBY
          user = User.find_or_initialize_by(email: #{Env.user_email.inspect})
          user.username ||= #{Env.user_username.inspect}
          user.firstname ||= "QA"
          user.lastname ||= "Admin"
          user.password = #{Env.user_password.inspect}
          user.admin = true if user.respond_to?(:admin=)
          user.confirmed_at ||= Time.current if user.respond_to?(:confirmed_at)
          user.save!
          user.ensure_namespace if user.respond_to?(:ensure_namespace)
          unless Runtime.exists?(token: #{Env.runtime_token.inspect})
            Runtime.create!(name: "QA Runtime", token: #{Env.runtime_token.inspect})
          end
          puts "QA seed complete: user=\#{user.email} runtime_token=#{Env.runtime_token}"
        RUBY
      end

      def run_rails_runner(script)
        cmd = [
          "docker", "compose", "exec", "-T", "sagittarius-grpc",
          "bin/rails", "runner", script
        ]
        Logger.info("Seeding #{Env.deployment} deployment via rails runner")
        out, status = Open3.capture2e(*cmd, chdir: Env.compose_dir)
        Logger.debug(out)
        raise "Seeding failed (exit #{status.exitstatus}):\n#{out}" unless status.success?

        Logger.info("Seeding complete")
      end
    end
  end
end
