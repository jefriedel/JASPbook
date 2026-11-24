-- keyterms.lua  (Quarto render filter, listed under `filters:` in _quarto.yml)
-- Styles [term]{.keyterm} spans and attaches definitions from glossary.yml.
--   HTML:  <span class="keyterm" data-definition="..."> — keyterms.html turns that into a popup
--   Typst: #keyterm[term] — the keyterm() function is defined in typst-style.typ
--   other: bold

local glossary = nil   -- term (normalised) -> definition as HTML

local function norm(s)
  s = s:gsub("\226\128\153", "'")          -- curly apostrophe -> straight
  s = s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  return s:lower()
end

local function load_glossary()
  glossary = {}
  local dir = (quarto.project and quarto.project.directory) or "."
  local f = io.open(dir .. "/glossary.yml", "r")
  if not f then return end
  local text = f:read("a")
  f:close()
  -- let pandoc parse the YAML (and the markdown inside each definition)
  local meta = pandoc.read("---\n" .. text .. "\n---\n", "markdown").meta
  for key, value in pairs(meta) do
    local blocks
    local t = pandoc.utils.type(value)
    if t == "Blocks" then blocks = value
    elseif t == "Inlines" then blocks = pandoc.Blocks({ pandoc.Plain(value) })
    else blocks = pandoc.Blocks({ pandoc.Plain({ pandoc.Str(tostring(value)) }) }) end
    glossary[norm(key)] = pandoc.write(pandoc.Pandoc(blocks), "html"):gsub("%s+$", "")
  end
end

function Span(span)
  if not span.classes:includes("keyterm") then return nil end

  if quarto.doc.is_format("html") then
    if not glossary then load_glossary() end
    local key = norm(span.attributes.term or pandoc.utils.stringify(span.content))
    local def = glossary[key]
    if def then
      span.attributes["data-definition"] = def
      span.attributes.tabindex = "0"         -- reachable with the keyboard
    end
    span.attributes.term = nil
    return span

  elseif quarto.doc.is_format("typst") then
    local out = pandoc.Inlines({ pandoc.RawInline("typst", "#keyterm[") })
    out:extend(span.content)
    out:insert(pandoc.RawInline("typst", "]"))
    return out

  else
    return pandoc.Strong(span.content)
  end
end
