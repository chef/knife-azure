#
# Author:: Nimisha Sharad (nimisha.sharad@clogeny.com)
# Copyright:: Copyright 2010-2019, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# XPLAT stores the access token and other information in windows credential manager.
# Using FFI to call CredRead function
require "chef"
require "mixlib/shellout"
require "ffi"
require "chef/win32/api"

module Azure::ARM

  module ReadCred

    extend Chef::ReservedNames::Win32::API
    extend FFI::Library

    ffi_lib "Advapi32"

    CRED_TYPE_GENERIC = 1
    CRED_TYPE_DOMAIN_PASSWORD = 2
    CRED_TYPE_DOMAIN_CERTIFICATE = 3
    CRED_TYPE_DOMAIN_VISIBLE_PASSWORD = 4

    # Ref: https://msdn.microsoft.com/en-us/library/windows/desktop/ms724284(v=vs.85).aspx
    class FILETIME < FFI::Struct
      layout :dwLowDateTime, :DWORD,
        :dwHighDateTime, :DWORD
    end

    # Ref: https://msdn.microsoft.com/en-us/library/windows/desktop/aa374790(v=vs.85).aspx
    class CREDENTIAL_ATTRIBUTE < FFI::Struct
      layout :Keyword, :LPTSTR,
        :Flags, :DWORD,
        :ValueSize, :DWORD,
        :Value, :LPBYTE
    end

    # Ref: https://msdn.microsoft.com/en-us/library/windows/desktop/aa374788(v=vs.85).aspx
    class CREDENTIAL_OBJECT < FFI::Struct
      layout :Flags, :DWORD,
        :Type, :DWORD,
        :TargetName, :LPTSTR,
        :Comment, :LPTSTR,
        :LastWritten, FILETIME,
        :CredentialBlobSize, :DWORD,
        :CredentialBlob, :LPBYTE,
        :Persist, :DWORD,
        :AttributeCount, :DWORD,
        :Attributes, CREDENTIAL_ATTRIBUTE,
        :TargetAlias, :LPTSTR,
        :UserName, :LPTSTR
      end

    # Ref: https://msdn.microsoft.com/en-us/library/windows/desktop/aa374804(v=vs.85).aspx
    safe_attach_function :CredReadW, %i{LPCTSTR DWORD DWORD pointer}, :BOOL
  end

  module WindowsCredentials

    include Chef::Mixin::WideString
    include ReadCred

    def token_details_from_WCM
      target = target_name

      if target && !target.empty?
        target_pointer = wstring(target)
        info_ptr = FFI::MemoryPointer.new(:pointer)
        cred = CREDENTIAL_OBJECT.new info_ptr
        cred_result = CredReadW(target_pointer, CRED_TYPE_GENERIC, 0, cred)
        translated_cred = CREDENTIAL_OBJECT.new(info_ptr.read_pointer)

        target_obj = translated_cred[:TargetName].read_wstring.split("::") if translated_cred[:TargetName].read_wstring
        cred_blob = translated_cred[:CredentialBlob].get_bytes(0, translated_cred[:CredentialBlobSize]).split("::")

        tokentype = target_obj.select { |obj| obj.include? "tokenType" }
        user = target_obj.select { |obj| obj.include? "userId" }
        clientid = target_obj.select { |obj| obj.include? "clientId" }
        expiry_time = target_obj.select { |obj| obj.include? "expiresOn" }
        access_token = cred_blob.select { |obj| obj.include? "a:" }
        refresh_token = cred_blob.select { |obj| obj.include? "r:" }

        credential = {}
        credential[:tokentype] = tokentype[0].split(":")[1]
        credential[:user] = user[0].split(":")[1]
        credential[:token] = access_token[0].split(":")[1]
        # Todo: refresh_token is not complete currently
        # target_name method needs to be modified for that
        credential[:refresh_token] = refresh_token[0].split(":")[1]
        credential[:clientid] = clientid[0].split(":")[1]
        credential[:expiry_time] = expiry_time[0].split("expiresOn:")[1].delete("\\")

        # Free memory pointed by info_ptr
        info_ptr.free
      else
        raise "TargetName Not Found"
      end
      credential
    rescue => error
      ui.error("#{error.message}")
      Chef::Log.debug("#{error.backtrace.join("\n")}")
      exit
    end

    # Todo: For getting the complete refreshToken, both credentials (ending with --0-2 and --1-2) have to be read
    def target_name
      # cmdkey command is used for accessing windows credential manager.
      # Multiple credentials get created in windows credential manager for a single Azure account in xplat-cli
      # One of them is for common tanent id, which can't be used
      # Others end with --0-x,--1-x,--2-x etc, where x represents the total no. of credentails across which the token is divided
      # The one ending with --0-x has the complete accessToken in the credentialBlob.
      # Refresh Token is split across both credentials (ending with --0-x and --1-x).
      # Xplat splits the credentials based on the number of bytes of the tokens.
      # Hence the access token is always found in the one which start with --0-
      # So selecting the credential on the basis of --0-
      xplat_creds_cmd = Mixlib::ShellOut.new('cmdkey /list | findstr AzureXplatCli | findstr \--0- | findstr -v common')
      result = xplat_creds_cmd.run_command
      target_names = []

      if result.stdout.empty?
        Chef::Log.debug("Unable to find a credential with --0- and falling back to looking for any credential.")
        xplat_creds_cmd = Mixlib::ShellOut.new("cmdkey /list | findstr AzureXplatCli | findstr -v common")
        result = xplat_creds_cmd.run_command

        if result.stdout.empty?
          raise "Azure Credentials not found. Please run xplat's 'azure login' command"
        else
          target_names = result.stdout.split("\n")
        end
      else
        target_names = result.stdout.split("\n")
      end

      # If "azure login" is run for multiple users, there will be multiple credentials
      # Picking up the latest logged in user's credentials
      latest_target = latest_credential_target target_names
      latest_target
    end

    def latest_credential_target(targets)
      case targets.size
      when 0
        raise "No Target was found for windows credentials"
      when 1
        targets.first.gsub("Target:", "").strip
      else
        latest_target = ""
        max_expiry_time = Time.new(0)

        # Using expiry_time to determine the latest credential
        targets.each do |target|
          target_obj = target.split("::")
          expiry_time_obj = target_obj.select { |obj| obj.include? "expiresOn" }
          expiry_time = expiry_time_obj[0].split("expiresOn:")[1].delete("\\")
          if Time.parse(expiry_time) > max_expiry_time
            latest_target = target
            max_expiry_time = Time.parse(expiry_time)
          end
        end

        latest_target.gsub("Target:", "").strip
      end
    end
  end
end
