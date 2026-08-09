/**
 * status-bar — footer / statusline extension.
 *
 * Tiny entrypoint kept for Pi extension discovery; implementation lives under
 * ./status-bar/ so agents can navigate by concern instead of loading this file.
 *
 * This is a fork off https://pi.dev/packages/pi-bar
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { registerStatusBarExtension } from "./status-bar/extension.js";

export default function (pi: ExtensionAPI) {
  registerStatusBarExtension(pi);
}
