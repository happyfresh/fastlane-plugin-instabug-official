require 'fileutils'
require 'fastlane/action'
require_relative '../helper/instabug_official_helper'

module Fastlane
  module Actions
    class InstabugOfficialAction < Action
      def self.run(params)
        UI.verbose 'Running Instabug Action'
        api_token = params[:api_token]

        endpoint = 'https://api.instabug.com/api/sdk/v3/symbols_files'
        command = "curl #{endpoint} --write-out %{http_code} --silent --output /dev/null -F os=\"ios\" -F application_token=\"#{api_token}\" -F symbols_file="

        dsym_paths = (params[:dsym_array_paths] || []).uniq
        UI.verbose 'dsym_paths: ' + dsym_paths.inspect

        if dsym_paths.empty?
          directory_name = fastlane_dsyms_filename
          if directory_name.empty?
            UI.error "Fastlane dSYMs file is not found! make sure you're using Fastlane action [download_dsyms] to download your dSYMs from App Store Connect"
            return
          end
        else
          directory_name = generate_directory_name
          UI.verbose 'Directory name: ' + directory_name
          copy_dsym_paths_into_directory(dsym_paths, directory_name)
        end

        command = build_single_file_command(command, directory_name)

        puts command

        result = Actions.sh(command)
        if result == '200'
          UI.success 'dSYM is successfully uploaded to Instabug 🤖'
          UI.verbose 'Removing The directory'
          remove_directory(directory_name)
        else
          UI.error "Something went wrong during Instabug dSYM upload. Status code is #{result}"
        end
      end

      def self.description
        'upload dsyms to fastlane'
      end

      def self.authors
        ['Instabug Inc.']
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        'upload dsyms to fastlane'
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: 'FL_INSTABUG_API_TOKEN', # The name of the environment variable
                                       description: 'API Token for Instabug', # a short description of this parameter
                                       verify_block: proc do |value|
                                                       unless value && !value.empty?
                                                         UI.user_error!("No API token for InstabugAction given, pass using `api_token: 'token'`")
                                                       end
                                                     end),
          FastlaneCore::ConfigItem.new(key: :dsym_array_paths,
                                       type: Array,
                                       optional: true,
                                       description: 'Array of paths to *.dSYM files')
        ]
      end

      def self.is_supported?(platform)
        platform == :ios
        true
      end

      def self.generate_directory_name
        'Instabug_dsym_files_fastlane'
      end

      def self.remove_directory(directory_path)
        FileUtils.rm_rf directory_path
      end

      def self.copy_dsym_paths_into_directory(dsym_paths, directory_path)
        FileUtils.rm 'Instabug_dsym_files_fastlane.zip', force: true
        FileUtils.mkdir_p directory_path
        dsym_paths.each do |path|
          FileUtils.copy_entry(path, "#{directory_path}/#{File.basename(path)}") if File.exist?(path)
        end
      end

      def self.build_single_file_command(command, dsym_path)
        file_path = if dsym_path.end_with?('.zip')
                      dsym_path.shellescape
                    else
                      ZipAction.run(path: dsym_path).shellescape
                    end
        command + "@\"#{file_path}\""
      end

      # this is a fallback scenario incase of dSYM paths are not provided.
      # We use the dSYMs  folder from iTC
      def self.fastlane_dsyms_filename
        paths = Dir['./**/*.dSYM.zip']
        return '' if paths.empty?

        iTunesConnectdSYMs = paths[0]
        iTunesConnectdSYMs ['./'] = ''
        renamediTunesConnectdSYMs = iTunesConnectdSYMs.clone
        renamediTunesConnectdSYMs ['.dSYM'] = '-iTC'
        File.rename(iTunesConnectdSYMs, renamediTunesConnectdSYMs)
        default_value = renamediTunesConnectdSYMs
      end
    end
  end
end
