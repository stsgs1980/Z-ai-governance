# Z.ai Sandbox Commands — File, Text & Archiving

> On-demand reference. Part of the Z.ai Sandbox Command Cheatsheet (see `sandbox-commands-cheatsheet.md` for the index).

---

## Table of Contents

1. [File Operations](#1-file-operations)
2. [Viewing and Searching Files](#2-viewing-and-searching-files)
3. [Text Search and Filtering](#3-text-search-and-filtering)
4. [Text Processing](#4-text-processing)
5. [Archiving and Compression](#5-archiving-and-compression)

---

## 1. File Operations

Commands for creating, copying, moving, deleting, and managing files and directories. These are the foundation of Linux work -- without these commands, no task can be performed.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `ls` | Lists files and directories. Without flags - only names. With `-l` - detailed info (permissions, owner, size, date). With `-a` - shows hidden files (start with `.`). | `ls -la /home/z/` | Need to view directory contents |
| `cp` | Copies files or directories. Flag `-r` - recursive (for folders). Flag `-p` - preserves permissions and date. | `cp -r src/ backup/` | Copy a file/folder |
| `mv` | Moves or renames files/directories. Works instantly within the same file system. | `mv old.txt new.txt` | Rename or move |
| `rm` | Deletes files. Flag `-r` - recursive (for folders). Flag `-f` - force, no confirmation. **Caution: cannot be undone!** | `rm -rf temp/` | Delete files or folders |
| `mkdir` | Creates directories. Flag `-p` - creates all intermediate directories. | `mkdir -p /home/z/project/src` | Create a folder |
| `rmdir` | Deletes an empty directory. Does not work if files exist inside. | `rmdir empty_dir/` | Delete an empty folder |
| `touch` | Creates an empty file or updates the modification date of an existing file. | `touch newfile.txt` | Create an empty file |
| `ln` | Creates a link to a file. Flag `-s` - symbolic (soft) link, without flag - hard link. | `ln -s /path/target link_name` | Create a shortcut/link |
| `chmod` | Changes file permissions. Supports numeric (755) and symbolic (u+x) formats. | `chmod 755 script.sh` | Set permissions |
| `chown` | Changes file owner and group. Requires sudo for system files. | `chown user:group file.txt` | Change file owner |
| `chgrp` | Changes the group owner of a file. | `chgrp developers project/` | Change file group |
| `install` | Copies a file while setting permissions and owner. Convenient for installing scripts. | `install -m 755 script.sh /usr/local/bin/` | Install a file with proper permissions |
| `truncate` | Shrinks or extends a file to the specified size. | `truncate -s 0 log.txt` | Clear a file without deleting it |
| `link` | Creates a hard link (similar to `ln` without `-s`). | `link file.txt hardlink.txt` | Create a hard link |
| `unlink` | Removes one link to a file. If it's the last one, the file is deleted. | `unlink hardlink.txt` | Remove a link |
| `rename.ul` | Renames files by pattern (util-linux utility). | `rename.ul .txt .bak *.txt` | Bulk rename |
| `realpath` | Outputs the full absolute path, resolving all symbolic links. | `realpath ./link` | Get the real path |
| `readlink` | Shows where a symbolic link points. Flag `-f` - recursive. | `readlink -f /usr/bin/python3` | Where does the link point |
| `basename` | Extracts the file name from a full path. | `basename /home/z/file.txt` -> `file.txt` | Get just the file name |
| `dirname` | Extracts the directory path from a full path. | `dirname /home/z/file.txt` -> `/home/z` | Get just the path |
| `stat` | Shows detailed file info: size, inode, permissions, timestamps. | `stat script.sh` | Detailed file information |
| `file` | Determines file type by content, not by extension. | `file unknown_data` | What type of file is this |
| `tree` | Shows directory structure as a tree. Flag `-L 2` - depth 2 levels. | `tree -L 2 /home/z/` | Visualize folder structure |
| `which` | Shows the full path to a command's executable. | `which python3` | Where is the command located |
| `whereis` | Finds binary, sources, and man page for a command. | `whereis gcc` | Find all files related to a command |
| `du` | Shows file and directory sizes. Flag `-h` - human readable, `-s` - total. | `du -sh /home/z/` | How much space does a folder take |
| `df` | Shows disk space usage. Flag `-h` - human readable. | `df -h` | How much free disk space |
| `pathchk` | Checks file name validity and portability. | `pathchk "my file.txt"` | Check file name validity |
| `mktemp` | Creates a temporary file or directory with a unique name. | `mktemp /tmp/data.XXXXXX` | Create a safe temporary file |
| `mkfifo` | Creates a named pipe (FIFO) for inter-process communication. | `mkfifo /tmp/mypipe` | Set up a pipe between processes |

---

---

## 2. Viewing and Searching Files

Commands for reading file contents and finding files in the file system. Used constantly for navigation, log analysis, and finding needed data.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `cat` | Outputs the entire file content. Not suitable for large files. With `-n` adds line numbers. | `cat config.yaml` | Read a small file |
| `head` | Outputs the first N lines of a file (default 10). Flag `-n 20` - 20 lines. | `head -n 20 log.txt` | View the beginning of a file |
| `tail` | Outputs the last N lines of a file. Flag `-f` - follow the file in real time. | `tail -f /var/log/syslog` | Monitor logs in real time |
| `less` | Paginated file viewer with scrolling, search (`/pattern`), and navigation. | `less large_file.log` | Read a large file |
| `more` | Simple paginated viewer (predecessor of `less`). No search or upward scrolling. | `more readme.txt` | Simple viewing |
| `wc` | Counts lines, words, and bytes. Flag `-l` - only lines, `-w` - words, `-c` - bytes. | `wc -l data.csv` | How many lines in a file |
| `find` | Powerful file search by name, type, size, date, permissions. Supports executing commands on found files. | `find /home -name "*.py" -mtime -7` | Find files by criteria |
| `nl` | Numbers file lines (similar to `cat -n`, but with formatting options). | `nl script.sh` | Output file with line numbers |
| `tee` | Reads from stdin and writes to both stdout and a file. Flag `-a` - append, don't overwrite. | `echo "log entry" \| tee -a log.txt` | Output and save simultaneously |
| `xargs` | Takes lines from stdin and passes them as arguments to a command. Flag `-I{}` - substitution template. | `find . -name "*.tmp" \| xargs rm` | Pipe output of one command to another |
| `od` | Outputs file content in octal, hexadecimal, or other format. | `od -x binary.dat` | View a binary file |
| `cksum` | Computes CRC checksum and file size. | `cksum data.bin` | Verify file integrity |
| `md5sum` | Computes MD5 hash of a file. Used for integrity verification. | `md5sum image.iso` | Check if file is corrupted |
| `sha256sum` | Computes SHA-256 hash. More reliable than MD5 for integrity checking. | `sha256sum archive.tar.gz` | Reliable integrity check |
| `sha512sum` | Computes SHA-512 hash. The most reliable of the family. | `sha512sum backup.tar` | Maximum integrity check |

---

---

## 3. Text Search and Filtering

Tools for finding text patterns in files and data streams. This is a key skill for log analysis, data processing, and debugging.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `grep` | Searches lines by regular expression. Flag `-r` - recursive, `-i` - case insensitive, `-n` - with line numbers. | `grep -rn "ERROR" /var/log/` | Find text in files |
| `egrep` | Alias for `grep -E` - extended regular expressions (no escaping for `+`, `?`, `|`). | `egrep "error\|warn" log.txt` | Search with extended regex |
| `fgrep` | Alias for `grep -F` - fixed string search, no regex. Faster for simple search. | `fgrep "exact string" *.txt` | Fast exact string search |
| `rg` | **ripgrep** - ultra-fast grep replacement. Recursive by default, respects `.gitignore`. | `rg "TODO" --type py` | Fast search in projects |
| `sed` | Stream editor. Replace, delete, insert lines. Flag `-i` - edit file in place. | `sed -i 's/old/new/g' file.txt` | Bulk text replacement in files |
| `awk` | Text processing language. More powerful than sed - supports variables, conditions, loops. | `awk '{print $1, $3}' data.csv` | Tabular data processing |
| `mawk` | Fast AWK implementation. POSIX AWK compatible, but faster than gawk. | `mawk -F, '{sum+=$2} END{print sum}' data.csv` | Fast large file processing |
| `sort` | Sorts lines. Flag `-n` - numeric, `-r` - reverse, `-k2` - by 2nd column, `-u` - unique. | `sort -rn -k2 scores.txt` | Sort data |
| `uniq` | Removes duplicate adjacent lines. Usually used after `sort`. Flag `-c` - count occurrences. | `sort data.txt \| uniq -c \| sort -rn` | Count element frequency |
| `cut` | Cuts columns or fields from lines. Flag `-d` - delimiter, `-f` - field number. | `cut -d: -f1 /etc/passwd` | Extract a column from a table |
| `tr` | Replaces or deletes characters. Supports ranges and classes. | `tr '[:lower:]' '[:upper:]' < file.txt` | Character transformation |
| `paste` | Merges lines from multiple files horizontally. | `paste names.txt ages.txt` | Glue files by columns |
| `column` | Formats text into columns. Flag `-t` - auto alignment, `-s` - delimiter. | `column -t -s: data.txt` | Pretty table output |
| `comm` | Compares two sorted files. Columns: only in 1st, only in 2nd, in both. | `comm -23 file1.txt file2.txt` | Find unique lines |
| `join` | Merges lines from two files by a common field (similar to SQL JOIN). | `join -t, file1.csv file2.csv` | Join data from two files |
| `diff` | Compares files line by line. Flag `-u` - unified format (like in git). | `diff -u old.txt new.txt` | Find differences between files |
| `sdiff` | Shows two files side by side with difference markers. | `sdiff file1.txt file2.txt` | Side-by-side comparison |
| `diff3` | Compares three files simultaneously (for three-way merge). | `diff3 mine.txt base.txt theirs.txt` | Resolve merge conflicts |
| `cmp` | Byte-by-byte comparison of two files. Shows the first difference. | `cmp file1.bin file2.bin` | Quick identity check |
| `expand` | Replaces tabs with spaces. | `expand -t 4 code.py` | Convert tabs to spaces |
| `unexpand` | Replaces spaces with tabs. | `unexpand -t 4 code.py` | Convert spaces to tabs |
| `fmt` | Formats text by paragraph width. | `fmt -w 80 readme.txt` | Justify text width |
| `fold` | Wraps long lines to specified width. | `fold -w 72 long_text.txt` | Wrap long lines |
| `pr` | Formats text for printing: headers, page numbering, columns. | `pr -d -h "Report" data.txt` | Prepare text for printing |
| `rev` | Reverses lines character by character. | `echo "hello" \| rev` -> `olleh` | Invert text |
| `tac` | Outputs file lines in reverse order (like `cat` backwards). | `tac log.txt` | Read file bottom to top |
| `seq` | Generates a sequence of numbers. | `seq 1 10` -> 1,2,...,10 | Create a numeric sequence |
| `shuf` | Randomly permutes lines. | `shuf names.txt` | Shuffle data |
| `split` | Splits a file into parts. Flag `-l 1000` - by 1000 lines. | `split -l 1000 bigfile.csv part_` | Split a large file |
| `csplit` | Splits a file by context (by pattern, not by line count). | `csplit file.txt '/^CHAPTER/' '{*}'` | Split file by chapters |

---

---

## 4. Text Processing

Additional tools for formatting, analyzing, and converting text data.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `printf` | Formatted output (like in C). Supports `%s`, `%d`, `%f`, `%x`, etc. | `printf "Name: %s, Age: %d\n" "Alice" 30` | Formatted output |
| `echo` | Outputs text to stdout. Flag `-e` - interpret escape sequences (`\n`, `\t`). | `echo -e "Line1\nLine2"` | Simple text output |
| `yes` | Repeatedly outputs a string (default "y"). Useful for automation. | `yes \| apt install pkg` | Auto-confirmation |
| `numfmt` | Converts numbers to human-readable format (KB, MB, GB). | `echo 1500000 \| numfmt --to=si` -> `1.5M` | Format numbers |
| `factor` | Factors a number into prime factors. | `factor 60` -> `60: 2 2 3 5` | Prime factorization |
| `base64` | Encodes/decodes Base64. Flag `-d` - decode. | `echo "hello" \| base64` | Encode/decode Base64 |
| `base32` | Encodes/decodes Base32. | `echo "hello" \| base32` | Encode Base32 |
| `basenc` | Encodes in various formats (base64, base32, hex, etc.). | `basenc --base64url < file` | Flexible encoding |
| `iconv` | Converts text between encodings. | `iconv -f UTF-8 -t CP1251 file.txt` | Change encoding |
| `strings` | Extracts readable strings from a binary file. | `strings binary_file` | Find text in a binary |
| `grep` | (see section 3) | | |
| `jq` | Processes JSON on the command line. Powerful selector and transformer. | `jq '.name' data.json` | Work with JSON |
| `json_pp` | Pretty-print JSON (from Perl). Simple formatter. | `json_pp < data.json` | Pretty-format JSON |
| `jsonschema` | Validates JSON against JSON Schema. | `jsonschema -i data.json schema.json` | Validate JSON against schema |
| `xml2` | Converts XML to a flat format for processing with text utilities. | `xml2 < config.xml` | Process XML as text |

---

---

## 5. Archiving and Compression

Tools for packing and unpacking archives. Different formats are used in different contexts: `.tar.gz` - Linux standard, `.zip` - universal, `.7z` - maximum compression.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `tar` | Universal Linux archiver. Creates `.tar`, combines with gzip/bzip2/xz. Flag `-c` - create, `-x` - extract, `-z` - gzip, `-j` - bzip2, `-v` - verbose. | `tar -czf archive.tar.gz folder/` | Create/extract tar archive |
| `gzip` | Compresses files to `.gz` format. Original is replaced. Flag `-k` - keep original. | `gzip -k bigfile.txt` | Compress file to .gz |
| `gunzip` | Decompresses `.gz` files. | `gunzip file.txt.gz` | Decompress .gz |
| `zcat` | Outputs `.gz` file content without decompressing to disk. | `zcat log.txt.gz` | Read compressed file |
| `bzip2` | Compresses to `.bz2` - better compression than gzip, but slower. | `bzip2 -k file.txt` | Compress to .bz2 |
| `bunzip2` | Decompresses `.bz2` files. | `bunzip2 file.txt.bz2` | Decompress .bz2 |
| `xz` | Compresses to `.xz` - best compression, but slowest. | `xz -k file.txt` | Maximum compression |
| `unxz` | Decompresses `.xz` files. | `unxz file.txt.xz` | Decompress .xz |
| `lzma` | Compresses in LZMA format (predecessor of xz). | `lzma -k file.txt` | Compress to LZMA |
| `zip` | Creates `.zip` archive. Universal format for Windows/Linux/macOS. | `zip -r archive.zip folder/` | Create zip archive |
| `unzip` | Decompresses `.zip` archives. Flag `-l` - list contents without extracting. | `unzip archive.zip -d target/` | Extract zip |
| `zipinfo` | Shows detailed info about zip archive contents. | `zipinfo archive.zip` | Zip information |
| `zipcloak` | Encrypts a zip archive with a password. | `zipcloak archive.zip` | Protect zip with password |
| `zipsplit` | Splits a large zip into parts of a given size. | `zipsplit -n 1000000 big.zip` | Split zip into parts |
| `unrar` | Decompresses `.rar` archives. | `unrar x archive.rar` | Extract RAR |
| `unrar-free` | Free implementation of unrar (limited RAR5 support). | `unrar-free x archive.rar` | Extract RAR (free) |

---


*(Part of the Z.ai Sandbox Command Cheatsheet — see `sandbox-commands-cheatsheet.md` for the full index.)*
