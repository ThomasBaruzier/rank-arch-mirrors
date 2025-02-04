# Rank Arch Mirrors

This script hunts down the fastest mirrors tailored to your connection by testing both latency *and* actual download speeds.

---

### Why another mirror raking tool?
- Two-stage testing: First filters mirrors by latency, then stress-tests the fastest candidates with real packages.
- ArchLinux and ArchLinuxArm support: Works on both x86_64 and ARM devices.
- Tuned for speed: Multithreaded queries for latency testing.
- Transparent results: See download speed, latency, and a combined score before applying changes.
- Safety first: Backs up your existing mirrorlist and asks for confirmation before making changes.

---

### Get Started  
1. Download and run:
   ```bash  
   curl -O https://raw.githubusercontent.com/ThomasBaruzier/rank-arch-mirrors/refs/heads/main/rank.sh
   chmod +x rank.sh
   ./rank.sh
   ```

2. When done, the script will display its findings. Enter 'y' to apply the new mirrorlist.

---

### Things to Know  
- Requires `curl`, `grep`, `sed`, `awk`, `pacman`.  
- Your original mirrorlist is backed up to `/etc/pacman.d/mirrorlist.bkp`.  

---

### If Something Breaks  
- "No mirrors available": Check your internet or open an issue 
- Permission errors: Run with `sudo` if the script struggles to write to `/etc/pacman.d/`.  

---

*Made for Arch users, by someone who hates waiting for packages to download.*
