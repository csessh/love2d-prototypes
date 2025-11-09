local M = {}

local function is_collision_rect_circle(rect, circle)
  local closest_x_px = math.max(rect.x, math.min(circle.x, rect.x + rect.width))
  local closest_y_px = math.max(rect.y, math.min(circle.y, rect.y + rect.height))

  local distance_x_px = circle.x - closest_x_px
  local distance_y_px = circle.y - closest_y_px
  local distance_squared_px2 = (distance_x_px * distance_x_px) + (distance_y_px * distance_y_px)

  return distance_squared_px2 < (circle.radius * circle.radius)
end

local function project_polygon_onto_axis(vertices, normalized_axis_x, normalized_axis_y)
  local min_scalar_projection = math.huge
  local max_scalar_projection = -math.huge

  for i = 1, #vertices, 2 do
    local vertex_x_px = vertices[i]
    local vertex_y_px = vertices[i + 1]
    local scalar_projection = vertex_x_px * normalized_axis_x + vertex_y_px * normalized_axis_y

    min_scalar_projection = math.min(min_scalar_projection, scalar_projection)
    max_scalar_projection = math.max(max_scalar_projection, scalar_projection)
  end

  return min_scalar_projection, max_scalar_projection
end

local function is_collision_polygon_polygon(a_vertices, b_vertices)
  local function test_axes(vertices)
    for i = 1, #vertices, 2 do
      local next_i = (i + 2 - 1) % #vertices + 1
      local edge_dx_px = vertices[next_i] - vertices[i]
      local edge_dy_px = vertices[next_i + 1] - vertices[i + 1]

      local normal_x = -edge_dy_px
      local normal_y = edge_dx_px
      local normal_length = math.sqrt(normal_x * normal_x + normal_y * normal_y)
      local normalized_normal_x = normal_x / normal_length
      local normalized_normal_y = normal_y / normal_length

      local a_min, a_max = project_polygon_onto_axis(a_vertices, normalized_normal_x, normalized_normal_y)
      local b_min, b_max = project_polygon_onto_axis(b_vertices, normalized_normal_x, normalized_normal_y)

      if a_max < b_min or b_max < a_min then
        return false
      end
    end
    return true
  end

  return test_axes(a_vertices) and test_axes(b_vertices)
end

local function is_collision_circle_polygon(circle, vertices)
  local closest_distance_squared_px2 = math.huge

  for i = 1, #vertices, 2 do
    local next_i = (i + 2 - 1) % #vertices + 1
    local edge_start_x_px = vertices[i]
    local edge_start_y_px = vertices[i + 1]
    local edge_end_x_px = vertices[next_i]
    local edge_end_y_px = vertices[next_i + 1]

    local edge_dx_px = edge_end_x_px - edge_start_x_px
    local edge_dy_px = edge_end_y_px - edge_start_y_px
    local edge_length_squared_px2 = edge_dx_px * edge_dx_px + edge_dy_px * edge_dy_px

    local edge_parameter_normalized = math.max(
      0,
      math.min(
        1,
        (
          (circle.x - edge_start_x_px) * edge_dx_px
          + (circle.y - edge_start_y_px) * edge_dy_px
        ) / edge_length_squared_px2
      )
    )
    local closest_x_px = edge_start_x_px + edge_parameter_normalized * edge_dx_px
    local closest_y_px = edge_start_y_px + edge_parameter_normalized * edge_dy_px

    local distance_x_px = circle.x - closest_x_px
    local distance_y_px = circle.y - closest_y_px
    local distance_squared_px2 = distance_x_px * distance_x_px + distance_y_px * distance_y_px

    closest_distance_squared_px2 =
      math.min(closest_distance_squared_px2, distance_squared_px2)
  end

  return closest_distance_squared_px2 < (circle.radius * circle.radius)
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
CollisionStrategies["rectangle-rectangle"] = function(a, b)
  local a_left_px = a.x
  local a_right_px = a.x + a.width
  local a_top_px = a.y
  local a_bottom_px = a.y + a.height

  local b_left_px = b.x
  local b_right_px = b.x + b.width
  local b_top_px = b.y
  local b_bottom_px = b.y + b.height

  return a_right_px > b_left_px
    and a_left_px < b_right_px
    and a_bottom_px > b_top_px
    and a_top_px < b_bottom_px
end

CollisionStrategies["circle-circle"] = function(a, b)
  local distance_x_px = a.x - b.x
  local distance_y_px = a.y - b.y
  local distance_squared_px2 = (distance_x_px * distance_x_px) + (distance_y_px * distance_y_px)
  local radius_sum_px = a.radius + b.radius

  return distance_squared_px2 < (radius_sum_px * radius_sum_px)
end

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

function M.detect_collision(shape_a, shape_b)
  local key = get_strategy_key(shape_a.type, shape_b.type)
  local strategy = CollisionStrategies[key]

  if strategy then
    return strategy(shape_a, shape_b)
  end

  return false
end

return M
