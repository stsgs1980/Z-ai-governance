# Z.ai Sandbox Commands — Documents, Media, Data, Web & Misc

> On-demand reference. Part of the Z.ai Sandbox Command Cheatsheet (see `sandbox-commands-cheatsheet.md` for the index).

---

## Table of Contents

17. [Documents and Conversion](#17-documents-and-conversion)
18. [Graphics, Video, Images](#18-graphics,-video,-images)
19. [Maps and Geodata (GDAL/OGR)](#19-maps-and-geodata-gdalogr)
20. [Data and Formats](#20-data-and-formats)
21. [Web Servers and API](#21-web-servers-and-api)
22. [Databases](#22-databases)
23. [Editors](#23-editors)
24. [Special Z.ai Commands](#24-special-zai-commands)
25. [Other Useful Utilities](#25-other-useful-utilities)

---

## 17. Documents and Conversion

Tools for working with and converting between document formats (PDF, text, markup, etc.).

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `pandoc` | Universal document converter (Markdown, HTML, PDF, DOCX, LaTeX). | `pandoc README.md -o README.pdf` | Convert document format |
| `groff` | Document formatting system (man pages, etc.). | `groff -man -Tpdf manpage.1 > manpage.pdf` | Create formatted documents |
| `man` | Shows system manual pages. | `man ls` | Read manual |
| `tex` | TeX typesetting system. | `tex document.tex` | Typeset TeX document |
| `pdflatex` | Compiles LaTeX to PDF. | `pdflatex article.tex` | Create PDF from LaTeX |
| `lualatex` | LuaLaTeX compiler (LaTeX with Lua scripting). | `lualatex document.tex` | Modern LaTeX compilation |
| `xelatex` | XeLaTeX compiler (supports Unicode and modern fonts). | `xelatex document.tex` | Unicode LaTeX compilation |
| `bibtex` | Bibliography management for LaTeX. | `bibtex article` | Process bibliography |
| `detex` | Strips LaTeX commands, leaving plain text. | `detex article.tex > article.txt` | Extract text from LaTeX |

---

---

## 18. Graphics, Video, Images

Tools for image processing, video manipulation, and graphic file conversion.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `convert` | ImageMagick - image format conversion and processing. | `convert input.png output.jpg` | Convert image format |
| `identify` | Shows image metadata (dimensions, format, colors). | `identify image.png` | Get image info |
| `mogrify` | Batch image processing (resize, format change). | `mogrify -resize 800x600 *.jpg` | Batch resize images |
| `ffmpeg` | Universal audio/video converter and processor. | `ffmpeg -i input.mp4 output.gif` | Convert video |
| `ffprobe` | Shows media file metadata. | `ffprobe video.mp4` | Get video info |
| `ffplay` | Simple media player. | `ffplay video.mp4` | Play video file |
| `exiftool` | Reads/writes EXIF metadata in images. | `exiftool image.jpg` | View image metadata |
| `pngquant` | PNG compression (lossy). | `pngquant --quality=80 image.png` | Compress PNG |
| `optipng` | PNG lossless compression. | `optipng image.png` | Optimize PNG |
| `jpegoptim` | JPEG lossless/lossy compression. | `jpegoptim --max=85 image.jpg` | Optimize JPEG |
| `rsvg-convert` | Converts SVG to PNG/PDF. | `rsvg-convert icon.svg -o icon.png` | Convert SVG to PNG |

---

---

## 19. Maps and Geodata (GDAL/OGR)

Geospatial data processing tools. GDAL handles raster formats, OGR handles vector formats.

**Version:** GDAL 3.9

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `gdalinfo` | Shows raster file metadata. | `gdalinfo terrain.tif` | Get raster info |
| `gdal_translate` | Converts raster format. | `gdal_translate input.tif output.png` | Convert raster |
| `gdalwarp` | Warps, reprojects, and clips rasters. | `gdalwarp -t_srs EPSG:4326 input.tif output.tif` | Reproject raster |
| `ogr2ogr` | Converts vector formats. | `ogr2ogr output.gpkg input.shp` | Convert vector data |
| `ogrinfo` | Shows vector file metadata. | `ogrinfo data.geojson` | Get vector info |
| `gdalsrsinfo` | Shows coordinate reference system info. | `gdalsrsinfo EPSG:4326` | CRS information |
| `gdalbuildvrt` | Builds virtual raster from multiple files. | `gdalbuildvrt mosaic.vrt *.tif` | Create raster mosaic |

---

---

## 20. Data and Formats

Tools for working with structured data: compression, encoding, conversion between formats.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `csvkit` | Suite of CSV processing utilities. | `csvcut -c 1,3 data.csv` | Process CSV files |
| `xsv` | Fast CSV command-line toolkit. | `xsv search "pattern" data.csv` | Fast CSV search |
| `in2csv` | Converts various formats to CSV. | `in2csv data.xlsx > data.csv` | Convert to CSV |
| `csvformat` | Formats CSV (delimiter, quoting). | `csvformat -D '|' data.csv` | Change CSV delimiter |
| `sqlite3` | SQLite database command-line tool. | `sqlite3 db.sqlite "SELECT * FROM users"` | Query SQLite |
| `parquet-tools` | Apache Parquet file tools. | `parquet-tools schema data.parquet` | Inspect Parquet schema |
| `protoc` | Protocol Buffers compiler. | `protoc --python_out=. data.proto` | Compile Protobuf |
| `avro-tools` | Apache Avro file tools. | `avro-tools getmeta data.avro` | Avro metadata |

---

---

## 21. Web Servers and API

Tools for running web servers, testing APIs, and network services.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `python3 -m http.server` | Simple HTTP server (Python). | `python3 -m http.server 8080` | Quick file server |
| `npx serve` | Static file server via npx. | `npx serve .` | Serve static files |
| `nginx` | High-performance web server. | `nginx -t` | Test nginx config |
| `apache2` | Apache HTTP Server. | `apache2ctl -S` | Apache status |
| `socat` | Multipurpose relay. | `socat TCP-LISTEN:8080,fork TCP:localhost:3000` | Port forwarding |
| `mitmproxy` | Interactive HTTPS proxy. | `mitmproxy --listen-port 8080` | Traffic inspection |
| `wrk` | HTTP benchmarking tool. | `wrk -t4 -c100 https://example.com` | Load testing |
| `ab` | Apache HTTP server benchmarking tool. | `ab -n 1000 -c 10 https://example.com/` | Performance testing |

---

---

## 22. Databases

Database management systems and CLI tools for data storage and retrieval.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `sqlite3` | SQLite CLI. Full SQL support. | `sqlite3 db.sqlite "SELECT * FROM users"` | Query SQLite database |
| `psql` | PostgreSQL interactive terminal. | `psql -d mydb -c "SELECT * FROM users"` | Query PostgreSQL |
| `mysql` | MySQL command-line client. | `mysql -u root -p -e "SHOW DATABASES"` | Query MySQL |
| `redis-cli` | Redis command-line client. | `redis-cli GET mykey` | Query Redis |
| `mongosh` | MongoDB Shell. | `mongosh --eval "db.users.find()"` | Query MongoDB |
| `bunx prisma` | Prisma ORM CLI. | `bunx prisma db push` | Manage Prisma schema |
| `pg_isready` | Checks PostgreSQL server status. | `pg_isready` | Is PostgreSQL running? |
| `mongod` | MongoDB daemon. | `mongod --dbpath /data/db` | Start MongoDB |

---

---

## 23. Editors

Command-line text editors and file manipulation tools available in the sandbox.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `vim` | Modal text editor (successor of vi). | `vim file.txt` | Edit text files |
| `nano` | Simple terminal text editor. | `nano config.yaml` | Quick edits |
| `emacs` | Extensible text editor. | `emacs file.txt` | Full-featured editing |
| `code` | VS Code CLI (if available). | `code .` | Open VS Code |
| `micro` | Modern terminal editor with mouse support. | `micro file.txt` | User-friendly terminal editing |
| `sed` | Stream editor for scripted editing. | `sed -i 's/foo/bar/g' file.txt` | Scripted replacements |
| `awk` | Pattern scanning and processing. | `awk '{print $1}' data.txt` | Text processing |
| `ed` | Original Unix line editor. | `ed file.txt` | Scripted editing |

---

---

## 24. Special Z.ai Commands

Commands specific to the Z.ai sandbox environment for managing the development container.

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `echo $FC_CONTAINER_ID` | Shows the sandbox container ID. | `echo $FC_CONTAINER_ID` | Get preview URL |
| `curl ... init-fullstack ...` | Initializes or reinitializes the sandbox. | `curl https://z-cdn.chatglm.cn/fullstack/init-fullstack_1775040338514.sh | bash` | Start fresh sandbox |
| `cat .zscripts/dev.log` | Reads dev server logs. | `cat .zscripts/dev.log \| tail -30` | Debug dev server |
| `cat .zscripts/dev.pid` | Shows dev server process ID. | `cat .zscripts/dev.pid` | Check if dev server is running |
| `pkill -f "next dev"` | Kills the Next.js dev server process. | `pkill -f "next dev"` | Restart dev server |
| `bun run lint` | Runs ESLint on the project. | `bun run lint` | Check code quality |
| `bunx tsc --noEmit` | TypeScript type checking. | `bunx tsc --noEmit` | Check TypeScript types |
| `bun add <package>` | Installs a package via Bun. | `bun add framer-motion` | Add dependencies |

---

---

## 25. Other Useful Utilities

Tools for system package management, quick installations, and other common tasks.

### System Package Installation

```bash
# System packages (Debian/Ubuntu)
apt install -y <package>

# Python packages
pip install <package>

# Node.js packages
npm install -g <package>
# or
bun add <package>

# Fast Python installation (uv - faster than pip)
uv pip install <package>
```None

### Quick Reference

```bash
# System information
uname -a          # Kernel version
cat /etc/os-release  # OS version
free -h           # Memory usage
df -h             # Disk usage
lscpu             # CPU info
nvidia-smi        # GPU info (if available)

# Process management
ps aux            # All processes
top               # Interactive monitor
kill -9 <PID>     # Force kill

# File operations
ls -la            # Detailed listing
find / -name "*.config"  # Search files
du -sh *          # Directory sizes

# Text processing
grep -rn "text" .  # Search in files
sed -i 's/a/b/g'   # Replace text
awk '{print $1}'   # Extract column
```

---

*Reference compiled for Z.ai sandbox. Total of 1321 commands available.*


*(Part of the Z.ai Sandbox Command Cheatsheet — see `sandbox-commands-cheatsheet.md` for the full index.)*
