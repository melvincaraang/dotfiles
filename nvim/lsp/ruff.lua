return {
    cmd = { 'ruff', 'check' },
    root_markers = {
        'server.py',
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
        'pyrightconfig.json',
        '.git',
    },
    filetypes = { 'python' },
    settings = {
    }
}
