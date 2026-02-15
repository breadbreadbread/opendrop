# Installation Guide for macOS Apple Silicon (M1/M2/M3)

This guide covers installing OpenDrop on Apple Silicon Macs running macOS 11 (Big Sur) or later.

## Prerequisites

### 1. Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Homebrew on Apple Silicon is installed in `/opt/homebrew` by default.

### 2. Install System Dependencies

```bash
# Install Python 3.10+ (recommended)
brew install python@3.10

# Install required libraries
brew install sundials
brew install boost
brew install gtk+3
brew install pygobject3
brew install open-mpi  # Optional: for parallel processing support

# Install optional camera support
brew install libdc1394  # For IEEE 1394 cameras
brew install libusbx    # For USB cameras
```

**Note:** Make sure to run `brew doctor` to ensure your Homebrew installation is healthy.

### 3. Set Up Python Environment

Create a virtual environment (recommended):

```bash
python3 -m venv opendrop-env
source opendrop-env/bin/activate
```

### 4. Install OpenDrop

#### Option A: Install from PyPI (when available)

```bash
pip install opendrop
```

#### Option B: Install from GitHub

```bash
# Install latest stable version
pip install git+https://github.com/jdber1/opendrop.git

# Or install development branch
pip install git+https://github.com/jdber1/opendrop.git@development
```

#### Option C: Install from source (for development)

```bash
# Clone the repository
git clone https://github.com/jdber1/opendrop.git
cd opendrop

# Set environment variables for Homebrew paths
export CPATH=/opt/homebrew/include
export LIBRARY_PATH=/opt/homebrew/lib
export LD_LIBRARY_PATH=/opt/homebrew/lib

# Install in development mode
pip install -e .
```

## Troubleshooting

### Issue: "library not found for -lsundials_arkode"

This occurs when the linker can't find SUNDIALS libraries. Try:

```bash
# Set library paths
export LIBRARY_PATH=/opt/homebrew/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/homebrew/lib:$LD_LIBRARY_PATH

# Or use LDFLAGS
export LDFLAGS="-L/opt/homebrew/lib"
export CPPFLAGS="-I/opt/homebrew/include"

pip install git+https://github.com/jdber1/opendrop.git
```

### Issue: "fatal error: 'arkode/arkode_erkstep.h' file not found"

This occurs when the compiler can't find SUNDIALS headers. Try:

```bash
# Set include paths
export CPATH=/opt/homebrew/include:$CPATH

pip install git+https://github.com/jdber1/opendrop.git
```

### Issue: Runtime library errors when running OpenDrop

If you get errors about missing libraries when running the application:

```bash
# Add Homebrew libraries to system library path
echo "/opt/homebrew/lib" | sudo tee /etc/ld.so.conf.d/homebrew.conf
sudo ldconfig

# Or set DYLD_LIBRARY_PATH (macOS-specific)
export DYLD_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_LIBRARY_PATH
```

### Issue: Segmentation faults

If OpenDrop crashes with a segmentation fault:

1. Make sure all Homebrew packages are installed for your architecture (arm64)
2. Reinstall problematic packages:

```bash
brew uninstall sundials boost
brew install sundials boost
```

### Issue: MPI-related errors

If you see errors about `ompi_mpi_comm_null`:

```bash
# Install OpenMPI
brew install open-mpi

# Ensure it's linked properly
brew link open-mpi
```

## Building Universal Binary Wheels

To build wheels that work on both Intel and Apple Silicon Macs:

```bash
# Install cross-compilation tools
brew install cmake

# Build universal wheel
python -m pip install --no-binary :all: --config-settings "--plat-name=universal2" opendrop
```

## Testing Your Installation

After installation, test that OpenDrop works:

```bash
# Check installation
python -c "import opendrop; print('OpenDrop installed successfully!')"

# Run the application
python -m opendrop
```

## Verification Checklist

- [ ] Homebrew is installed and working
- [ ] Python 3.10+ is installed
- [ ] All system dependencies are installed via Homebrew
- [ ] OpenDrop installs without errors
- [ ] Application launches and displays the main window
- [ ] Can load test images and perform analysis
- [ ] Camera acquisition works (if applicable)

## Additional Notes

### Python Version

Python 3.10 is recommended for Apple Silicon. Python 3.11+ may have compatibility issues with some dependencies.

### Rosetta 2

If you encounter issues, you can try running under Rosetta 2 translation:

```bash
arch -x86_64 pip install opendrop
```

However, native arm64 installation is recommended for best performance.

### Homebrew on Apple Silicon

- Path: `/opt/homebrew` (arm64 native)
- Intel compatibility: `/usr/local` (x86_64 via Rosetta 2)

Make sure you're using the correct Homebrew prefix for your architecture when setting environment variables.

## Getting Help

If you encounter issues not covered in this guide:

1. Check the [GitHub Issues](https://github.com/jdber1/opendrop/issues)
2. Search for similar problems in closed issues
3. Open a new issue with detailed information about your setup and error messages
