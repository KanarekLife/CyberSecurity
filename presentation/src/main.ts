import "reveal.js/dist/reveal.css";
import "reveal.js/dist/theme/white.css";
import Reveal from "reveal.js";
import Markdown from "reveal.js/plugin/markdown/markdown";
import RevealNotes from "reveal.js/plugin/notes/notes";
import ReavealHighight from "reveal.js/plugin/highlight/highlight";

let deck = new Reveal({
  plugins: [Markdown, RevealNotes, ReavealHighight],
  width: 1920,
  height: 1080,
  history: true,
});
deck.initialize();
