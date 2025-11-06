# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    ['ArcSentinel.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[
        'PyQt5.sip', 'PyQt5.QtCore', 'PyQt5.QtGui', 'PyQt5.QtWidgets',
        'PyQt5.QtNetwork', 'PyQt5.QtSvg', 'PyQt5.QtPrintSupport',
        'pip', 'pip._vendor', 'pip._internal', 'pip._internal.commands',
        'pip._internal.utils', 'pip._internal.operations', 'pip._internal.models',
        'pip._internal.index', 'pip._internal.resolution', 'pip._internal.cli',
        'psutil', 'pefile', 'requests', 'chardet', 'numpy'
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

# Add dependency_installer.py and add_to_startup.py to the bundle
a.datas += [('dependency_installer.py', 'dependency_installer.py', 'DATA')]
a.datas += [('add_to_startup.py', 'add_to_startup.py', 'DATA')]

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='ArcSentinel',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='icon.ico',
)