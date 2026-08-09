" Vim syntax file for Bruno `.bru` request files.
" Bruno (https://usebruno.com) uses its own "Bru Markup Language": a block-based
" format where each block is `keyword { ... }` or `keyword:sub { ... }`. There is
" no Tree-sitter grammar for it, so this is a hand-written syntax definition.
" JavaScript inside `script:*` and `tests` blocks is highlighted via the built-in
" javascript syntax file.

if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpoptions
set cpoptions&vim

" --- Comments ----------------------------------------------------------------
" `#` starts a line comment.
syn match bruComment "#.*$" contains=bruTodo
syn keyword bruTodo TODO FIXME XXX NOTE contained

" --- Template variables ------------------------------------------------------
" Bruno interpolates `{{varName}}` (env/vars) inside string and url values.
syn match bruTemplateVar "{{[^}]*}}" contained

" --- Block headers -----------------------------------------------------------
" Top-level block keywords. Method blocks (get/post/put/...) and structural
" blocks (meta/headers/params/auth/query/assert/docs/tests/vars).
syn keyword bruBlock meta get post put patch delete head options
syn keyword bruBlock headers params auth query assert docs tests
syn keyword bruBlock body script vars

" Sub-type modifier after a colon, e.g. `body:json`, `script:pre-request`,
" `vars:post-response`, `body:form-urlencoded`, `body:multipart-form`.
syn match bruBlockSub ":\s*\zs\h\w*" contained containedin=bruBlockRegion

" --- Keys and values ---------------------------------------------------------
" `key: value` pairs inside blocks. Match the key as a label up to the colon.
syn match bruKey "^\s*\zs\h\w*\ze\s*:"
syn match bruKey "\n\s*\zs\h\w*\ze\s*:" contained containedin=bruBlockRegion

" Quoted strings.
syn region bruString start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=bruTemplateVar
syn region bruString start=+'+ skip=+\\\\\|\\'+ end=+'+ contains=bruTemplateVar

" Bare scalar values after a colon (urls, enums like formUrlEncoded, none, etc.).
syn match bruScalar "\(:\s*\)\zs\%(none\|basic\|bearer\|awsv4\|digest\|api key\|oauth2\|inherit\|http\|graphql\|formUrlEncoded\|multipartForm\|text\|json\|xml\|sparql\)" contains=bruTemplateVar

" Numbers (seq, etc.).
syn match bruNumber "\(:\s*\)\zs-\?\d\+\(\.\d\+\)\?"

" Booleans.
syn keyword bruBoolean true false contained

" --- Braces and punctuation --------------------------------------------------
syn match bruBrace "[{}]"

" --- Block regions with embedded JavaScript ---------------------------------
" `script:*` and `tests` blocks contain JavaScript. Pull in the built-in
" javascript syntax so the code bodies get real JS highlighting.
syn include @bruJS syntax/javascript.vim

" A block region runs from `keyword` (optionally `:sub`) through its matching
" braces. We use a transparent region that contains everything and, for JS
" blocks, nests @bruJS.
syn region bruScriptBlock matchgroup=bruBlock
  \ start="\<script\s*:\s*\h\w*\s*{" end="}"
  \ contains=@bruJS,bruComment,bruBlockSub

syn region bruTestsBlock matchgroup=bruBlock
  \ start="\<tests\s*{" end="}"
  \ contains=@bruJS,bruComment

" Generic block: any keyword (optionally with `:sub`) followed by `{ ... }`.
syn region bruBlockRegion matchgroup=bruBlock
  \ start="\<\%(meta\|get\|post\|put\|patch\|delete\|head\|options\|headers\|params\|auth\|query\|assert\|docs\|body\|vars\)\%(\s*:\s*\h\w*\)\=\s*{"
  \ end="}"
  \ transparent
  \ contains=bruComment,bruKey,bruString,bruScalar,bruNumber,bruBoolean,bruTemplateVar,bruBrace,bruBlockSub

" --- Highlighting links ------------------------------------------------------
hi def link bruComment Comment
hi def link bruTodo Todo
hi def link bruBlock Keyword
hi def link bruBlockSub Type
hi def link bruKey Identifier
hi def link bruString String
hi def link bruScalar Constant
hi def link bruNumber Number
hi def link bruBoolean Boolean
hi def link bruTemplateVar Special
hi def link bruBrace Delimiter

let b:current_syntax = "bru"

let &cpoptions = s:cpo_save
unlet s:cpo_save
