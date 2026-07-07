# Z.ai Sandbox Commands — Development Languages & Git

> On-demand reference. Part of the Z.ai Sandbox Command Cheatsheet (see `sandbox-commands-cheatsheet.md` for the index).

---

## Table of Contents

11. [Python and Ecosystem](#11-python-and-ecosystem)
12. [Node.js / JavaScript / TypeScript](#12-nodejs--javascript--typescript)
13. [Java](#13-java)
14. [Perl](#14-perl)
15. [C/C++ and Build Tools](#15-cc++-and-build-tools)
16. [Git - Version Control](#16-git---version-control)

---

## 11. Python and Ecosystem

Python is the primary language for data, AI, and automation. The sandbox has Python 3.12 and 3.13 installed, along with many libraries and tools.

**Version:** Python 3.12.13 / 3.13 | **pip:** 25.1.1

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `python3` | Python 3 interpreter. Flag `-c` - execute string, `-m` - run module. | `python3 -c "print('Hello')"` | Run Python |
| `pip` | Python package manager. `install`, `uninstall`, `list`, `show`, `freeze`. | `pip install pandas` | Install a library |
| `pip3` | Alias for pip for Python 3. | `pip3 install requests` | Install library (Python 3) |
| `ipython` | Interactive Python shell with syntax highlighting, autocompletion, and magic commands. | `ipython` | Interactive Python work |
| `jupyter` | Runs Jupyter Notebook/Lab - interactive environment for data analysis. | `jupyter lab --port 8888` | Data analysis in browser |
| `jupyter-lab` | JupyterLab - next generation Jupyter Notebook. | `jupyter-lab` | Interactive data analysis |
| `jupyter-notebook` | Classic Jupyter Notebook. | `jupyter-notebook` | Run notebook |
| `pytest` | Testing framework. Automatically finds tests in `test_*.py` files. | `pytest tests/ -v` | Run tests |
| `coverage` | Measures code test coverage. | `coverage run -m pytest && coverage report` | Check test coverage |
| `debugpy` | Python debugger for VS Code and other IDEs. | `debugpy --listen 5678 script.py` | Remote debugging |
| `pydoc` | Generates documentation from Python docstrings. | `pydoc pandas.DataFrame` | Module documentation |
| `pygmentize` | Syntax highlights code (500+ languages supported). | `pygmentize script.py` | Code highlighting |
| `spacy` | NLP library (Natural Language Processing). | `spacy download en_core_web_sm` | NLP text processing |
| `numba` | Python JIT compiler for accelerating numerical computations. | `numba -s` | Numba information |
| `bokeh` | Interactive data visualization library. | `bokeh serve app.py` | Interactive charts |
| `gradio` | Quick web interface creation for ML models. | `gradio app.py` | ML model demo |
| `fastapi` | Framework for creating Python APIs. | `fastapi dev main.py` | Create API |
| `uvicorn` | ASGI server for running FastAPI and other ASGI applications. | `uvicorn main:app --host 0.0.0.0` | Run web server |
| `httpx` | Modern HTTP client for Python (supports HTTP/2). | `httpx` | HTTP requests from Python |
| `f2py` | Python-Fortran interface generator. | `f2py -c fib1.f90 -m fib1` | Fortran and Python integration |

---

---

## 12. Node.js / JavaScript / TypeScript

Node.js is a JavaScript runtime on the server. The sandbox has the latest version and several package managers installed.

**Version:** Node.js v24.15.0 | **npm:** 11.12.1 | **Bun:** 1.3.13

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `node` | JavaScript runtime. Executes JS files. Flag `-e` - execute inline code. | `node -e "console.log('hi')"` | Run JavaScript |
| `npm` | Node.js package manager. `install`, `run`, `test`, `publish`. | `npm install express` | Install Node.js packages |
| `npx` | Executes npm packages without installing. | `npx create-next-app` | Run package without install |
| `bun` | Fast JavaScript runtime and package manager. | `bun add react` | Fast package management |
| `tsc` | TypeScript compiler. Compiles `.ts` to `.js`. | `tsc --noEmit` | Type-check TypeScript code |
| `tsx` | TypeScript execute - runs TS files directly. | `tsx script.ts` | Run TypeScript files |
| `eslint` | JavaScript/TypeScript linter. | `eslint src/ --fix` | Check code quality |
| `prettier` | Code formatter. Supports JS, TS, CSS, JSON. | `prettier --write src/` | Format code |
| `next` | Next.js CLI. `dev`, `build`, `start`, `lint`. | `npx next build` | Build Next.js project |
| `react-scripts` | Create React App scripts. | `react-scripts build` | Build React app |

---

---

## 13. Java

Java is a compiled language for cross-platform applications. The sandbox includes the JDK for compilation and the JVM for execution.

**Version:** OpenJDK 21

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `javac` | Java compiler. Compiles `.java` to `.class`. | `javac Main.java` | Compile Java code |
| `java` | Java runtime. Runs compiled `.class` files. | `java Main` | Run Java application |
| `jar` | Java archiver. Creates/extracts JAR files. | `jar -cf app.jar *.class` | Package Java application |
| `javadoc` | Generates HTML documentation from Java comments. | `javadoc -d docs src/*.java` | Generate Java docs |
| `jshell` | Interactive Java REPL (Read-Eval-Print Loop). | `jshell` | Interactive Java testing |
| `jps` | Shows JVM process IDs. | `jps -l` | List Java processes |
| `jstack` | Shows Java thread stack traces. | `jstack 12345` | Debug Java threads |
| `jmap` | Shows Java heap memory map. | `jmap -heap 12345` | Analyze Java heap |
| `mvn` | Apache Maven - build automation for Java. | `mvn clean install` | Build Java project |
| `gradle` | Gradle build system. | `gradle build` | Build with Gradle |

---

---

## 14. Perl

Perl is a scripting language for text processing, system administration, and web development.

**Version:** Perl 5.38

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `perl` | Perl interpreter. Flag `-e` - execute inline. | `perl -e "print 'hi'"` | Run Perl scripts |
| `perldoc` | Shows Perl documentation. | `perldoc -f print` | Perl documentation |
| `cpan` | Perl module installer (Comprehensive Perl Archive Network). | `cpan install DBI` | Install Perl modules |
| `cpanm` | Lightweight CPAN client (cpanminus). | `cpanm Moose` | Quick Perl module install |
| `pl2pm` | Converts Perl library to Perl module. | `pl2pm lib.pl` | Convert script to module |
| `splain` | Explains Perl warnings and errors. | `perl -w script.pl 2>&1 \| splain` | Understand Perl errors |

---

---

## 15. C/C++ and Build Tools

C and C++ are compiled languages for system programming and performance-critical applications.

**C Compiler:** GCC 12.2 | **C++ Compiler:** G++ 12.2 | **LLVM:** 16

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `gcc` | GNU C compiler. Flag `-o` - output file, `-Wall` - all warnings. | `gcc -o program main.c` | Compile C code |
| `g++` | GNU C++ compiler. | `g++ -o program main.cpp` | Compile C++ code |
| `clang` | LLVM C compiler. Fast compilation, clear error messages. | `clang -o program main.c` | Compile with Clang |
| `clang++` | LLVM C++ compiler. | `clang++ -o program main.cpp` | Compile C++ with Clang |
| `make` | Build automation tool. Uses Makefile. | `make && make install` | Build project |
| `cmake` | Cross-platform build system generator. | `cmake -B build && cmake --build build` | Configure and build |
| `gdb` | GNU Debugger for C/C++. | `gdb ./program` | Debug a program |
| `ldd` | Shows shared library dependencies. | `ldd /usr/bin/python3` | Check library dependencies |
| `objdump` | Displays information from object files. | `objdump -d program` | Disassemble binary |
| `valgrind` | Memory debugging and profiling tool. | `valgrind ./program` | Detect memory leaks |

---

---

## 16. Git - Version Control

Git is the standard version control system for source code. All sandbox projects use Git for managing changes.

**Version:** Git 2.45

| Command | Description | Example | When to Use |
|---------|-------------|---------|-------------|
| `git init` | Initializes a new Git repository. | `git init` | Start version control |
| `git clone` | Copies a remote repository locally. | `git clone https://github.com/user/repo.git` | Download a repository |
| `git add` | Stages changes for commit. | `git add .` | Stage files for commit |
| `git commit` | Commits staged changes. | `git commit -m "feat: add feature"` | Save changes |
| `git push` | Pushes commits to remote. | `git push origin main` | Upload changes |
| `git pull` | Pulls changes from remote. | `git pull origin main` | Update local repo |
| `git status` | Shows working tree status. | `git status` | Check changed files |
| `git log` | Shows commit history. | `git log --oneline -10` | View commit history |
| `git diff` | Shows file differences. | `git diff HEAD~1` | Compare changes |
| `git branch` | Manages branches. | `git branch feature-x` | Create a new branch |
| `git checkout` | Switches branches or restores files. | `git checkout main` | Switch branch |
| `git merge` | Merges branches. | `git merge feature-x` | Merge feature branch |
| `git rebase` | Reapplies commits on top of another branch. | `git rebase main` | Linearize history |
| `git stash` | Temporarily saves uncommitted changes. | `git stash pop` | Save and restore changes |
| `git submodule` | Manages submodules. | `git submodule update --init` | Clone submodules |
| `git tag` | Creates tags (releases). | `git tag v1.0.0` | Mark a release |

---


*(Part of the Z.ai Sandbox Command Cheatsheet — see `sandbox-commands-cheatsheet.md` for the full index.)*
