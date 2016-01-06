require 'open3'
require 'govuk_template/version'
require_relative 'tar_packager'
require_relative '../compiler/jinja_processor'

module Packager
  class JinjaPackager < TarPackager
    def initialize
      super
      @base_name = "jinja_govuk_template-#{GovukTemplate::VERSION}"
    end

    def build
      @target_dir = @repo_root.join('pkg', @base_name, 'govuk_template_jinja')
      @target_dir.rmtree if @target_dir.exist?
      @target_dir.mkpath
      Dir.chdir(@target_dir) do |dir|
        prepare_contents
        add_package_init
      end
      @target_dir = @repo_root.join('pkg', @base_name)
      Dir.chdir(@target_dir) do |dir|
        generate_setup_py
        create_tarball
      end
    end

    def generate_setup_py
      template_abbreviation = "jinja"
      template_name = "jinja"
      contents = ERB.new(File.read(File.join(@repo_root, "source/setup.py.erb"))).result(binding)
      File.open(File.join(@target_dir, "setup.py"), "w") do |f|
        f.write contents
      end
    end

    def add_package_init
      output, status = Open3.capture2e("touch #{File.join(@target_dir, "__init__.py")}")
      abort "Error creating __init__.py:\n#{output}" if status.exitstatus > 0
    end

    def process_template(file)
      target_dir = @target_dir.join(File.dirname(file))
      target_dir.mkpath
      File.open(target_dir.join(generated_file_name(file)), 'wb') do |f|
        f.write Compiler::JinjaProcessor.new(file).process
      end
    end

    def create_tarball
      Dir.chdir(@target_dir.join('..')) do
        @repo_root.join("pkg").mkpath
        target_file = @repo_root.join("pkg", "#{@base_name}.tgz").to_s
        output, status = Open3.capture2e("tar -czf #{target_file.shellescape} -C #{@base_name.shellescape} .")
        abort "Error creating tar:\n#{output}" if status.exitstatus > 0
      end
    end

    private

    def generated_file_name(file_path)
      File.basename(file_path, File.extname(file_path))
    end
  end
end
