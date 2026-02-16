import os
import platform
import subprocess
from pathlib import Path

def detect_homebrew_prefix():
    """Detect Homebrew installation prefix based on architecture"""
    system_arch = platform.machine()
    if system_arch == 'arm64':  # Apple Silicon
        # Check for Apple Silicon Homebrew
        homebrew_arm = Path('/opt/homebrew')
        if homebrew_arm.exists():
            return str(homebrew_arm)
    elif system_arch == 'x86_64':  # Intel Mac
        # Check for Intel Homebrew
        homebrew_intel = Path('/usr/local')
        if (homebrew_intel / 'bin/brew').exists():
            return str(homebrew_intel)
    
    # Fallback: try to use brew --prefix
    try:
        result = subprocess.run(['brew', '--prefix'], 
                              capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return '/usr/local'  # Default fallback

def find_sundials_paths(homebrew_prefix):
    """Find SUNDIALS include and lib directories"""
    # Linux system paths first (most common)
    linux_paths = [
        Path('/usr/include'),
        Path('/usr/local/include'),
    ]
    
    lib_linux_paths = [
        Path('/usr/lib'),
        Path('/usr/lib/x86_64-linux-gnu'),
        Path('/usr/local/lib'),
        Path('/usr/local/lib/x86_64-linux-gnu'),
    ]
    
    # Homebrew SUNDIALS paths (macOS)
    sundials_paths = [
        Path(homebrew_prefix) / 'include',
        Path(homebrew_prefix) / 'Cellar/sundials' / '*/include',
        Path('/usr/include'),
    ]
    
    lib_paths = [
        Path(homebrew_prefix) / 'lib',
        Path(homebrew_prefix) / 'Cellar/sundials' / '*/lib',
        Path('/usr/lib'),
    ]
    
    # Find the actual paths (handle versioned Cellar paths)
    include_dir = None
    lib_dir = None
    
    # First try Linux paths (they're usually more standard)
    for path in linux_paths:
        arkode_header = path / 'arkode' / 'arkode_erkstep.h'
        if arkode_header.exists():
            include_dir = path
            break
    
    # If not found, try Homebrew paths
    if not include_dir:
        for path in sundials_paths:
            if path.name == 'include' and path.exists():
                include_dir = path
                break
            elif 'Cellar' in str(path):
                matching = list(path.parent.glob('sundials/*/include'))
                if matching:
                    include_dir = matching[0]
                    break
    
    # Find library directory
    for path in lib_linux_paths + lib_paths:
        if path.name == 'lib' and path.exists():
            lib_dir = path
            break
        elif 'Cellar' in str(path):
            matching = list(path.parent.glob('sundials/*/lib'))
            if matching:
                lib_dir = matching[0]
                break
    
    return include_dir, lib_dir

# Detect system architecture and Homebrew prefix
system_arch = platform.machine()
homebrew_prefix = detect_homebrew_prefix()

print(f"Detected architecture: {system_arch}")
print(f"Homebrew prefix: {homebrew_prefix}")

# Detect platform - do this before Environment creation
import sys
platform_name = sys.platform
if platform_name == 'darwin':
    detected_platform = 'darwin'
elif platform_name.startswith('linux'):
    detected_platform = 'posix'
else:
    detected_platform = platform_name

# Set up compiler flags based on architecture
ccflags = ['-O3', '-std=c++14']

# Only add architecture flags on macOS (where they're supported)
if detected_platform == 'darwin':
    if system_arch == 'arm64':
        ccflags.extend(['-arch', 'arm64'])
    elif system_arch == 'x86_64':
        ccflags.extend(['-arch', 'x86_64'])

env = Environment(
    NAME='opendrop',
    PACKAGE_METADATA={
        'Requires-Python': '>=3.8',  # Updated minimum for better Apple Silicon support
        'Provides-Extra': 'genicam',
        'Requires-Dist': File('requirements.txt').get_text_contents().splitlines(),
        'Home-page': 'https://github.com/jdber1/opendrop',
        'Classifier': [
            'License :: OSI Approved :: GNU General Public License v3 (GPLv3)',
        ],
    },
    BUILDDIR='./build',
    CCFLAGS=ccflags,
)

# Dynamic path configuration
mpich_dir = os.getenv('MPICH_DIR', os.path.join(homebrew_prefix, 'include'))
boost_include_dir = os.getenv('BOOST_INCLUDE_DIR', os.path.join(homebrew_prefix, 'Cellar/boost'))
sundials_include_dir, sundials_lib_dir = find_sundials_paths(homebrew_prefix)

print(f"Detected SUNDIALS include: {sundials_include_dir}")
print(f"Detected SUNDIALS lib: {sundials_lib_dir}")

# Build include and library paths
include_paths = [env.Dir('include')]
if detected_platform != 'darwin':
    # On Linux, include paths for system libraries
    include_paths.extend(['/usr/include', '/usr/local/include'])
include_paths.extend([boost_include_dir, mpich_dir])
if sundials_include_dir:
    include_paths.append(sundials_include_dir)

library_paths = []
if detected_platform != 'darwin':
    # On Linux, add multiarch library paths
    library_paths.extend(['/usr/lib', '/usr/lib/x86_64-linux-gnu', '/usr/local/lib'])
if sundials_lib_dir:
    library_paths.append(sundials_lib_dir)

env.Append(CPPPATH=include_paths)
if library_paths:
    env.Append(LIBPATH=library_paths)


AddOption(
    '--build-dir',
    dest='build_dir',
    default=env.Dir('build'),
    metavar='DIR',
    help='Set DIR as the build directory.',
)

env['BUILDDIR'] = GetOption('build_dir')

# Add runtime library path configuration for macOS
if detected_platform == 'darwin':
    # Configure runtime library paths for dynamic libraries
    env.Append(
        ENV={'PATH': os.environ['PATH']},
        # Add proper RPATH for SUNDIALS libraries on macOS
        RPATH=[sundials_lib_dir] if sundials_lib_dir else [],
        # Set install name directive for shared libraries
        SHLIB_INSTALL_NAME='$TARGET',
    )
else:
    env.Append(
        ENV={'PATH': os.environ['PATH']},
        CPPPATH=[env.Dir('include')],
    )

env.Tool('gitversion')
env.Tool('python')
env.Tool('pydist')

package_files = SConscript('opendrop/SConscript', exports='env')

# Determine platform tag based on architecture
if detected_platform == 'darwin':
    if system_arch == 'arm64':
        platform_tag = 'macosx_11_0_arm64'
    else:
        platform_tag = 'macosx_10_9_x86_64'
else:
    platform_tag = env['PYTHONPLATFORM']

wheel = env.WheelPackage(
    '$BUILDDIR',
    package_files,
    packages={'opendrop': './opendrop'},
    python_tag='cp%s%s' % tuple(env['PYTHONVERSION'].split('.')[:2]),
    abi_tag='abi3',
    platform_tag=platform_tag,
)
Alias('bdist_wheel', wheel)

c_tests = SConscript('tests/c/SConscript', exports='env')
Alias('tests', c_tests)
