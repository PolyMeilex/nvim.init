local CompletionItemKind = vim.lsp.protocol.CompletionItemKind

LspItemTypeHighlight = {
  [CompletionItemKind.Text] = "CmpItemKindText",
  [CompletionItemKind.Method] = "CmpItemKindMethod",
  [CompletionItemKind.Function] = "CmpItemKindFunction",
  [CompletionItemKind.Constructor] = "CmpItemKindConstructor",
  [CompletionItemKind.Field] = "CmpItemKindField",
  [CompletionItemKind.Variable] = "CmpItemKindVariable",
  [CompletionItemKind.Class] = "CmpItemKindClass",
  [CompletionItemKind.Interface] = "CmpItemKindInterface",
  [CompletionItemKind.Module] = "CmpItemKindModule",
  [CompletionItemKind.Property] = "CmpItemKindProperty",
  [CompletionItemKind.Unit] = "CmpItemKindUnit",
  [CompletionItemKind.Value] = "CmpItemKindValue",
  [CompletionItemKind.Enum] = "CmpItemKindEnum",
  [CompletionItemKind.Keyword] = "CmpItemKindKeyword",
  [CompletionItemKind.Snippet] = "CmpItemKindSnippet",
  [CompletionItemKind.Color] = "CmpItemKindColor",
  [CompletionItemKind.File] = "CmpItemKindFile",
  [CompletionItemKind.Reference] = "CmpItemKindReference",
  [CompletionItemKind.Folder] = "CmpItemKindFolder",
  [CompletionItemKind.EnumMember] = "CmpItemKindEnumMember",
  [CompletionItemKind.Constant] = "CmpItemKindConstant",
  [CompletionItemKind.Struct] = "CmpItemKindStruct",
  [CompletionItemKind.Event] = "CmpItemKindEvent",
  [CompletionItemKind.Operator] = "CmpItemKindOperator",
  [CompletionItemKind.TypeParameter] = "CmpItemKindTypeParameter",
}

LspItemTypeIcons = {
  [CompletionItemKind.Text] = "",
  [CompletionItemKind.Method] = "󰆧",
  [CompletionItemKind.Function] = "󰊕",
  [CompletionItemKind.Constructor] = "",
  [CompletionItemKind.Field] = "󰇽",
  [CompletionItemKind.Variable] = "󰂡",
  [CompletionItemKind.Class] = "󰠱",
  [CompletionItemKind.Interface] = "",
  [CompletionItemKind.Module] = "",
  [CompletionItemKind.Property] = "󰜢",
  [CompletionItemKind.Unit] = "",
  [CompletionItemKind.Value] = "󰎠",
  [CompletionItemKind.Enum] = "",
  [CompletionItemKind.Keyword] = "󰌋",
  [CompletionItemKind.Snippet] = "",
  [CompletionItemKind.Color] = "󰏘",
  [CompletionItemKind.File] = "󰈙",
  [CompletionItemKind.Reference] = "",
  [CompletionItemKind.Folder] = "󰉋",
  [CompletionItemKind.EnumMember] = "",
  [CompletionItemKind.Constant] = "󰏿",
  [CompletionItemKind.Struct] = "",
  [CompletionItemKind.Event] = "",
  [CompletionItemKind.Operator] = "󰆕",
  [CompletionItemKind.TypeParameter] = "󰅲",
}

return {
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
    opts = {
      override = {
        rs = {
          icon = "",
          color = "#f46623",
          cterm_color = "216",
          name = "Rs",
        },
      },
    },
  },
}
