# Functions & Utilities Reference

Este documento lista todas las funciones y utilidades disponibles en tu configuración de shell.

## 📁 Estructura de Archivos

- **`dotfiles/bashrc`** - Punto de entrada para Bash
- **`dotfiles/zshrc`** - Punto de entrada para Zsh
- **`dotfiles/shell/functions.sh`** - Funciones personalizadas
- **`dotfiles/shell/aliases.sh`** - Alias y atajos
- **`dotfiles/shell/exports.sh`** - Variables de entorno

Los archivos se cargan automáticamente mediante enlaces simbólicos:

- `~/.bashrc` → `dotfiles/bashrc`
- `~/.zshrc` → `dotfiles/zshrc`
- `~/.config/shell/*.sh` → `dotfiles/shell/*.sh`

---

## 🔧 Funciones Principales

### Navegación

- **`mkdir_and_cd <dir>`** (alias: `mkcd`) - Crea un directorio y navega a él
- **`fcd [path]`** - Cambio de directorio interactivo con FZF
- **`..`, `...`, `.3`, `.4`, `.5`** - Atajos para navegar directorios arriba

### Editor

- **`editor [file]`** (alias: `v`, `e`) - Abre archivos con el mejor editor disponible
  - Busca automáticamente: nvim → vim → vi → nano → code → emacs

### Sistema

- **`upgrade`** - Actualiza el sistema completo (detecta distribución automáticamente)
  - Soporta: apt, dnf, yum, pacman, zypper, apk
  - También actualiza: Flatpak, Snap, NPM, Cargo, Pipx
- **`cleanup`** - Limpia caché y archivos temporales del sistema
  - Limpia cache de paquetes, /tmp, logs del journal, Docker
- **`detect_package_manager`** - Detecta el gestor de paquetes del sistema

### Información del Sistema

- **`sysinfo`** - Muestra información completa del sistema
- **`get_public_ip`** (alias: `pubip`, `myip`) - Obtiene tu IP pública
- **`get_local_ip`** - Muestra tus IPs locales

### Archivos y Búsqueda

- **`extract <file>`** - Extrae cualquier tipo de archivo comprimido
  - Soporta: .tar.gz, .zip, .rar, .7z, .bz2, etc.
- **`ff [pattern] [path] [depth]`** - Encuentra archivos por nombre
  - Usa `fd` si está disponible, sino `find`
- **`search <pattern> [path]`** - Busca contenido en archivos
  - Usa `ripgrep` si está disponible, sino `grep`
- **`whichcmd <command>`** - Muestra información detallada sobre un comando
  - Nota: Usa `whichcmd` en lugar del `which` nativo para más detalles

### Gestión de Procesos

- **`psgrep <pattern>`** - Busca procesos por nombre
- **`killport <port>`** - Mata el proceso que usa un puerto específico

### Git

- **`glog [args]`** - Git log bonito con colores y formato mejorado
- **`ghead`** - Muestra el último commit con cambios
- **`gbr [args]`** - Lista ramas ordenadas por fecha de commit
- **`gitignore <tech1,tech2,...>`** - Genera .gitignore desde gitignore.io
- **`git_clone_cd <url>`** - Clona repo y entra al directorio

### Desarrollo Python

- **`mkvenv [name]`** - Crea y activa un entorno virtual Python
  - Por defecto: `.venv`
- **`serve [port]`** - Inicia servidor HTTP con Python
  - Puerto por defecto: 8000

### FZF (Buscador Interactivo)

- **`fzf_preview`** - FZF con preview de archivos usando bat
- **`fzf_find`** - Busca archivos con preview
- **`fzf_open`** (alias: `fo`) - Abre archivos con FZF
- **`fzf_rg [query]`** - Búsqueda de contenido interactiva con ripgrep
- **`fgco`** - Checkout de rama Git interactivo

### Utilidades

- **`sha256 <file>`** - Calcula hash SHA256 de un archivo
- **`md5 <file>`** - Calcula hash MD5 de un archivo
- **`benchmark <command> [iterations]`** - Ejecuta comando N veces y mide tiempo
- **`dirs [pattern]`** - Lista archivos en directorio actual

---

## 🎯 Alias Principales

### Navegación y Sistema

```bash
c, csl          # clear
shutdownnow     # apaga el sistema inmediatamente
rebootnow       # reinicia el sistema
```

### Git (atajos básicos)

```bash
g               # git
gst             # git status
gaa             # git add --all
gc              # git commit
gco             # git checkout
gd              # git diff
gl              # git log --oneline --graph
pull            # git pull
push            # git push
```

### Docker

```bash
d               # docker
dc              # docker-compose
```

### Herramientas Modernas (si están instaladas)

```bash
lg              # lazygit
cat             # bat (mejor cat con resaltado)
ls, ll, la, lt  # eza (mejor ls con iconos)
grep            # ripgrep (búsqueda más rápida)
find            # fd (búsqueda más rápida)
```

### Systemd

```bash
sctl            # sudo systemctl
jctl            # sudo journalctl
```

### Seguridad

```bash
rm, cp, mv      # Con modo interactivo (-i) para evitar errores
```

### Clipboard (X11/Wayland)

```bash
pbcopy          # Copia al portapapeles
pbpaste         # Pega desde portapapeles
```

---

## 🌟 Herramientas Integradas

### Starship

Prompt moderno y rápido. Configuración en `~/.config/starship.toml`

### Zoxide

Navegación inteligente de directorios. Reemplaza `cd` con aprendizaje.

- **`z <query>`** - Salta a directorio frecuente
- **`zi`** - Selección interactiva de directorios

### FZF
Buscador difuso interactivo con keybindings:

- `Ctrl+T` - Buscar archivos
- `Ctrl+R` - Buscar en historial
- `Alt+C` - Cambiar directorio

### Bat
Reemplazo de `cat` con resaltado de sintaxis y numeración de líneas.

### Eza
Reemplazo de `ls` con iconos, colores y vista de árbol.

---

## 📝 Variables de Entorno Importantes

```bash
EDITOR=nvim                 # Editor por defecto
VISUAL=nvim                 # Editor visual
LANG=en_US.UTF-8           # Localización
HISTSIZE=10000             # Tamaño del historial
FZF_DEFAULT_COMMAND        # Comando para FZF (usa fd)
BAT_THEME=Nord             # Tema de Bat
```

---

## 🚀 Uso Típico

### Flujo de trabajo Git

```bash
gst              # Ver estado
gaa              # Agregar todo
gc -m "mensaje"  # Commit
push             # Push a remote
glog             # Ver historial bonito
```

### Búsqueda y navegación

```bash
ff "*.py"        # Buscar archivos Python
search "TODO"    # Buscar TODOs en código
z proyecto       # Saltar a directorio de proyecto
fcd              # Cambio de directorio interactivo
```

### Mantenimiento del sistema

```bash
upgrade          # Actualizar todo
cleanup          # Limpiar cache y temporales
sysinfo          # Ver info del sistema
```

### Desarrollo

```bash
mkvenv           # Crear entorno Python
serve 3000       # Servidor HTTP en puerto 3000
killport 8080    # Matar proceso en puerto 8080
```

---

## ⚠️ Notas Importantes

1. **Todas las funciones están disponibles automáticamente** después de ejecutar `make install`
2. **No necesitas crear alias para las funciones** - están en el scope global del shell
3. **Los archivos se cargan en orden**: exports → aliases → functions
4. **Personalización local**: 
   - `~/.bashrc.local` o `~/.zshrc.local` para personalizaciones
   - `~/.config/shell/exports.local.sh` para variables de entorno personalizadas
5. **Chezmoi**: Si está instalado, hay funciones adicionales (`czcd`, `cma`, `cms`, etc.)

---

## 🔄 Actualización

Para actualizar la configuración:
```bash
cd ~/.dotfiles
git pull
make install
source ~/.bashrc  # o source ~/.zshrc
```

## 🐛 Depuración

Si algo no funciona:

1. Verifica que los enlaces simbólicos estén correctos: `ls -la ~/.config/shell/`
2. Recarga el shell: `source ~/.bashrc` o `source ~/.zshrc`
3. Verifica que la función exista: `type <nombre_funcion>`
4. Revisa errores: `bash -x ~/.bashrc` o `zsh -x ~/.zshrc`
