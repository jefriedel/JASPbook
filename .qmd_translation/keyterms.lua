-- keyterms.lua  (conversion filter, used by tex_to_qmd.sh)
-- macros.tex defines \keyterm{x} as \textcolor{keyterm}{x}; pandoc reads that as a
-- span with style "color: keyterm". Turn it into a class, so the markdown says
--   [belief bias effect]{.keyterm}
-- Styling and hover definitions are added at render time by styles/keyterms.lua.

function Span(s)
  if s.attributes.style == "color: keyterm" then
    s.attributes.style = nil
    s.classes:insert("keyterm")
    return s
  end
end
