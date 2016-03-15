require File.expand_path('../azurerm_base', __FILE__)

class Chef
  class Knife
    class AzurermServerList < Knife

      include Knife::AzurermBase

      banner "knife azurerm server list (options)"

      def run
        $stdout.sync = true
        validate_arm_keys!
        if locate_config_value(:azure_resource_group_name).nil?
          service.list_servers
        else
          service.list_servers(locate_config_value(:azure_resource_group_name))
        end
      end
    end
  end
end