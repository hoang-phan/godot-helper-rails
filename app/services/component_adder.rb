class ComponentAdder < BaseSceneAdder
  attr_reader :component

  def initialize(component, scene)
    super(scene)
    @component = component
  end

  def call
    FileUtils.mkdir_p(out_components_directory)
    FileUtils.mkdir_p(out_scripts_directory)
    copy_gd_files
    add_tscn_scenes
  end

  private

  def copy_gd_files
    `cp #{component_directory}/*.gd #{out_scripts_directory} 2> /dev/null`
  end

  def add_tscn_scenes
    ext_resource_lines = []
    component_lines = []
    new_lines = []
    File.readlines(scene_path, chomp: true).each do |line|
      new_lines << line
    end
    scene_content = new_lines[1..].join("\n")
    load_steps = new_lines[0].match(/load_steps=(\d+)/)[1].to_i rescue 0

    Dir["#{component_directory}/*.tscn"].each do |tscn_path|
      content = File.read(tscn_path)
      content.gsub!("{{out_components_directory}}", out_components_path)
      content.gsub!("{{out_scripts_directory}}", out_scripts_path)
      content.gsub!("{{uid}}", generate_uid)
      (1..10).each do |i|
        content.gsub!("{{id#{i}}}", generate_id)
      end

      filename = File.basename(tscn_path)
      filename_without_extension = File.basename(filename, '.tscn')
      gd_content = File.read("#{component_directory}/#{filename_without_extension}.gd")
      export_variables = gd_content.scan(/@export\s+var\s+(\w+)\s*:\s*(\w+Component)/).select do |(variable_name, component_name)|
        scene_content.include?(%(name="#{component_name}"))
      end

      class_name = filename_without_extension.titleize.gsub(/\s/, '')
      uid = content.match(/uid:\/\/[a-z0-9]+/)[0]
      component_id = generate_id
      unless content.include?(%(path="res://#{out_components_path}/#{filename}"))
        load_steps += 1
      end

      scene_content.gsub!(/\n\[ext_resource type=\"PackedScene\".*path=\"res:\/\/#{out_components_path}\/#{filename}\".*/, "")
      scene_content.gsub!(/\n\[node name=\"#{class_name}\".*(\n.*NodePath.*)*\n?/, "")

      ext_resource_lines << %(
[ext_resource type="PackedScene" uid="#{uid}" path="res://#{out_components_path}/#{filename}" id="#{component_id}"])

      if export_variables.blank?
        component_lines << %(
[node name="#{class_name}" parent="." instance=ExtResource("#{component_id}")])
      else
        node_paths = export_variables.map do |(key, _)|
          %("#{key}")
        end.join(', ')
        reference_lines = export_variables.map do |(key, value)|
          %(#{key} = NodePath("../#{value}"))
        end.join("\n")
        component_lines << %(
[node name="#{class_name}" parent="." node_paths=PackedStringArray(#{node_paths}) instance=ExtResource("#{component_id}")]
#{reference_lines})
      end

      File.open("#{out_components_directory}/#{filename}", 'w') do |file|
        file << content
      end
    end

    new_lines[0].gsub!(/load_steps=(\d+)/, "load_steps=#{load_steps}") 

    new_lines = [new_lines[0]] + ext_resource_lines + [scene_content] + component_lines

    File.open(scene_path, "w") { |f| f << new_lines.join("\n") }
  end

  def component_path
    @component_path ||= "#{ENV['HOME']}/#{components_root}/#{component}"
  end

  def component_directory
    @component_directory ||= File.dirname(component_path)
  end

  def out_scripts_directory
    "#{ENV['HOME']}/#{project_root}/#{out_scripts_path}"
  end

  def out_scripts_path
    "Scripts/#{File.dirname(component)}"
  end
end
