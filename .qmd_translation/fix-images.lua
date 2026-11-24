-- fix-images.lua
-- Pandoc Lua filter: runs on every Image element after pandoc parses the LaTeX.
--
-- The LaTeX sources reference ../img/<chapter>/<name>.eps (or .pdf).
-- Browsers can't display EPS/PDF in an <img>, so point at a .png instead.
-- The ../img/ prefix is kept: tex/ and qmd/ are both one level below the
-- repo root, so the same relative path works from either folder.

function Image(img)
  -- swap .eps / .pdf (or no extension) for .png
  local base = img.src:gsub("%.eps$", ""):gsub("%.pdf$", "")
  img.src = base .. ".png"

  -- If you ever move the images, rewrite the folder prefix here, e.g.:
  -- img.src = img.src:gsub("^%.%./img/", "../images/")

  return img
end

-- \begin{figure}[t] becomes a figure attribute data-latex-placement="t".
-- Pandoc can't write attributes like that in ![](){} syntax, so it falls back
-- to a raw HTML <figure>. Dropping them gives a clean markdown figure.
function Figure(fig)
  fig.attributes = {}
  return fig
end
