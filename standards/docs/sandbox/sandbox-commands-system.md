# Z.ai Sandbox Commands — System, Network & Services

> On-demand reference. Part of the Z.ai Sandbox Command Cheatsheet (see `sandbox-commands-cheatsheet.md` for the index).

---

## Table of Contents

6. [Network and Internet](#6-network-and-internet)
7. [System and Processes](#7-system-and-processes)
8. [Users and Permissions](#8-users-and-permissions)
9. [Disks and File Systems](#9-disks-and-file-systems)
10. [System Services (systemd)](#10-system-services-systemd)

---

## 6. Network and Internet

Commands for network operations: file downloads, connection diagnostics, DNS queries, and traffic monitoring. In the sandbox, network capabilities are limited by security policies, but basic tools work.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `curl` | Universal HTTP client. Supports HTTP/HTTPS/FTP and dozens of other protocols. Flag `-o` - save to file, `-s` - silent mode, `-X POST` - method, `-d` - data, `-H` - headers. | `curl -s https://api.example.com/data` | HTTP requests, downloading |
| `wget` | File downloader from the internet. Better than curl for recursive site downloading. Flag `-q` - quiet, `-O` - output filename, `-c` - resume. | `wget -q https://example.com/file.zip` | Download a file |
| `ping` | Checks host availability via ICMP echo. Flag `-c 4` - 4 packets. | `ping -c 4 google.com` | Check host connectivity |
| `traceroute` | Shows the packet route to a host (all intermediate nodes). | `traceroute google.com` | Route diagnostics |
| `dig` | DNS queries. Shows IP addresses, MX records, NS, and other DNS data. | `dig example.com A` | DNS diagnostics |
| `nslookup` | Simple DNS query (deprecated but convenient). | `nslookup example.com` | Quick DNS query |
| `host` | Compact DNS query. Shorter output than dig. | `host example.com` | Get IP by domain |
| `ip` | Powerful network configuration utility (replacement for ifconfig/route). Subcommands: `addr`, `link`, `route`, `neigh`. | `ip addr show` | Network configuration and diagnostics |
| `ifconfig` | Shows/configures network interfaces (deprecated but popular). | `ifconfig eth0` | Network interface information |
| `ss` | Socket statistics (replacement for netstat). Flag `-t` - TCP, `-u` - UDP, `-l` - listening. | `ss -tlnp` | Check open ports |
| `netstat` | Shows network connections, routing tables, interface statistics. | `netstat -tlnp` | Check ports and connections |
| `arp` | Shows/manages the ARP table (IP to MAC mapping). | `arp -a` | View ARP table |
| `bridge` | Manages network bridges in Linux. | `bridge link show` | Configure network bridge |
| `rdma` | Manages RDMA connections (high-performance networks). | `rdma link show` | RDMA diagnostics |
| `nc` (netcat) | Swiss army knife for TCP/UDP. Can listen on a port, transfer data. | `nc -l 8080` | Simple TCP/UDP client/server |

---

---

## 7. System and Processes

Commands for monitoring and managing the operating system and running processes. Used for diagnostics, resource management, and background tasks.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `ps` | Shows a snapshot of running processes. Flag `aux` - all processes with details. | `ps aux` | Process list |
| `top` | Interactive real-time process monitor. Shows CPU, memory, PID. | `top` | Load monitoring |
| `kill` | Sends a signal to a process. Default SIGTERM (15). Flag `-9` - SIGKILL (force). | `kill -9 12345` | Terminate a process |
| `pkill` | Kills processes by name or pattern. | `pkill -f "node server"` | Kill process by name |
| `pgrep` | Finds PIDs by process name. Flag `-f` - search in full command line. | `pgrep -f python` | Find PID |
| `pidof` | Shows PID by exact process name. | `pidof nginx` | Get PID by name |
| `pidwait` | Waits for a process to finish. | `pidwait 12345` | Wait for completion |
| `nohup` | Runs a command immune to session disconnection. Output is redirected to `nohup.out`. | `nohup python3 train.py &` | Run a process in background |
| `bg` | Resumes a suspended process in background mode. | `bg %1` | Continue task in background |
| `fg` | Brings a background process to the foreground. | `fg %1` | Return task to screen |
| `jobs` | Shows background tasks of the current session. | `jobs -l` | List background tasks |
| `wait` | Waits for a background process to finish. | `wait $PID` | Wait for completion |
| `sleep` | Pauses execution for N seconds. Supports `s`, `m`, `h`, `d`. | `sleep 5` | Pause in script |
| `watch` | Periodically runs a command, showing results in real time. | `watch -n 2 "ps aux \| grep python"` | Monitor changes |
| `time` | Measures command execution time (real, user, sys). | `time python3 script.py` | Measure performance |
| `timeout` | Runs a command with a time limit. | `timeout 60 python3 script.py` | Limit execution time |
| `nice` | Runs a process with modified priority (-20 to 19, lower = higher priority). | `nice -n 10 heavy_task.sh` | Lower task priority |
| `renice` | Changes the priority of an already running process. | `renice -n 5 -p 12345` | Change priority |
| `uname` | Shows system information. Flag `-a` - all. | `uname -a` | What system? |
| `hostname` | Shows/sets the hostname. | `hostname` | Machine name |
| `whoami` | Shows the current username. | `whoami` | Who am I? |
| `id` | Shows UID, GID, and user groups. | `id` | User identification |
| `who` | Shows logged-in users. | `who` | Who is in the system |
| `w` | Shows logged-in users and what they are doing. | `w` | Who and what are they doing |
| `uptime` | Shows system uptime and average load. | `uptime` | How long has the server been running |
| `free` | Shows RAM usage. Flag `-h` - human readable. | `free -h` | How much memory is free |
| `vmstat` | Shows virtual memory, process, and CPU statistics. | `vmstat 1 5` | Memory and CPU monitoring |
| `dmesg` | Shows kernel messages (boot, drivers, hardware errors). | `dmesg \| tail -20` | Kernel diagnostics |
| `env` | Shows environment variables. | `env` | View variables |
| `printenv` | Outputs environment variables. Can specify a specific one. | `printenv PATH` | Get variable value |
| `export` | Exports a variable to child processes. | `export MY_VAR="value"` | Set environment variable |
| `set` | Shows all shell variables and functions. | `set` | All shell variables |
| `unset` | Removes an environment variable or function. | `unset MY_VAR` | Remove variable |
| `alias` | Creates a command alias. | `alias ll='ls -la'` | Create command shortcut |
| `unalias` | Removes an alias. | `unalias ll` | Remove shortcut |
| `history` | Shows command history. | `history \| tail -20` | What did I do before? |
| `source` | Executes a script in the current shell (no new process). | `source venv/bin/activate` | Activate virtual environment |
| `date` | Shows/sets date and time. | `date +%Y-%m-%d` | Current date |
| `lsof` | Shows open files and sockets of processes. | `lsof -i :8080` | Who is using the port? |
| `pmap` | Shows the memory map of a process. | `pmap 12345` | Process memory usage |
| `slabtop` | Interactive kernel slab cache monitor. | `slabtop` | Kernel cache monitoring |
| `taskset` | Pins a process to specific CPU cores. | `taskset -c 0,1 python3 script.py` | Limit CPU for process |
| `chrt` | Changes process scheduling policy (realtime, etc.). | `chrt -f -p 50 12345` | Configure scheduling |
| `ionice` | Sets I/O priority for a process. | `ionice -c 3 cp bigfile /backup/` | Lower I/O priority |
| `flock` | Manages file locks for process synchronization. | `flock /tmp/lockfile command` | Prevent parallel access |
| `prlimit` | Shows/sets resource limits for a process. | `prlimit --nofile=1024:1024 -p 12345` | Limit process resources |

---

---

## 8. Users and Permissions

User, group, and access rights management. In the sandbox, most commands require root privileges.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `su` | Switches to another user (default root). | `su - username` | Become another user |
| `sudo` | Executes a command as superuser. | `sudo apt install pkg` | Execute with root rights |
| `useradd` | Creates a new user. | `useradd -m -s /bin/bash newuser` | Create a user |
| `userdel` | Deletes a user. Flag `-r` - delete home directory. | `userdel -r olduser` | Delete a user |
| `usermod` | Modifies user parameters. | `usermod -aG docker username` | Add to group |
| `groupadd` | Creates a new group. | `groupadd developers` | Create a group |
| `groupdel` | Deletes a group. | `groupdel oldgroup` | Delete a group |
| `groupmod` | Modifies group parameters. | `groupmod -n newname oldname` | Rename a group |
| `passwd` | Changes user password. | `passwd username` | Change password |
| `groups` | Shows the groups a user belongs to. | `groups username` | Which groups is the user in |
| `chage` | Manages password expiration. | `chage -l username` | Password policy |
| `chfn` | Changes Finger information (full name, phone). | `chfn -f "John Doe"` | Update user data |
| `chsh` | Changes the login shell. | `chsh -s /bin/zsh` | Change shell |
| `newgrp` | Switches the primary group in the current session. | `newgrp docker` | Change active group |
| `sg` | Executes a command as another group. | `sg docker -c "docker ps"` | Run as group |
| `visudo` | Safely edits the sudoers file with syntax checking. | `sudo visudo` | Configure sudo rights |
| `last` | Shows login history. | `last -10` | Who logged in and when |
| `login` | Initiates a new login session. | `login username` | Log into the system |

---

---

## 9. Disks and File Systems

Disk partition management, file system mounting, checking, and formatting. In the sandbox, most operations are restricted.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `mount` | Mounts a file system. | `mount /dev/sda1 /mnt/data` | Connect a disk |
| `umount` | Unmounts a file system. | `umount /mnt/data` | Disconnect a disk |
| `lsblk` | Shows block devices (disks, partitions). | `lsblk` | List disks and partitions |
| `blkid` | Shows UUID and file system type of block devices. | `blkid` | Identify partitions |
| `findmnt` | Shows mounted file systems as a tree. | `findmnt` | List mounts |
| `mkfs` | Creates a file system (formats a partition). | `mkfs.ext4 /dev/sda1` | Format a disk |
| `mkswap` | Creates a swap partition. | `mkswap /dev/sda2` | Create swap |
| `swapoff` | Disables swap. | `swapoff /dev/sda2` | Disable swap |
| `swapon` | Enables swap. | `swapon /dev/sda2` | Enable swap |
| `fsck` | Checks and repairs a file system. | `fsck /dev/sda1` | Check disk for errors |
| `fstrim` | Frees unused blocks on SSD. | `sudo fstrim -av` | Optimize SSD |
| `losetup` | Configures loop devices (mounting ISO as disk). | `losetup /dev/loop0 image.iso` | Mount ISO |
| `dd` | Byte-by-byte data copying. Caution - can erase a disk! | `dd if=image.iso of=/dev/sdb bs=4M` | Create bootable USB |
| `df` | (see section 1) | | |
| `du` | (see section 1) | | |
| `partx` | Manages partitions of a block device. | `partx -l /dev/sda` | List partitions |
| `wipefs` | Removes file system signatures (clears headers). | `wipefs -a /dev/sdb` | Clean a disk |
| `fallocate` | Reserves space for a file without writing data. | `fallocate -l 1G swapfile` | Create a file of specified size |
| `sync` | Flushes file system buffers to disk. | `sync` | Guarantee data write |

---

---

## 10. System Services (systemd)

Service management, logs, and system configuration through systemd - the standard init system in modern Linux distributions.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `systemctl` | Manages systemd services. `start`, `stop`, `restart`, `status`, `enable`, `disable`. | `systemctl status nginx` | Service management |
| `journalctl` | Views systemd journal logs. Flag `-u` - by service, `-f` - follow, `--since` - from date. | `journalctl -u nginx --since today` | System logs |
| `systemd-analyze` | Analyzes boot time and service dependencies. | `systemd-analyze blame` | What slows down boot? |
| `systemd-run` | Runs a command as a temporary systemd service. | `systemd-run --unit=mytask python3 script.py` | Run as a service |
| `systemd-notify` | Sends service status notifications. | `systemd-notify --ready` | Signal readiness |
| `systemd-cat` | Redirects output to systemd journal. | `systemd-cat echo "hello"` | Write to system log |
| `systemd-cgls` | Shows the control groups (cgroups) tree. | `systemd-cgls` | Process hierarchy |
| `systemd-cgtop` | Interactive cgroups resource monitor (like top for cgroups). | `systemd-cgtop` | Resource monitoring |
| `hostnamectl` | Manages hostname, timezone, localization. | `hostnamectl set-hostname myserver` | Configure host |
| `localectl` | Manages keyboard layout and locale. | `localectl set-locale LANG=en_US.UTF-8` | Configure locale |
| `timedatectl` | Manages date, time, timezone, NTP. | `timedatectl set-timezone Europe/Moscow` | Configure time |
| `loginctl` | Manages user sessions. | `loginctl list-sessions` | List sessions |
| `networkctl` | Manages network interfaces via systemd-networkd. | `networkctl status` | Network status |

---


*(Part of the Z.ai Sandbox Command Cheatsheet — see `sandbox-commands-cheatsheet.md` for the full index.)*
