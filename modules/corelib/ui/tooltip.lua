-- @docclass
g_tooltip = {}

-- private variables
local toolTipLabel
local currentHoveredWidget

-- private functions
local function moveToolTip(first)
  if not first and (not toolTipLabel:isVisible() or toolTipLabel:getOpacity() < 0.1) then return end

  local pos = g_window.getMousePosition()
  local windowSize = g_window.getSize()
  local labelSize = toolTipLabel:getSize()

  pos.x = pos.x + 1
  pos.y = pos.y + 1

  if windowSize.width - (pos.x + labelSize.width) < 10 then
    pos.x = pos.x - labelSize.width - 10
  else
    pos.x = pos.x + 10
  end

  if windowSize.height - (pos.y + labelSize.height) < 10 then
    pos.y = pos.y - labelSize.height - 10
  else
    pos.y = pos.y + 10
  end

  toolTipLabel:setPosition(pos)

  -- Now calculate the position for the second tooltip (toolTipLabel2)
  if not first and (not toolTipLabel2:isVisible() or toolTipLabel2:getOpacity() < 0.1) then return end
  local label2Size = toolTipLabel2:getSize()
  local pos2 = { x = pos.x, y = pos.y + labelSize.height } -- here you can offset the second tooltip, labelSize.height +2 will create a small gap
  if windowSize.height - (pos2.y + label2Size.height) < 10 then
    pos2.y = pos2.y - label2Size.height - 10
  end

  -- Set the position of the second tooltip
  toolTipLabel2:setPosition(pos2)
end


local function onWidgetHoverChange(widget, hovered)
  if hovered then
    if widget.tooltip and not g_mouse.isPressed() then
      g_tooltip.display(widget.tooltip)
      currentHoveredWidget = widget
    end
  else
    if widget == currentHoveredWidget then
      g_tooltip.hide()
      currentHoveredWidget = nil
    end
  end
end

local function onWidgetStyleApply(widget, styleName, styleNode)
  if styleNode.tooltip then
    widget.tooltip = styleNode.tooltip
  end
end

-- public functions
function g_tooltip.init()
  connect(UIWidget, {
    onStyleApply = onWidgetStyleApply,
    onHoverChange = onWidgetHoverChange
  })

  addEvent(function()
    toolTipLabel = g_ui.createWidget('UILabel', rootWidget)
    toolTipLabel:setId('toolTip')
    toolTipLabel:setBackgroundColor('#111111cc')
    toolTipLabel:setTextAlign(AlignCenter)
    toolTipLabel:hide()

    toolTipLabel2 = g_ui.createWidget('UILabel', rootWidget)
    toolTipLabel2:setId('toolTip')
    toolTipLabel2:setBackgroundColor('#111111cc')
    toolTipLabel2:setTextAlign(AlignCenter)
    toolTipLabel2:hide()
  end)
end

function g_tooltip.terminate()
  disconnect(UIWidget, {
    onStyleApply = onWidgetStyleApply,
    onHoverChange = onWidgetHoverChange
  })

  currentHoveredWidget = nil
  toolTipLabel:destroy()
  toolTipLabel = nil

  g_tooltip = nil
end

function g_tooltip.display(text)
  if text == nil or text:len() == 0 then return end
  if not toolTipLabel or not toolTipLabel2 then return end

  -- Split the text into two parts: first line and rest
  local firstLine = text:match("^(.-)\n") or text -- If no newline, treat the entire text as firstLine
  local rest = text:match("\n(.*)") or ""         -- Empty if no second part
  local itemNameLower = firstLine:lower()
  -- Set color for the first line
  -- Rarity colors used from WoW wiki https://wowpedia.fandom.com/wiki/API_GetItemQualityColor
  toolTipLabel:setColor("#ffffff")
  if string.find(itemNameLower, "legendary") then
    toolTipLabel:setColor("#ff8000")
  elseif string.find(itemNameLower, "epic") then
    toolTipLabel:setColor("#a335ee")
  elseif string.find(itemNameLower, "rare") then
    toolTipLabel:setColor("#0070dd")
  end

  -- Set text for the first label
  toolTipLabel:setText(firstLine)
  toolTipLabel:resizeToText()

  -- Set text for the second label (rest of the text)
  toolTipLabel2:setColor("#ffffff")
  toolTipLabel2:setText(rest)
  toolTipLabel2:resizeToText()

  -- Calculate maximum width between the two labels
  local maxWidth = math.max(toolTipLabel:getWidth(), toolTipLabel2:getWidth())

  -- Resize both tooltips to have the same width
  toolTipLabel:resize(maxWidth + 4, toolTipLabel:getHeight() + 4)
  toolTipLabel2:resize(maxWidth + 4, toolTipLabel2:getHeight() + 4)

  -- Show both tooltips
  toolTipLabel:show()
  toolTipLabel:raise()
  toolTipLabel:enable()

  toolTipLabel2:show()
  toolTipLabel2:raise()
  toolTipLabel2:enable()

  -- Handle fade-in effects
  g_effects.fadeIn(toolTipLabel, 100)
  g_effects.fadeIn(toolTipLabel2, 100)

  -- Move tooltips together on mouse move
  moveToolTip(true) -- Position tooltips initially
  connect(rootWidget, {
    onMouseMove = moveToolTip,
  })
end

function g_tooltip.hide()
  g_effects.fadeOut(toolTipLabel, 100)
  g_effects.fadeOut(toolTipLabel2, 100)

  disconnect(rootWidget, {
    onMouseMove = moveToolTip,
  })
end

-- @docclass UIWidget @{

-- UIWidget extensions
function UIWidget:setTooltip(text)
  self.tooltip = text
end

function UIWidget:removeTooltip()
  self.tooltip = nil
end

function UIWidget:getTooltip()
  return self.tooltip
end

-- @}

g_tooltip.init()
connect(g_app, { onTerminate = g_tooltip.terminate })
