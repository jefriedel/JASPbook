// Base page and text settings
#set page(margin: 1in)
#set text(font: "Atkinson Hyperlegible Next", size: 11pt)

// Example: styling headings
#show heading.where(level: 1): it => {
  set text(fill: rgb("#2C3E50"), weight: "bold")
  block(above: 1.5em, below: 0.8em, it)
}
// Key terms: [term]{.keyterm} -> #keyterm[term] (styles/keyterms.lua)
// Colour from the original book (\keytermcol rgb(.6,0,.8))
#let keyterm(body) = text(fill: rgb("#9900cc"), weight: "bold", body)
