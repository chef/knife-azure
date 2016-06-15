require File.expand_path('../azurerm_base', __FILE__)

class Chef
  class Knife
    class AzurermServerList < Knife

      include Knife::AzurermBase

      banner "knife azurerm server list (options)"

      def run
        $stdout.sync = true
        validate_arm_keys!
        begin
          service.list_servers(locate_config_value(:azure_resource_group_name))
        rescue => error
          service.common_arm_rescue_block(error)
        end
      end
    end
  end
end