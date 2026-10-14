-- bash-language-server, installed by populate.sh (npm, ~/.local).
-- Settings: https://github.com/bash-lsp/bash-language-server (bashIde.*)
--
-- Diagnostics come from shellcheck (apt), which the server runs on every
-- change when it finds it on PATH. It would also format with shfmt, but
-- conform runs shfmt itself, so the server's formatting is never asked for.
-- Not for zsh: .zshrc gets filetype zsh, which the server doesn't understand.
return {
  cmd = { "bash-language-server", "start" },
  -- #!/bin/bash scripts usually get filetype sh, not bash
  filetypes = { "bash", "sh" },
  root_markers = { ".git" },
}
