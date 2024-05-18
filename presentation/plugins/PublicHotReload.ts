import type { Plugin } from "vite";

export default function CustomHmr(): Plugin {
  return {
    name: "custom-hmr",
    enforce: "post",
    // HMR
    handleHotUpdate({ file, server }) {
      if (file.endsWith(".md")) {
        server.ws.send({
          type: "full-reload",
          path: "*",
        });
      }
    },
  };
}
