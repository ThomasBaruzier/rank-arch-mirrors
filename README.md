# Mirrors

A bash script to find the best mirrors

<br><img src="https://github.com/user-attachments/assets/86d0bb0b-e120-4062-8b11-aa1ef3364488" width="720"><br>

### Features

- Two-stage testing: Latency + download speed
- ArchLinux, ArchLinuxArm, Artix Linux support
- Multithreaded queries for latency checks
- See download speed, latency, and a combined score
- Backs up the current mirrorlist and asks for confirmation first

### Get Started  

1. Download and run:
   ```bash  
   curl -O https://raw.githubusercontent.com/ThomasBaruzier/rank-arch-mirrors/refs/heads/main/rank.sh && chmod +x rank.sh && ./rank.sh && rm rank.sh
   ```

2. When done, the script will display its findings. Enter 'y' to apply the new mirrorlist.

### To Know  
- Requires `curl`, `grep`, `sed`, `awk`, `pacman`.  
- Your original mirrorlist is backed up to `/etc/pacman.d/mirrorlist.bkp`.  
