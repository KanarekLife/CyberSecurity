import "reveal.js/dist/reveal.css";
import "reveal.js/dist/theme/night.css";
import Reveal from "reveal.js";
import Markdown from "reveal.js/plugin/markdown/markdown";
import RevealNotes from "reveal.js/plugin/notes/notes";

let deck = new Reveal({
  plugins: [Markdown, RevealNotes],
});
deck.initialize();
