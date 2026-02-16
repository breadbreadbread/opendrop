import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


def detect_homebrew_prefix():
    if sys.platform != 'darwin':
        return None

    default_prefix = '/opt/homebrew' if platform.machine() == 'arm64' else '/usr/local'
    brew = shutil.which('brew')
    if not brew:
        return default_prefix

    try:
        result = subprocess.run([brew, '--prefix'], capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError:
        return default_prefix

    prefix = result.stdout.strip()
    return prefix or default_prefix


def library_present(path, name):
    return any(path.glob(f"lib{name}*"))


def find_sundials_paths(homebrew_prefix):
    include_candidates = [Path('/usr/include'), Path('/usr/local/include')]
    lib_candidates = [
        Path('/usr/lib'),
        Path('/usr/lib/x86_64-linux-gnu'),
        Path('/usr/local/lib'),
    ]

    if homebrew_prefix:
        include_candidates.append(Path(homebrew_prefix) / 'include')
        lib_candidates.append(Path(homebrew_prefix) / 'lib')

        cellar = Path(homebrew_prefix) / 'Cellar' / 'sundials'
        if cellar.exists():
            include_candidates.extend(cellar.glob('*/include'))
            lib_candidates.extend(cellar.glob('*/lib'))

    include_dir = next(
        (path for path in include_candidates if (path / 'arkode' / 'arkode_erkstep.h').exists()),
        None,
    )

    required_libs = ['sundials_arkode', 'sundials_nvecserial']
    lib_dir = next(
        (
            path
            for path in lib_candidates
            if path.exists() and all(library_present(path, lib) for lib in required_libs)
        ),
        None,
    )

    return include_dir, lib_dir


platform_name = sys.platform
if platform_name == 'darwin':
    detected_platform = 'darwin'
elif platform_name.startswith('linux'):
    detected_platform = 'posix'
else:
    detected_platform = platform_name

system_arch = platform.machine()
homebrew_prefix = detect_homebrew_prefix()

ccflags = ['-O3', '-std=c++14']
if detected_platform == 'darwin' and system_arch in {'arm64', 'x86_64'}:
    ccflags.extend(['-arch', system_arch])

env = Environment(
    NAME='opendrop',
    PACKAGE_METADATA={
        'Requires-Python': '>=3.6',
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

mpich_default = '/usr/include/mpich-x86_64/'
boost_default = '/usr/include'
if detected_platform == 'darwin' and homebrew_prefix:
    mpich_default = os.path.join(homebrew_prefix, 'include')
    boost_default = os.path.join(homebrew_prefix, 'include')

mpich_dir = os.getenv('MPICH_DIR', mpich_default)
boost_include_dir = os.getenv('BOOST_INCLUDE_DIR', boost_default)

sundials_include_dir, sundials_lib_dir = find_sundials_paths(homebrew_prefix)

sundials_libs = ['sundials_arkode', 'sundials_nvecserial']
if sundials_lib_dir and library_present(sundials_lib_dir, 'sundials_core'):
    sundials_libs.insert(0, 'sundials_core')

env['SUNDIALS_LIBS'] = sundials_libs

include_paths = [env.Dir('include'), boost_include_dir, mpich_dir]
if sundials_include_dir:
    include_paths.append(sundials_include_dir)

env.Append(ENV={'PATH': os.environ['PATH']}, CPPPATH=include_paths)
if sundials_lib_dir:
    env.Append(LIBPATH=[sundials_lib_dir])

AddOption(
    '--build-dir',
    dest='build_dir',
    default=env.Dir('build'),
    metavar='DIR',
    help='Set DIR as the build directory.',
)

env['BUILDDIR'] = GetOption('build_dir')

if detected_platform == 'darwin' and sundials_lib_dir:
    env.Append(RPATH=[sundials_lib_dir], SHLIB_INSTALL_NAME='$TARGET')

env.Tool('gitversion')
env.Tool('python')
env.Tool('pydist')

package_files = SConscript('opendrop/SConscript', exports='env')

if detected_platform == 'darwin':
    platform_tag = 'macosx_11_0_arm64' if system_arch == 'arm64' else 'macosx_10_9_x86_64'
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
