-- This is a custom writer for pandoc. Used inconjunction with the 
-- default tei template, it produces a valid TEI file, conforming 
-- to the TEI Lite P5 document definition. 
-- It is a lightly modified version of the default writer provided 
-- by pandoc.
--
-- Invoke with: pandoc -t sample.lua
--
-- Note: you need not have lua installed on your system to use this
-- custom writer.  However, if you do have lua installed, you can
-- use it to test changes to the script.  'lua sample.lua' will
-- produce informative error messages if your code contains
-- syntax errors.

-- Character escaping
local function escape(s, in_attribute)
  return s:gsub("[<>&\"']",
    function(x)
      if x == '<' then
        return '&lt;'
      elseif x == '>' then
        return '&gt;'
      elseif x == '&' then
        return '&amp;'
      elseif x == '"' then
        return '&quot;'
      elseif x == "'" then
        return '&#39;'
      else
        return x
      end
    end)
end

-- Helper function to check if string begins with 
-- specified substring. Necessary for handling raw 
-- stuff.
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

-- Helper function to split string into list.
-- From: http://lua-users.org/wiki/SplitJoin
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


-- Helper function to convert an attributes table into
-- a string that can be put into HTML tags.
local function attributes(attr)
  local attr_table = {}
  for x,y in pairs(attr) do
    if y and y ~= "" then
      table.insert(attr_table, ' ' .. x .. '="' .. escape(y,true) .. '"')
    end
  end
  return table.concat(attr_table)
end

-- Run cmd on a temporary file containing inp and return result.
local function pipe(cmd, inp)
  local tmp = os.tmpname()
  local tmph = io.open(tmp, "w")
  tmph:write(inp)
  tmph:close()
  local outh = io.popen(cmd .. " " .. tmp,"r")
  local result = outh:read("*all")
  outh:close()
  os.remove(tmp)
  return result
end

-- Variables to manage divs created by headers.
local headerDivDepth = 0

-- Blocksep is used to separate block elements.
function Blocksep()
  return "\n\n"
end

-- This function is called once for the whole document. Parameters:
-- body is a string, metadata is a table, variables is a table.
-- This gives you a fragment.  You could use the metadata table to
-- fill variables in a custom lua template.  Or, pass `--template=...`
-- to pandoc, and pandoc will add do the template processing as
-- usual.
function Doc(body, metadata, variables)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add(body)
  return table.concat(buffer,'\n')
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).
-- Comments indicate the types of other variables.

function Str(s)
  return escape(s)
end

function Space()
  return " "
end

function RawInline(s)
   return (s)
end

function RawBlock(s)
   return ''
end

function SingleQuoted(s)
   return "‘" .. s .. "’"
end

function DoubleQuoted(s)
   return "“" .. s .. "”"
end

function LineBreak()
-- NOTETOSELF: Advantages of using <lb /> instead?
  return "\n"
end

function Emph(s)
  return "<hi rend='italics'>" .. s .. "</hi>"
end

function Strong(s)
  return "<hi rend='bolds'>" .. s .. "</hi>"
end

function Subscript(s)
  return "<hi rend='subscript'>" .. s .. "</hi>"
end

function Superscript(s)
  return "<hi rend='superscript'>" .. s .. "</hi>"
end

function SmallCaps(s)
  return "<hi rend='small-caps'>" .. s .. "</hi>"
end

function Strikeout(s)
  return "<hi rend='strikeout'>" .. s .. "</hi>"
end

function Link(s, src, tit)
-- NOTETOSELF: This use of <ref> does not preserve the 'title', contained 
-- in the variable 'tit.'
  return "<ref target='" .. escape(src,true) .. s .. "</ref>"
end

function Image(s, src, tit)
   -- Uses a <figure> with <graphic> and <head> for title.
   return "<figure>\n <graphic url=" .. escape(src,true) .. "/> \n <head>" .. tit .. "<\head>\n</figure>\n"
end

function CaptionedImage(s, src, tit)
   -- Uses a <figure> with <graphic> and <head> for title.


   if tit and tit ~= '' then
      captionString = '\n<head>' .. tit .. '</head>\n'
   else
      captionString = ''
   end

   return "<figure>\n <graphic url='" .. escape(s,true) .. "' />" .. captionString .. "\n</figure>\n"
end


function Code(s, attr)
  return "<code" .. attributes(attr) .. ">" .. escape(s) .. "</code>"
end

function InlineMath(s)
  return "\\(" .. escape(s) .. "\\)"
end

function DisplayMath(s)
  return "\\[" .. escape(s) .. "\\]"
end


--- We handle notes simply, inline. 
function Note(s)
   return '<note>' .. s .. '</note>'
end

function Span(s, attr)
   -- NOTETOSELF: Implementing arbitary span with <seg>.
  return "<seg" .. attributes(attr) .. ">" .. s .. "</seg>"
end

function Cite(s, cs)
  local ids = {}
  for _,cit in ipairs(cs) do
    table.insert(ids, cit.citationId)
  end
  return "<span class='cite' data-citation-ids='" .. table.concat(ids, ",") ..
    "'>" .. s .. "</span>"
end

function Plain(s)
  return s
end

function Para(s)
   return "<p>" .. s .. "</p>"
end

function poeticLine(s)
   return "<l>" .. s .. "</l>\n"
end

-- lev is an integer, the header level.
function Header(lev, s, attr)

   return "<div type='heading-" .. lev .."' " .. attributes(attr) .. ">" .. s .. "</div>"
end

function BlockQuote(s)
  return "<q rend='block'>" .. s .. "</q>"
end

function HorizontalRule()
   -- NOTETOSELF: We have no encoding for horizontal rule.
  return
end

function CodeBlock(s, attr)
  -- If code block has class 'dot', pipe the contents through dot
  -- and base64, and include the base64-encoded png as a data: URL.
  if attr.class and string.match(' ' .. attr.class .. ' ',' dot ') then
    local png = pipe("base64", pipe("dot -Tpng", s))
    return '<img src="data:image/png;base64,' .. png .. '"/>'
  -- otherwise treat as code (one could pipe through a highlighter)
  else
    return "<code" .. attributes(attr) .. ">" .. escape(s) ..
           "</code>"
  end
end

function BulletList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<item>" .. item .. "</item>")
  end
  return "<list rend='bulleted'>\n" .. table.concat(buffer, "\n") .. "\n</list>"
end

function OrderedList(items)
  local buffer = {}
  for _, item in pairs(items) do
    table.insert(buffer, "<item>" .. item .. "</item>")
  end
  return "<list rend='numbered'>\n" .. table.concat(buffer, "\n") .. "\n</list>"
end

-- Revisit association list STackValue instance.
function DefinitionList(items)
  local buffer = {}
  for _,item in pairs(items) do
    for k, v in pairs(item) do
      table.insert(buffer,"<label>" .. k .. "</label>\n<item>" ..
                        table.concat(v,"</item>\n<item>") .. "</item>")
    end
  end
  return "<list type='definition'>\n" .. table.concat(buffer, "\n") .. "\n</list>"
end

-- Convert pandoc alignment to something HTML can use.
-- align is AlignLeft, AlignRight, AlignCenter, or AlignDefault.
function html_align(align)
  if align == 'AlignLeft' then
    return 'left'
  elseif align == 'AlignRight' then
    return 'right'
  elseif align == 'AlignCenter' then
    return 'center'
  else
    return 'left'
  end
end

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
  local buffer = {}
  local function add(s)
    table.insert(buffer, s)
  end
  add("<table>")
  if caption ~= "" then
    add("<head>" .. caption .. "</head>")
  end

  -- NOTETOSELF: For now, we do nothing with these widths.
  if widths and widths[1] ~= 0 then
    for _, w in pairs(widths) do
--      add('<col width="' .. string.format("%d%%", w * 100) .. '" />')
    end
  end
  local header_row = {}
  local empty_header = true

  for i, h in pairs(headers) do
    local align = html_align(aligns[i])
    table.insert(header_row,'<th align="' .. align .. '">' .. h .. '</th>')
    empty_header = empty_header and h == ""
  end
  if empty_header then
    head = ""
  else
    add('<tr class="header">')
    for _,h in pairs(header_row) do
      add(h)
    end
    add('</tr>')
  end
  local class = "even"
  for _, row in pairs(rows) do
    class = (class == "even" and "odd") or "even"
    add('<tr class="' .. class .. '">')
    for i,c in pairs(row) do
      add('<td align="' .. html_align(aligns[i]) .. '">' .. c .. '</td>')
    end
    add('</tr>')
  end
  add('</table')
  return table.concat(buffer,'\n')
end

function Div(s, attr)
   if attr['class'] == 'poetry' then
      lines = split(s, '\n')
      returnval = "<lg type='poetry'>\n"

      -- Are there multiple line groups within this linegroup?
      -- Let's count the line groups.
      lgs = 0
      for no, line in ipairs(lines) do
	 if line == '' then lgs = lgs + 1 end
      end
      lgs = lgs + 1

      if lgs > 0 then 
	 returnval = returnval .. '<lg>\n'
      end

      closed = 0
      
      for no, line in ipairs(lines) do
--	 returnval = returnval .. '<l>' .. line .. '</l>\n'
	 if line == '' then 
	    returnval = returnval .. '</lg>\n'
	    closed = closed + 1
	    if no <= table.getn(lines) then 
	       returnval = returnval .. '<lg>\n' 
	    end
	 else 
	    returnval = returnval .. poeticLine(line)
	 end
      end

      if closed < lgs then returnval = returnval .. '</lg>\n' end

      returnval = returnval .. '</lg>'

      return returnval
   else
      return "<div" .. attributes(attr) .. ">\n" .. s .. "</div>"
   end
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
  end
setmetatable(_G, meta)

