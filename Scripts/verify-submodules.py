import subprocess
import sys

def verify_submodules():
    result = subprocess.run(["git", "submodule", "status"], capture_output=True, text=True, check=True)
    lines = result.stdout.strip().splitlines()
    for line in lines:
        if line.startswith("+"):
            print(f"Error: Submodule is out of sync with pinned commit: {line}")
            sys.exit(1)
        if line.startswith("-"):
            print(f"Error: Submodule is uninitialized: {line}")
            sys.exit(1)
    print("All submodules match their pinned commits")

if __name__ == "__main__":
    verify_submodules()
