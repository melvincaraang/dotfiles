return {
    cmd = { 'vtsls', '--stdio' },
    root_markers = {
        'tsconfig.json',
        'package.json',
        'jsconfig.json',
        '.git',
    },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'typescript.tsx' },
    single_file_support = true,
}
