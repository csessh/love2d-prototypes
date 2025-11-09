local function is_collision_rect_rect(a, b)
  local a_left = a.x
  local a_right = a.x + a.width
  local a_top = a.y
  local a_bottom = a.y + a.height

  local b_left = b.x
  local b_right = b.x + b.width
  local b_top = b.y
  local b_bottom = b.y + b.height

  return a_right > b_left
    and a_left < b_right
    and a_bottom > b_top
    and a_top < b_bottom
end

local function is_collision_circle_circle(a, b)
  local distance_x = a.x - b.x
  local distance_y = a.y - b.y
  local distance_squared = (distance_x * distance_x) + (distance_y * distance_y)
  local radius_sum = a.radius + b.radius

  return distance_squared < (radius_sum * radius_sum)
end

local function is_collision_rect_circle(rect, circle)
  local closest_x = math.max(rect.x, math.min(circle.x, rect.x + rect.width))
  local closest_y = math.max(rect.y, math.min(circle.y, rect.y + rect.height))

  local distance_x = circle.x - closest_x
  local distance_y = circle.y - closest_y
  local distance_squared = (distance_x * distance_x) + (distance_y * distance_y)

  return distance_squared < (circle.radius * circle.radius)
end

local function project_polygon_onto_axis(vertices, axis_x, axis_y)
  local min_projection = math.huge
  local max_projection = -math.huge

  for i = 1, #vertices, 2 do
    local vertex_x = vertices[i]
    local vertex_y = vertices[i + 1]
    local projection = vertex_x * axis_x + vertex_y * axis_y

    min_projection = math.min(min_projection, projection)
    max_projection = math.max(max_projection, projection)
  end

  return min_projection, max_projection
end

local function is_collision_polygon_polygon(a_vertices, b_vertices)
  local function test_axes(vertices)
    for i = 1, #vertices, 2 do
      local next_i = (i + 2 - 1) % #vertices + 1
      local edge_x = vertices[next_i] - vertices[i]
      local edge_y = vertices[next_i + 1] - vertices[i + 1]

      local axis_x = -edge_y
      local axis_y = edge_x
      local length = math.sqrt(axis_x * axis_x + axis_y * axis_y)
      axis_x = axis_x / length
      axis_y = axis_y / length

      local a_min, a_max = project_polygon_onto_axis(a_vertices, axis_x, axis_y)
      local b_min, b_max = project_polygon_onto_axis(b_vertices, axis_x, axis_y)

      if a_max < b_min or b_max < a_min then
        return false
      end
    end
    return true
  end

  return test_axes(a_vertices) and test_axes(b_vertices)
end

local function is_collision_circle_polygon(circle, vertices)
  local closest_distance_squared = math.huge

  for i = 1, #vertices, 2 do
    local next_i = (i + 2 - 1) % #vertices + 1
    local edge_start_x = vertices[i]
    local edge_start_y = vertices[i + 1]
    local edge_end_x = vertices[next_i]
    local edge_end_y = vertices[next_i + 1]

    local edge_x = edge_end_x - edge_start_x
    local edge_y = edge_end_y - edge_start_y
    local edge_length_squared = edge_x * edge_x + edge_y * edge_y

    local t = math.max(
      0,
      math.min(
        1,
        (
          (circle.x - edge_start_x) * edge_x
          + (circle.y - edge_start_y) * edge_y
        ) / edge_length_squared
      )
    )
    local closest_x = edge_start_x + t * edge_x
    local closest_y = edge_start_y + t * edge_y

    local distance_x = circle.x - closest_x
    local distance_y = circle.y - closest_y
    local distance_squared = distance_x * distance_x + distance_y * distance_y

    closest_distance_squared =
      math.min(closest_distance_squared, distance_squared)
  end

  return closest_distance_squared < (circle.radius * circle.radius)
end

local function rect_to_vertices(rect)
  return {
    rect.x,
    rect.y,
    rect.x + rect.width,
    rect.y,
    rect.x + rect.width,
    rect.y + rect.height,
    rect.x,
    rect.y + rect.height,
  }
end

local CollisionStrategies = {}

CollisionStrategies["rectangle-rectangle"] = is_collision_rect_rect

CollisionStrategies["circle-circle"] = is_collision_circle_circle

CollisionStrategies["circle-rectangle"] = function(a, b)
  if a.type == "rectangle" then
    return is_collision_rect_circle(a, b)
  else
    return is_collision_rect_circle(b, a)
  end
end

CollisionStrategies["triangle-triangle"] = function(a, b)
  return is_collision_polygon_polygon(a.vertices, b.vertices)
end

CollisionStrategies["rectangle-triangle"] = function(a, b)
  local rect = a.type == "rectangle" and a or b
  local triangle = a.type == "triangle" and a or b
  return is_collision_polygon_polygon(rect_to_vertices(rect), triangle.vertices)
end

CollisionStrategies["circle-triangle"] = function(a, b)
  local circle = a.type == "circle" and a or b
  local triangle = a.type == "triangle" and a or b
  return is_collision_circle_polygon(circle, triangle.vertices)
end

local function get_strategy_key(type_a, type_b)
  if type_a <= type_b then
    return type_a .. "-" .. type_b
  else
    return type_b .. "-" .. type_a
  end
end

function is_collision(shape_a, shape_b)
  local key = get_strategy_key(shape_a.type, shape_b.type)
  local strategy = CollisionStrategies[key]

  if strategy then
    return strategy(shape_a, shape_b)
  end

  return false
end
