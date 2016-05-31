#
# Author:: Nimisha Sharad (nimisha.sharad@clogeny.com)
# Copyright:: Copyright (c) 2015-2016 Opscode, Inc.
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
require 'chef'
require 'mixlib/shellout'
require 'ffi'

module Azure::ARM

    module ReadCred

      extend FFI::Library

      ffi_lib 'Advapi32'

      CRED_TYPE_GENERIC = 1
      CRED_TYPE_DOMAIN_PASSWORD = 2
      CRED_TYPE_DOMAIN_CERTIFICATE = 3
      CRED_TYPE_DOMAIN_VISIBLE_PASSWORD = 4

      # Ref: https://msdn.microsoft.com/en-us/library/windows/desktop/ms724284(v=vs.85).aspx
      class FILETIME < FFI::Struct
        layout :dwLowDateTime, :uint32,
               :dwHighDateTime, :uint32
      end

      # Ref: https://msdn.microsoft.com/en-us/library/windows/desktop/aa374790(v=vs.85).aspx
      class CREDENTIAL_ATTRIBUTE < FFI::Struct
        layout :Keyword, :pointer,
               :Flags, :uint32,
               :ValueSize, :uint32,
               :Value, :pointer
      end

      # Ref: https://msdn.microsoft.com/en-us/library/windows/desktop/aa374788(v=vs.85).aspx
      class CREDENTIAL_OBJECT < FFI::Struct
          layout :Flags, :uint32,
                 :Type, :uint32,
                 :TargetName, :pointer,
                 :Comment, :pointer,
                 :LastWritten, FILETIME,
                 :CredentialBlobSize, :uint32,
                 :CredentialBlob, :pointer,
                 :Persist, :uint32,
                 :AttributeCount, :uint32,
                 :Attributes, CREDENTIAL_ATTRIBUTE,
                 :TargetAlias, :pointer,
                 :UserName, :pointer
        end

      # Ref: https://msdn.microsoft.com/en-us/library/windows/desktop/aa374804(v=vs.85).aspx
      attach_function :CredReadW, [:pointer, :uint32, :uint32, :pointer], :bool
    end


    module WindowsCredentials

      include Chef::Mixin::WideString
      include ReadCred

      def token_details_for_windows
        target = target_name

        if target
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
          credential[:tokentype] = tokentype[0].split(":")[1] if tokentype
          credential[:user] = user[0].split(":")[1] if user
          credential[:token] = access_token[0].split(":")[1] if access_token
          credential[:refresh_token] = refresh_token[0].split(":")[1] if refresh_token
          credential[:clientid] = clientid[0].split(":")[1] if clientid
          credential[:expiry_time] = expiry_time[0].split("expiresOn:")[1].gsub("\\","") if expiry_time
        else
          raise "TargetName Not Found"
        end
        credential
      end

      def target_name
        # cmdkey command is used for accessing windows credential manager
        xplat_creds_cmd = Mixlib::ShellOut.new("cmdkey /list | grep AzureXplatCli")
        result = xplat_creds_cmd.run_command

        target_name = ""
        if result.stdout.empty?
          raise "Azure Credentials not found. Please run xplat's 'azure login' command"
        else
          result.stdout.split("\n").each do |target|
            # Three credentials get created in windows credential manager for xplat-cli
            # One of them is for common tanent id, which can't be used
            # Two of them end with --0-2 and --1-2. The one ending with --1-2 doesn't have
            # accessToken and refreshToken in the credentialBlob.
            # Selecting the one ending with --0-2
            if !target.include?("common::") && target.include?("--0-2")
              target_name = target.gsub("Target:","").strip
              break
            end
          end
        end

        target_name
      end
    end
end