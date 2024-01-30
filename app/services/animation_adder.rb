class AnimationAdder < BaseSceneAdder
  attr_reader :fbx, :actions, :generator

  def initialize(fbx, actions, scene)
    super(scene)
    @fbx = fbx
    @actions = actions.scan(/[+-]\w+/).map { |w| [w[0] == '+', w[1..]] }
  end

  def call
    FileUtils.rm_rf(tmp_output_path)
    FileUtils.rm_rf("#{asset_directory}/#{model_name}")
    `ACTIONS=#{actions.map(&:last).join(',')} ANIMATION_BLEND_FILE=scripts/animations.blend FBX_MODEL=#{fbx_path} OUTPUT=#{tmp_output_path} blender scripts/main.blend -b --python scripts/render_animation_spritesheet.py 1> /dev/null`
    FileUtils.mkdir_p(asset_directory)
    FileUtils.mv(tmp_output_path, asset_directory)
    `cd #{ENV['HOME']}/#{project_root} && godot -e --headless --quit . && cd -`
    FileUtils.mkdir_p(out_components_directory)

    frames = {}

    Dir["#{asset_directory}/#{model_name}/**/*.import"].each do |import_path|
      file_path = import_path[0..-8]
      uid = File.read(import_path).match(/uid:\/\/[a-z0-9]+/)[0]
      relative_path = file_path.split("#{asset_directory}/#{model_name}/").last
      animation_name, direction = relative_path.split("/")
      anim = "#{animation_name}_#{direction}".downcase
      frames[anim] ||= []
      frames[anim] << [uid, file_path.split("#{project_root}/").last, generate_id]
    end

    animation_tree_lines = []
    node_statemachine_lines = []
    loops = {}
    load_steps = generator.counter + 2

    actions.each_with_index do |(looped, animation_state), asi|
      node_animations = {}
      node_blendspace_2d_id = "AnimationNodeBlendSpace2D_#{generate_str(5)}"
      node_blendspace_2d_lines = [
        %([sub_resource type="AnimationNodeBlendSpace2D" id="#{node_blendspace_2d_id}"])
      ]
      load_steps += 1
      timescale_id = "AnimationNodeTimeScale_#{generate_str(5)}"

      ct = 0
      %w(
        nw n ne
        w x e
        sw s se
      ).each_with_index do |dir, index|
        next if dir == 'x'
        i = index % 3 - 1
        j = index / 3 - 1
        id = "AnimationNodeAnimation_#{generate_str(5)}"

        node_animations[id] = %(
[sub_resource type="AnimationNodeAnimation" id="#{id}"]
animation = &"#{animation_state}_#{dir}"
)
        loops["#{animation_state}_#{dir}"] = looped
        node_blendspace_2d_lines <<
%(blend_point_#{ct}/node = SubResource("#{id}")
blend_point_#{ct}/pos = Vector2(#{i}, #{j}))

        load_steps += 1
        ct += 1
      end

      blendtree_id = "AnimationNodeBlendTree_#{generate_str(5)}"

      node_statemachine_lines <<
%(states/#{animation_state}/node = SubResource("#{blendtree_id}")
states/#{animation_state}/position = Vector2(344, #{asi * 90}))

      animation_tree_lines << %(
[sub_resource type="AnimationNodeTimeScale" id="#{timescale_id}"]
#{node_animations.values.join("\n")}

[sub_resource type="AnimationNodeBlendSpace2D" id="#{node_blendspace_2d_id}"]
#{node_blendspace_2d_lines.join("\n")}
blend_mode = 2

[sub_resource type="AnimationNodeBlendTree" id="#{blendtree_id}"]
graph_offset = Vector2(-494.354, 41.7619)
nodes/TimeScale/node = SubResource("#{timescale_id}")
nodes/TimeScale/position = Vector2(80, 100)
nodes/dir/node = SubResource("#{node_blendspace_2d_id}")
nodes/dir/position = Vector2(-140, 100)
node_connections = [&"output", 0, &"TimeScale", &"TimeScale", 0, &"dir"]
)
      load_steps += 3
    end

    frame_lines = []

    frames.values.each do |group|
      group.each do |(uid, file_path, id)|
        frame_lines << %([ext_resource type="Texture2D" uid="#{uid}" path="res://#{file_path}" id="#{id}"])
      end
    end

    sprite_frames_id = "SpriteFrames_#{generate_str(5)}"

    animation_lines = frames.map do |anim, lst|
      frame_list = lst.map do |(_, _, id)|
      %({
"duration": 1.0,
"texture": ExtResource("#{id}")
})
      end.join(", ")

      %({
"frames": [#{frame_list}],
"loop": true,
"name": &"#{anim}",
"speed": 5.0
})
    end.join(", ")

    reset_animation_id = "Animation_#{generate_str(5)}"
    reset_animation = %(
[sub_resource type="Animation" id="#{reset_animation_id}"]
length = 0.001
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Body:animation")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0),
"transitions": PackedFloat32Array(1),
"update": 1,
"values": [&"#{frames.keys[0]}"]
}
tracks/1/type = "value"
tracks/1/imported = false
tracks/1/enabled = true
tracks/1/path = NodePath("Body:frame")
tracks/1/interp = 1
tracks/1/loop_wrap = true
tracks/1/keys = {
"times": PackedFloat32Array(0),
"transitions": PackedFloat32Array(1),
"update": 1,
"values": [0]
}
)
    load_steps += 1

    animations = {}
    animation_map = {}

    frames.each do |anim, lst|
      id = "Animation_#{generate_str(5)}"
      animation_map[id] = anim
      animations[id] = %(
[sub_resource type="Animation" id="#{id}"]#{
%(
loop_mode = 1) if loops[anim]
}
resource_name = "#{anim}"
length = #{(lst.size * 0.1).round(1)}
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Body:animation")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0),
"transitions": PackedFloat32Array(1),
"update": 1,
"values": [&"#{anim}"]
}
tracks/1/type = "value"
tracks/1/imported = false
tracks/1/enabled = true
tracks/1/path = NodePath("Body:frame")
tracks/1/interp = 1
tracks/1/loop_wrap = true
tracks/1/keys = {
"times": PackedFloat32Array(#{lst.size.times.map { |i| (i * 0.1).round(1).to_s }.join(", ")}),
"transitions": PackedFloat32Array(#{lst.size.times.map { "1" }.join(", ")}),
"update": 1,
"values": #{lst.size.times.to_a}
})
      load_steps += 1
    end

    animation_library_id = "AnimationLibrary_#{generate_str(5)}"
    uid = generate_str(12)

    node_state_machine_id = "AnimationNodeStateMachine_#{generate_str(5)}"

    lines = [%([gd_scene load_steps=#{load_steps} format=3 uid="uid://#{uid}"]

[ext_resource type="Script" path="res://{{out_scripts_directory}}/animation_component.gd" id="{{id1}}"]
)] + frame_lines + [%(
[sub_resource type="SpriteFrames" id="#{sprite_frames_id}"]
animations = [#{animation_lines}]
#{reset_animation}
#{animations.values.join("\n")}

[sub_resource type="AnimationLibrary" id="#{animation_library_id}"]
_data = {
"RESET": SubResource("#{reset_animation_id}"),
#{animation_map.map do |id, anim|
  %("#{anim}": SubResource("#{id}"))
end.join(",\n")}
}
#{animation_tree_lines.join("\n")}
[sub_resource type="AnimationNodeStateMachine" id="#{node_state_machine_id}"]
#{node_statemachine_lines.join("\n")}

[node name="AnimationComponent" type="Node2D"]
script = ExtResource("{{id1}}")

[node name="Body" type="AnimatedSprite2D" parent="."]
sprite_frames = SubResource("#{sprite_frames_id}")
animation = &"#{frames.keys[0]}"

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {
"": SubResource("#{animation_library_id}")
}

[node name="AnimationTree" type="AnimationTree" parent="."]
tree_root = SubResource("#{node_state_machine_id}")
anim_player = NodePath("../AnimationPlayer")
)]

    File.open(tscn_path, "w") { |f| f << lines.join("\n") }

    ComponentAdder.new(tscn, scene).call
    FileUtils.rm_rf(tscn_path)
  end

  private

  def asset_directory
    "#{ENV['HOME']}/#{project_root}/Assets"
  end

  def tscn_path
    "#{ENV['HOME']}/#{components_root}/#{tscn}"
  end

  def tscn
    '2d/topdown/character/Animation/animation_component.tscn'
  end

  def model_name
    File.basename(fbx)[0..-5]
  end

  def tmp_output_path
    "/tmp/#{model_name}"
  end

  def fbx_path
    "#{ENV['HOME']}/#{fbx}"
  end
end
