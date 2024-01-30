class BaseSceneAdder
  attr_reader :scene, :generator
  delegate :generate_str, :generate_id, :generate_uid, to: :generator

  def initialize(scene)
    @scene = scene
    @generator = IdGenerator.new
  end

  protected

  def scene_component_prefix
    File.basename(scene, '.tscn').titleize.gsub(/\s+/, '')
  end

  def scene_path
    "#{ENV['HOME']}/#{project_root}/#{scene}"
  end

  def scene_directory
    File.dirname(scene_path)
  end

  def out_components_directory
    @out_components_directory ||= "#{scene_directory}/#{scene_component_prefix}Components"
  end

  def out_components_path
    out_components_directory.split("#{ENV['HOME']}/#{project_root}/").last
  end

  def project_root
    Rails.cache.read('project_path')
  end

  def components_root
    Rails.root.join('components')
  end
end
