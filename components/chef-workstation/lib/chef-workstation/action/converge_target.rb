require "chef-workstation/action/base"
require "chef-workstation/text"
require "pathname"
require "tempfile"

module ChefWorkstation::Action
  class ConvergeTarget < Base

    def perform_action
      remote_tmp = connection.run_command!(mktemp)
      remote_dir_path = escape_windows_path(remote_tmp.stdout.strip)
      remote_recipe_path = create_remote_recipe(@config, remote_dir_path)
      remote_config_path = create_remote_config(remote_dir_path)

      c = connection.run_command("#{chef_client} #{remote_recipe_path} --config #{remote_config_path}")

      connection.run_command!("#{delete_folder} #{remote_dir_path}")
      if c.exit_status == 0
        ChefWorkstation::Log.debug(c.stdout)
        notify(:success)
      else
        notify(:error)
        handle_ccr_error()
      end
    end

    def create_remote_recipe(config, dir)
      remote_recipe_path = File.join(dir, "recipe.rb")

      if config.has_key?(:recipe_path)
        recipe_path = config.delete :recipe_path
        begin
          connection.upload_file(recipe_path, remote_recipe_path)
        rescue RuntimeError
          raise RecipeUploadFailed.new(recipe_path)
        end
      else
        resource_type = config.delete :resource_type
        resource_name = config.delete :resource_name
        properties = config.delete(:properties) || []
        begin
          recipe_file = Tempfile.new
          recipe_file.write(create_resource(resource_type, resource_name, properties))
          recipe_file.close
          connection.upload_file(recipe_file.path, remote_recipe_path)
        rescue RuntimeError
          raise ResourceUploadFailed.new()
        ensure
          recipe_file.unlink
        end
      end
      remote_recipe_path
    end

    def create_remote_config(dir)
      remote_config_path = File.join(dir, "workstation.rb")

      workstation_rb = <<~EOM
        local_mode true
        color false
        cache_path "#{cache_path}"
      EOM

      begin
        config_file = Tempfile.new
        config_file.write(workstation_rb)
        config_file.close
        connection.upload_file(config_file.path, remote_config_path)
      rescue RuntimeError
        raise ConfigUploadFailed.new()
      end
      remote_config_path
    end

    def handle_ccr_error
      require "chef-workstation/errors/ccr_failure_mapper"
      mapper_opts = {}
      c = connection.run_command(read_chef_stacktrace)
      if c.exit_status == 0
        lines = c.stdout.split("\n")
        # We need to delete the stacktrace after copying it over. Otherwise if we get a
        # remote failure that does not write a chef stacktrace its possible to get an old
        # stale stacktrace.
        connection.run_command!(delete_chef_stacktrace)
        ChefWorkstation::Log.error("Remote chef-client error follows:")
        ChefWorkstation::Log.error("\n    " + lines.join("\n    "))
      else
        lines = []
        ChefWorkstation::Log.error("Could not read remote stacktrace:")
        ChefWorkstation::Log.error("stdout: #{c.stdout}")
        ChefWorkstation::Log.error("stderr: #{c.stderr}")
        mapper_opts[:stdout] = c.stdout
        mapper_opts[:stdrerr] = c.stderr
      end
      mapper = ChefWorkstation::Errors::CCRFailureMapper.new(lines, mapper_opts)
      mapper.raise_mapped_exception!
    end

    def create_resource(resource_type, resource_name, properties)
      r = "#{resource_type} '#{resource_name}'"
      # lets format the properties into the correct syntax Chef expects
      unless properties.empty?
        r += " do\n"
        properties.each do |k, v|
          v = "'#{v}'" if v.is_a? String
          r += "  #{k} #{v}\n"
        end
        r += "end"
      end
      r += "\n"
      r
    end

    class RecipeUploadFailed < ChefWorkstation::Error
      def initialize(local_path); super("CHEFUPL001"); end
    end

    class ResourceUploadFailed < ChefWorkstation::Error
      def initialize(); super("CHEFUPL002"); end
    end

    class ConfigUploadFailed < ChefWorkstation::Error
      def initialize(); super("CHEFUPL003"); end
    end

  end
end
