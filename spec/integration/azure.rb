
class AzureKnifeServerCommands
    attr_accessor :cmd_list_image                    # "knife azure image list"                      # Knife command for image list
    attr_accessor :cmd_create_server                 # "knife azure server create"                   # Knife command for creating a server
    attr_accessor :cmd_delete_server                 # "knife azure server delete"                   # Knife command for deleting a server
    attr_accessor :cmd_describe_server               # "knife azure server describe"                 # Knife command for describing a server
    attr_accessor :cmd_list_server                   # "knife azure server list"                     # Knife command for listing servers
end

class AzureKnifeServerCreateParameters
    attr_accessor :azure_server_url                  # "-H"                                          # Your Azure host name
    attr_accessor :azure_server_url_l                # "--azure-server-url"                           # Your Azure host name
    attr_accessor :azure_mgmt_cert                   # "--azure-mgmt-cert"                           # Your Azure PEM file name
    attr_accessor :azure_subcription_id              # "--azure-subscription-id"                     # Your Azure subscription ID
    attr_accessor :bootstrap_protocol                # "--bootstrap-protocol"                        # Protocol to bootstrap windows servers. options: winrm/ssh
    attr_accessor :bootstrap_version                 # "--bootstrap-version"                         # The version of Chef to install
    attr_accessor :trust_file                        # "-f"                                          # The Certificate Authority (CA) trust file used for SSL transport
    attr_accessor :trust_file_l                      # "--ca-trust-file"                             # The Certificate Authority (CA) trust file used for SSL transport
    attr_accessor :node_name                         # "-N"                                          # The Chef node name for your new node
    attr_accessor :node_name_l                       # "--node-name"                                 # The Chef node name for your new node
    attr_accessor :server_url                        # "--server-url"                                # Chef Server URL
    attr_accessor :api_client_key                    # "-k"                                          # API Client Key
    attr_accessor :api_client_key_l                  # "--key"                                       # API Client Key
    attr_accessor :colored_optput                    # "--[no-]color"                                # Use colored output, defaults to enabled
    attr_accessor :config_file                       # "-c"                                          # The configuration file to use
    attr_accessor :config_file_l                     # "--config"                                    # The configuration file to use
    attr_accessor :defaults                          # "--defaults"                                  # Accept default values for all questions
    attr_accessor :disable_editing                   # "--disable-editing"                           # Do not open EDITOR, just accept the data as is
    attr_accessor :distro                            # "-d"                                          # Bootstrap a distro using a template; default is 'chef-full'
    attr_accessor :distro_l                          # "--distro"                                    # Bootstrap a distro using a template; default is 'chef-full'
    attr_accessor :editor                            # "-e"                                          # Set the editor to use for interactive commands
    attr_accessor :editor_l                          # "--editor"                                    # Set the editor to use for interactive commands
    attr_accessor :environment                       # "-E"                                          # Set the Chef environment
    attr_accessor :environment_l                     # "--environment"                               # Set the Chef environment
    attr_accessor :format                            # "-F"                                          # Which format to use for output
    attr_accessor :format_l                          # "--format"                                    # Which format to use for output
    attr_accessor :host_key                          # "--[no-]host-key-verify"                      # Verify host key, enabled by default.
    attr_accessor :host_name_l                       # "--host-name"                                 # specifies the host name for the virtual machine
    attr_accessor :hosted_service_desc               # "-D"                                          # Description for the hosted service
    attr_accessor :hosted_service_desc_l             # "--hosted_service_description"                # Description for the hosted service
    attr_accessor :hosted_service_name               # "-s"                                          # specifies the name for the hosted service
    attr_accessor :hosted_service_name_l             # "--hosted-service-name"                       # specifies the name for the hosted service
    attr_accessor :identity_file                     # "--identity-file"                             # The SSH identity file used for authentication
    attr_accessor :keytab_file                       # "-i"                                          # The Kerberos keytab file used for authentication
    attr_accessor :keytab_file_l                     # "--keytab-file"                               # The Kerberos keytab file used for authentication
    attr_accessor :kerberos_realm                    # "--kerberos-realm"                            # The Kerberos realm used for authentication
    attr_accessor :kerberos_service                  # "-S"                                          # The Kerberos service used for authentication
    attr_accessor :kerberos_service_l                # "--kerberos-service"                          # The Kerberos service used for authentication
    attr_accessor :user                              # "--user"                                      # API Client Username
    attr_accessor :os_disk_name                      # "-o"                                          # unique name for specifying os disk (optional)
    attr_accessor :os_disk_name_l                    # "--os-disk-name"                              # unique name for specifying os disk (optional)
    attr_accessor :pre_release                       # "--prerelease"                                # Install the pre-release chef gems
    attr_accessor :print_after                       # "--print-after"                               # Show the data after a destructive operation
    attr_accessor :role_name_l                       # "--role-name"                                 # specifies the name for the virtual machine
    attr_accessor :role_size                         # "-z"                                          # size of virtual machine (ExtraSmall, Small, Medium, Large, ExtraLarge)
    attr_accessor :role_size_l                       # "--role-size"                                 # size of virtual machine (ExtraSmall, Small, Medium, Large, ExtraLarge)
    attr_accessor :run_list                          # "-r"                                          # Comma separated list of roles/recipes to apply
    attr_accessor :run_list_l                        # "--run-list"                                  # Comma separated list of roles/recipes to apply
    attr_accessor :service_location                  # "-m"                                          # specify the Geographic location for the virtual machine and services
    attr_accessor :service_location_l                # "--service-location"                          # specify the Geographic location for the virtual machine and services
    attr_accessor :source_image                      # "-I"                                          # disk image name to use to create virtual machine
    attr_accessor :source_image_l                    # "--source-image"                              # disk image name to use to create virtual machine
    attr_accessor :ssh_password                      # "--ssh-password"                              # The ssh password
    attr_accessor :ssh_username                      # "--ssh-user"                                  # The ssh username
    attr_accessor :storage_account                   # "-a"                                          # specifies the name for the hosted service
    attr_accessor :storage_account_l                 # "--storage-account"                           # specifies the name for the hosted service
    attr_accessor :tcp_endpoints                     # "--tcp-endpoints"                             # Comma separated list of TCP local and public ports to open i.e. '80:80,433:5000'
    attr_accessor :template_file                     # "--template-file"                             # Full path to location of template to use
    attr_accessor :udp_endpoints                     # "-u"                                          # Comma separated list of UDP local and public ports to open i.e. '80:80,433:5000'
    attr_accessor :udp_endpoints_l                   # "--udp-endpoints"                             # Comma separated list of UDP local and public ports to open i.e. '80:80,433:5000'
    attr_accessor :verbose                           # "-V"                                          # More verbose output. Use twice for max verbosity
    attr_accessor :verbose_l                         # "--verbose"                                   # More verbose output. Use twice for max verbosity
    attr_accessor :verify_ssl_cert                   # "--verify-ssl-cert"                           # Verify SSL Certificates for communication over HTTPS
    attr_accessor :version_chef                      # "-v"                                          # Show chef version
    attr_accessor :version_chef_l                    # "--version"                                   # Show chef version
    attr_accessor :winrm_password                    # "-P"                                          # The WinRM password
    attr_accessor :winrm_password_l                  # "--winrm-password"                            # The WinRM password
    attr_accessor :winrm_port                        # "-p"                                          # The WinRM port, by default this is 5985
    attr_accessor :winrm_port_l                      # "--winrm-port"                                # The WinRM port, by default this is 5985
    attr_accessor :winrm_transport                   # "-t"                                          # The WinRM transport type.  valid choices are [ssl, plaintext]
    attr_accessor :winrm_transport_l                 # "--winrm-transport"                           # The WinRM transport type.  valid choices are [ssl, plaintext]
    attr_accessor :winrm_user                        # "-x"                                          # The WinRM username
    attr_accessor :winrm_user_l                      # "--winrm-user"                                # The WinRM username
    attr_accessor :say_yes_to_all_prompts            # "-y"                                          # Say yes to all prompts for confirmation
    attr_accessor :say_yes_to_all_prompts_l          # "--yes"                                       # Say yes to all prompts for confirmation
    attr_accessor :help                              # "-h"                                          # Show help
    attr_accessor :help_l                            # "--help"                                      # Show help


    def user_ssh_dir
      require 'tmpdir'
      @_user_ssh_dir ||= Dir.mktmpdir
    end

    def parse_settings
      require 'nokogiri'
      require 'base64'
      require 'openssl'
      require 'uri'

      doc = Nokogiri::XML(File.open(File.expand_path(File.dirname(__FILE__) + "/properties/publishSettings.xml")))
      profile = doc.at_css("PublishProfile")
      @cert_data = OpenSSL::PKCS12.new(Base64.decode64(profile.attribute("ManagementCertificate").value))
      @host_name = URI(profile.attribute("Url").value).host
      @subscription_id =  doc.at_css("Subscription").attribute("Id").value
      return @cert_data, @host_name, @subscription_id
    end

    def user_ssh_pem_path
      "#{user_ssh_dir}/" + "managementCertificate" + ".pem"
    end

    def create_user_ssh_key_path(cert_data, filename=user_ssh_pem_path, invalidcontent=false)
      File.open(filename, 'wb') do |f|
        f.write(cert_data.certificate.to_pem)
        f.write(invalidcontent) if invalidcontent
        f.write(cert_data.key.to_pem)
      end
      puts "Creating user azure ssh key file at: "+"#{user_ssh_pem_path}"
      return user_ssh_pem_path
    end

    #FIXME This file should be fetch from a properties/ config file but for now we are placing the file content here
    def get_template_file_name
        return "template.erb"
    end

    # Method used to generate template file for azure windows bootstraps
    # This method fetches the file template file from
    # https://raw.github.com/opscode/knife-windows/master/lib/chef/knife/bootstrap/windows-chef-client-msi.erb

    def template_file_path

      # For windows machine do the follwing settings to set the ssl cert
      # download => http://curl.haxx.se/ca/cacert.pem
      # put the downloaded file to desired location, e.g. C:\cacert.pem
      # run command prompt and run => set SSL_CERT_FILE=C:\cacert.pem

      require 'open-uri'
      template_file_path = "#{user_ssh_dir}/" + get_template_file_name
      template_file_data = open("https://raw.github.com/opscode/knife-windows/master/lib/chef/knife/bootstrap/windows-chef-client-msi.erb")
      File.open("#{template_file_path}", 'w') {|f| f.write(template_file_data.read)}
      puts "Creating user azure template file at: " + "#{user_ssh_dir}/template.erb"
      return template_file_path
    end
end

class AzureKnifeServerDeleteParameters
    attr_accessor :azure_server_url                  # "-H"                                          # Your Azure host name
    attr_accessor :azure_server_url_l                # "--azure_host_name"                           # Your Azure host name
    attr_accessor :azure_mgmt_cert                   # "-p"                                          # Your Azure PEM file name
    attr_accessor :azure_mgmt_cert_l                 # "--azure-mgmt-cert"                           # Your Azure PEM file name
    attr_accessor :azure_subcription_id              # "-S"                                          # Your Azure subscription ID
    attr_accessor :azure_subcription_id_l            # "--azure-subscription-id"                     # Your Azure subscription ID
    attr_accessor :node_name                         # "-N"                                          # The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option.
    attr_accessor :node_name_l                       # "--node-name"                                 # The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option.
    attr_accessor :server_url                        # "-s"                                          # Chef Server URL
    attr_accessor :server_url_l                      # "--server-url"                                # Chef Server URL
    attr_accessor :api_client_key                    # "-k"                                          # API Client Key
    attr_accessor :api_client_key_l                  # "--key"                                       # API Client Key
    attr_accessor :colored_optput                    # "--[no-]color"                                # Use colored output, defaults to enabled
    attr_accessor :config_file                       # "-c"                                          # The configuration file to use
    attr_accessor :config_file_l                     # "--config"                                    # The configuration file to use
    attr_accessor :defaults                          # "--defaults"                                  # Accept default values for all questions
    attr_accessor :disable_editing                   # "-d"                                          # Do not open EDITOR, just accept the data as is
    attr_accessor :disable_editing_l                 # "--disable-editing"                           # Do not open EDITOR, just accept the data as is
    attr_accessor :editor                            # "-e"                                          # Set the editor to use for interactive commands
    attr_accessor :editor_l                          # "--editor"                                    # Set the editor to use for interactive commands
    attr_accessor :environment                       # "-E"                                          # Set the Chef environment
    attr_accessor :environment_l                     # "--environment"                               # Set the Chef environment
    attr_accessor :format                            # "-F"                                          # Which format to use for output
    attr_accessor :format_l                          # "--format"                                    # Which format to use for output
    attr_accessor :user                              # "-u"                                          # API Client Username
    attr_accessor :user_l                            # "--user"                                      # API Client Username
    attr_accessor :print_after                       # "--print-after"                               # Show the data after a destructive operation
    attr_accessor :purge                             # "-P"                                          # Destroy corresponding node and client on the Chef Server, in addition to destroying the azure node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option).
    attr_accessor :purge_l                           # "--purge"                                     # Destroy corresponding node and client on the Chef Server, in addition to destroying the azure node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option).
    attr_accessor :purge_os_disk                     # "--purge-os-disk"                             # Destroy corresponding OS Disk
    attr_accessor :verbose                           # "-V"                                          # More verbose output. Use twice for max verbosity
    attr_accessor :verbose_l                         # "--verbose"                                   # More verbose output. Use twice for max verbosity
    attr_accessor :verify_ssl_cert                   # "--verify-ssl-cert"                           # Verify SSL Certificates for communication over HTTPS
    attr_accessor :version_chef                      # "-v"                                          # Show chef version
    attr_accessor :version_chef_l                    # "--version"                                   # Show chef version
    attr_accessor :say_yes_to_all_prompts            # "-y"                                          # Say yes to all prompts for confirmation
    attr_accessor :say_yes_to_all_prompts_l          # "--yes"                                       # Say yes to all prompts for confirmation
    attr_accessor :help                              # "-h"                                          # Show help
    attr_accessor :help_l                            # "--help"                                      # Show help
end

class AzureKnifeServerListParameters
    attr_accessor :azure_server_url                 # "-H"                                          # Your Azure host name
    attr_accessor :azure_server_url_l               # "--azure-server-url"                           # Your Azure host name
    attr_accessor :azure_mgmt_cert                  # "-p"                                          # Your Azure PEM file name
    attr_accessor :azure_mgmt_cert_l                # "--azure-mgmt-cert"                           # Your Azure PEM file name
    attr_accessor :azure_subcription_id             # "-S"                                          # Your Azure subscription ID
    attr_accessor :azure_subcription_id_l           # "--azure-subscription-id"                     # Your Azure subscription ID
    attr_accessor :server_url                       # "-s"                                          # Chef Server URL
    attr_accessor :server_url_l                     # "--server-url"                                # Chef Server URL
    attr_accessor :api_client_key                   # "-k"                                          # API Client Key
    attr_accessor :api_client_key_l                 # "--key"                                       # API Client Key
    attr_accessor :colored_optput                   # "--[no-]color"                                # Use colored output, defaults to enabled
    attr_accessor :config_file                      # "-c"                                          # The configuration file to use
    attr_accessor :config_file_l                    # "--config"                                    # The configuration file to use
    attr_accessor :defaults                         # "--defaults"                                  # Accept default values for all questions
    attr_accessor :disable_editing                  # "--disable-editing"                           # Do not open EDITOR, just accept the data as is
    attr_accessor :editor                           # "-e"                                          # Set the editor to use for interactive commands
    attr_accessor :editor_l                         # "--editor"                                    # Set the editor to use for interactive commands
    attr_accessor :environment                      # "-E"                                          # Set the Chef environment
    attr_accessor :environment_l                    # "--environment"                               # Set the Chef environment
    attr_accessor :format                           # "-F"                                          # Which format to use for output
    attr_accessor :format_l                         # "--format"                                    # Which format to use for output
    attr_accessor :user                             # "-u"                                          # API Client Username
    attr_accessor :user_l                           # "--user"                                      # API Client Username
    attr_accessor :print_after                      # "--print-after"                               # Show the data after a destructive operation
    attr_accessor :tags                             # "-t"                                          # List of tags to output
    attr_accessor :tags_l                           # "--tags"                                      # List of tags to output
    attr_accessor :verbose                          # "-V"                                          # More verbose output. Use twice for max verbosity
    attr_accessor :verbose_l                        # "--verbose"                                   # More verbose output. Use twice for max verbosity
    attr_accessor :version_chef                     # "-v"                                          # Show chef version
    attr_accessor :version_chef_l                   # "--version"                                   # Show chef version
    attr_accessor :say_yes_to_all_prompts           # "-y"                                          # Say yes to all prompts for confirmation
    attr_accessor :say_yes_to_all_prompts_l         # "--yes"                                       # Say yes to all prompts for confirmation
    attr_accessor :help                             # "-h"                                          # Show help
    attr_accessor :help_l                           # "--help"                                      # Show help
end
