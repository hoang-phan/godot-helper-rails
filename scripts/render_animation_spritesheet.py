import bpy
import os
import math

direction_labels = ["E", "NE", "N", "NW", "W", "SW", "S", "SE"]
resolution = [256, 256]
actions = os.environ.get("ACTIONS").split(',')
source_file_path = os.environ.get("ANIMATION_BLEND_FILE")
fbx_file_path = os.environ.get("FBX_MODEL")
output_path = os.environ.get("OUTPUT")
targeted_height = 2.0
height = 0

def get_action(action_name):
  for loaded_action in bpy.data.actions:
    if loaded_action.name == action_name:
      return loaded_action

def append(action_names):
  bpy.ops.import_scene.fbx(filepath=fbx_file_path)
  armature = bpy.data.objects['Armature']
  height = armature.dimensions.y
  scale = targeted_height / height
  armature.scale.x *= scale
  armature.scale.y *= scale
  armature.scale.z *= scale
  nla_tracks = armature.animation_data.nla_tracks

  if armature is None or armature.type != 'ARMATURE':
    print("Error: No valid armature object selected.")
    return

  for action_name in action_names:
    bpy.ops.wm.append(filename=action_name, directory=f"{source_file_path}/Action/")
    action = get_action(action_name)
    
    armature.animation_data.action = action
    nla_track = nla_tracks.new()
    nla_track.name = action_name
    nla_track.strips.new(action_name, 0, action)

def render_8_directions_selected_objects():
  # path fixing
  path = os.path.abspath(output_path)

  # get list of selected objects
  obj = bpy.data.objects['Armature']

  # deselect all in scene
  bpy.ops.object.select_all(action='TOGGLE')

  scene = bpy.context.scene

  scene.render.resolution_x = resolution[0]
  scene.render.resolution_y = resolution[1]

  # select the object
  bpy.context.scene.objects[obj.name].select_set(True)

  # loop through the actions
  for action in bpy.data.actions:
    action_name = action.name

    #assign the action
    bpy.context.active_object.animation_data.action = bpy.data.actions.get(action_name)
    
    #dynamically set the last frame to render based on action
    scene.frame_end = int(bpy.context.active_object.animation_data.action.frame_range[1])

    #set which actions you want to render.  Make sure to use the exact name of the action!
    if action_name in actions:
      
      #create folder for animation
      action_folder = os.path.join(path, action_name)
      if not os.path.exists(action_folder):
        os.makedirs(action_folder)
      
      offset = -90

      #loop through all 8 directions
      for angle in range(0, 360, 45):
        angle1 = (angle + offset) % 360
        angle_dir = direction_labels[angle1 // 45]

        #set which angles we want to render.
        if angle % 45 != 0:
          continue

        #create folder for specific angle
        animation_folder = os.path.join(action_folder, angle_dir)
        if not os.path.exists(animation_folder):
          os.makedirs(animation_folder)
        
        #rotate the model for the new angle
        bpy.context.active_object.rotation_euler[2] = math.radians(angle)

        #loop through and render frames.  Can set how "often" it renders.
        #Every frame is likely not needed.  Currently set to 2 (every other).
        for i in range(scene.frame_start,scene.frame_end,1):
          scene.frame_current = i

          scene.render.filepath = f'{animation_folder}\\{action_name}_{angle}_{str(i).zfill(3)}'
          bpy.ops.render.render(False, animation=False, write_still=True)

append(actions)
render_8_directions_selected_objects()
