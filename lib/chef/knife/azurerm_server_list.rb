require File.expand_path('../azurerm_base', __FILE__)

class Chef
  class Knife
    class AzurermServerList < Knife

      include Knife::AzurermBase

      banner "knife azurerm server list (options)"

      def run
        $stdout.sync = true
        validate_arm_keys!
        service.list_servers
      end
    end
  end
end