# frozen_string_literal: true

module Identity
  module Permissions
    MEDIATOR = {
      "escrows" => {
        "view_own" => false,
        "view_all" => false,
        "view_assigned_disputes" => true,
        "release" => false,
        "force_close" => false
      },
      "disputes" => {
        "view_own" => false,
        "view_all" => false,
        "view_assigned" => true,
        "create" => false,
        "assign" => false,
        "reassign" => false,
        "resolve" => true,
        "escalate" => true,
        "send_message" => true,
        "request_evidence" => true,
        "view_evidence" => true,
        "submit_evidence" => false,
        "set_availability" => true
      },
      "users" => {
        "view_own" => true,
        "view_all" => false
      },
      "mediator" => {
        "view_dashboard" => true,
        "update_profile" => true,
        "set_availability" => true,
        "view_workload" => true
      }
    }.freeze

    module_function

    def for(user)
      case user.role.to_s
      when "mediator"
        MEDIATOR.deep_dup
      when "admin", "superadmin"
        admin_permissions(user)
      else
        {}
      end
    end

    def admin_permissions(user)
      platform = if user.role_superadmin?
                   true
                 else
                   %w[view_audit_log manage_settings manage_fees manage_banks]
                 end

      {
        "escrows" => %w[view_all export view_events create resolve_disputes],
        "disputes" => %w[view_all assign reassign resolve escalate send_message request_evidence view_evidence],
        "mediators" => %w[manage],
        "analytics" => %w[view_platform view_financial],
        "platform" => platform,
        "users" => %w[view_all suspend edit_all],
        "payouts" => %w[view_all manual_trigger reverse],
        "transactions" => %w[view_all export],
        "kyc" => %w[override_tier]
      }
    end
  end
end
