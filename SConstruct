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
    # Common Homebrew SUNDIALS paths
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
    
    for path in sundials_paths:
        if path.name == 'include' and path.exists():
            include_dir = path
            break
        elif 'Cellar' in str(path):
            matching = list(path.parent.glob('sundials/*/include'))
            if matching:
                include_dir = matching[0]
                break
    
    for path in lib_paths:
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

# Set up compiler flags based on architecture
ccflags = ['-O3', '-std=c++14']
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

# Build include and library paths
include_paths = [env.Dir('include'), boost_include_dir, mpich_dir]
if sundials_include_dir:
    include_paths.append(sundials_include_dir)

library_paths = []
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
if env['PLATFORM'] == 'darwin':
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
if env['PLATFORM'] == 'darwin':
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
