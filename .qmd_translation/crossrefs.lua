-- crossrefs.lua
-- Pandoc Lua filter: turn LaTeX \label / \ref into Quarto cross-references,
-- so Quarto numbers figures/tables/sections itself (correct after reordering)
-- and Typst doesn't fail on links to labels it can't find.
--
--   \label{fig:x} on a figure      ->  {#fig-x}
--   \label{tab:x} on a table       ->  {#tab-x}
--   \label{sec:x} / \label{ch:x}   ->  {#sec-x} on the heading  (Quarto uses sec- for chapters too)
--   Figure~\ref{fig:x}             ->  @fig-x       (Quarto writes "Figure 2.1")
--   Figures~\ref{fig:x}            ->  [-@fig-x]    (just the number, word kept)
--
-- A reference to a chapter not converted yet renders as "?@sec-x" with a warning
-- and resolves once that chapter is in the book.

local NBSP = "\194\160"   -- non-breaking space (LaTeX ~), as UTF-8 bytes

local kinds = { fig = "fig", tab = "tab", sec = "sec", ch = "sec" }

-- words that Quarto adds itself, so we drop them from the text
local prefix_words = {
  fig = { figure = true, ["fig."] = true },
  tab = { table = true },
  sec = { section = true, chapter = true, ["sec."] = true, ["ch."] = true, ["chap."] = true },
}

local function quarto_id(label)
  local kind, name = (label or ""):match("^(%a+):(.+)$")
  if not kind or not kinds[kind] then return nil end
  return kinds[kind] .. "-" .. name:gsub("[^%w%-]", "-")
end

-- headings: move the label span's id onto the heading itself
function Header(h)
  local out = pandoc.Inlines({})
  for _, el in ipairs(h.content) do
    local id = el.t == "Span" and quarto_id(el.attributes.label)
    if id then
      h.identifier = id
    else
      out:insert(el)
    end
  end
  -- tidy the space / ~ that sat before the \label
  while #out > 0 and (out[#out].t == "Space" or (out[#out].t == "Str" and out[#out].text:sub(-2) == NBSP)) do
    if out[#out].t == "Space" then out:remove(#out) else out[#out].text = out[#out].text:sub(1, -3) end
  end
  h.content = out
  return h
end

function Figure(f) f.identifier = quarto_id(f.identifier) or f.identifier; return f end
function Table(t)  t.identifier = quarto_id(t.identifier) or t.identifier; return t end

-- references
function Inlines(inlines)
  local out = pandoc.Inlines({})
  for _, el in ipairs(inlines) do
    local id = el.t == "Link" and el.attributes["reference-type"] and quarto_id(el.attributes.reference)
    if not id then
      out:insert(el)
    else
      local mode = "SuppressAuthor"            -- [-@id]: number only
      local kind = id:match("^(%a+)-")
      local prev = out[#out]
      local lead, word
      if prev and prev.t == "Str" then
        lead, word = prev.text:match("^(.-)(%a+%.?)" .. NBSP .. "$")
      end
      if word and prefix_words[kind][word:lower()] then
        mode = "AuthorInText"                 -- @id: Quarto writes "Figure 2.1"
        if lead == "" then out:remove(#out) else prev.text = lead end
      end
      out:insert(pandoc.Cite({}, { pandoc.Citation(id, mode) }))
    end
  end
  return out
end

-- run headings/figures/tables first, then references
return {
  { Header = Header, Figure = Figure, Table = Table },
  { Inlines = Inlines },
}
