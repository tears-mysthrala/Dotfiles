#!/usr/bin/env bash
# ============================================================================
# Optimized Tool Initialization with Caching
# Cachea el output de starship init y zoxide init para evitar
# ejecutar los binarios en cada shell startup
# ============================================================================

# Directorio para caches
__CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/shell-init"
[ -d "$__CACHE_DIR" ] || mkdir -p "$__CACHE_DIR"

# ============================================================================
# Generic Eval Cache Function
# Cachea el resultado de eval "$($cmd init $shell)" basado en el hash del binario
# ============================================================================

__evalcache() {
    local cmd="$1"
    shift
    local cache_file="$__CACHE_DIR/${cmd}-init.sh"
    local hash_file="$__CACHE_DIR/${cmd}-hash"
    
    # Obtener hash actual del binario
    local current_hash=""
    if command -v "$cmd" >/dev/null 2>&1; then
        current_hash=$(command -v "$cmd" | xargs md5sum 2>/dev/null | cut -d' ' -f1)
    fi
    
    # Verificar si el cache es válido
    local cached_hash=""
    if [ -f "$hash_file" ]; then
        cached_hash=$(cat "$hash_file" 2>/dev/null)
    fi
    
    if [ -f "$cache_file" ] && [ "$current_hash" = "$cached_hash" ] && [ -n "$current_hash" ]; then
        # Usar cache
        source "$cache_file"
    else
        # Generar nuevo cache
        if command -v "$cmd" >/dev/null 2>&1; then
            "$cmd" init "$@" > "$cache_file" 2>/dev/null
            echo "$current_hash" > "$hash_file"
            source "$cache_file"
        fi
    fi
}

# ============================================================================
# Clear all caches (útil después de actualizar herramientas)
# ============================================================================

evalcache_clear() {
    local cmd="$1"
    if [ -n "$cmd" ]; then
        rm -f "$__CACHE_DIR/${cmd}-init.sh" "$__CACHE_DIR/${cmd}-hash"
        echo "Cache cleared for $cmd"
    else
        rm -rf "$__CACHE_DIR"
        mkdir -p "$__CACHE_DIR"
        echo "All caches cleared"
    fi
}

# ============================================================================
# Optimized Starship Init
# ============================================================================

init_starship_optimized() {
    local shell="${1:-bash}"
    
    # Detectar shell actual si no se especificó
    if [ -z "$shell" ]; then
        if [ -n "$ZSH_VERSION" ]; then
            shell="zsh"
        elif [ -n "$BASH_VERSION" ]; then
            shell="bash"
        fi
    fi
    
    # Starship es especial - necesita saber el shell
    local cache_file="$__CACHE_DIR/starship-${shell}-init.sh"
    local hash_file="$__CACHE_DIR/starship-${shell}-hash"
    
    local current_hash=""
    if command -v starship >/dev/null 2>&1; then
        current_hash=$(command -v starship | xargs md5sum 2>/dev/null | cut -d' ' -f1)
    fi
    
    local cached_hash=""
    if [ -f "$hash_file" ]; then
        cached_hash=$(cat "$hash_file" 2>/dev/null)
    fi
    
    if [ -f "$cache_file" ] && [ "$current_hash" = "$cached_hash" ] && [ -n "$current_hash" ]; then
        source "$cache_file"
    else
        if command -v starship >/dev/null 2>&1; then
            starship init "$shell" > "$cache_file" 2>/dev/null
            echo "$current_hash" > "$hash_file"
            source "$cache_file"
        fi
    fi
}

# ============================================================================
# Optimized Zoxide Init
# ============================================================================

init_zoxide_optimized() {
    local shell="${1:-bash}"
    
    if [ -z "$shell" ]; then
        if [ -n "$ZSH_VERSION" ]; then
            shell="zsh"
        elif [ -n "$BASH_VERSION" ]; then
            shell="bash"
        fi
    fi
    
    local cache_file="$__CACHE_DIR/zoxide-${shell}-init.sh"
    local hash_file="$__CACHE_DIR/zoxide-${shell}-hash"
    
    local current_hash=""
    if command -v zoxide >/dev/null 2>&1; then
        current_hash=$(command -v zoxide | xargs md5sum 2>/dev/null | cut -d' ' -f1)
    fi
    
    local cached_hash=""
    if [ -f "$hash_file" ]; then
        cached_hash=$(cat "$hash_file" 2>/dev/null)
    fi
    
    if [ -f "$cache_file" ] && [ "$current_hash" = "$cached_hash" ] && [ -n "$current_hash" ]; then
        source "$cache_file"
    else
        if command -v zoxide >/dev/null 2>&1; then
            zoxide init "$shell" > "$cache_file" 2>/dev/null
            echo "$current_hash" > "$hash_file"
            source "$cache_file"
        fi
    fi
}

# ============================================================================
# Lazy Zoxide Init (Ultra-fast, carga bajo demanda)
# ============================================================================

init_zoxide_lazy() {
    local shell="${1:-bash}"
    
    if [ -z "$shell" ]; then
        if [ -n "$ZSH_VERSION" ]; then
            shell="zsh"
        elif [ -n "$BASH_VERSION" ]; then
            shell="bash"
        fi
    fi
    
    # Crear función wrapper que inicializa zoxide en primer uso
    eval "
z() {
    unset -f z zi cdi 2>/dev/null || true
    init_zoxide_optimized '$shell'
    z \"\$@\"
}

zi() {
    unset -f z zi cdi 2>/dev/null || true
    init_zoxide_optimized '$shell'
    zi \"\$@\"
}
"
    
    # Si el usuario quiere reemplazar cd, crear un smart cd
    if [ "${ZOXIDE_REPLACE_CD:-false}" = "true" ]; then
        eval "
cd() {
    if [ -d \"\$1\" ] || [ \"\$1\" = \"-\" ] || [ -z \"\$1\" ]; then
        builtin cd \"\$@\" 2>/dev/null || command cd \"\$@\"
    else
        unset -f z zi cd 2>/dev/null || true
        init_zoxide_optimized '$shell'
        z \"\$@\"
    fi
}
"
    fi
}

# ============================================================================
# Benchmarking function
# ============================================================================

benchmark_init() {
    local cmd="$1"
    local iterations="${2:-10}"
    
    echo "Benchmarking $cmd init ($iterations iterations)..."
    
    # Medir con eval directo
    echo "Direct eval:"
    time for i in $(seq 1 "$iterations"); do
        eval "$($cmd init bash)" >/dev/null 2>&1
    done
    
    # Medir con cache
    echo ""
    echo "Cached:"
    # Primero llenar cache
    __evalcache "$cmd" bash >/dev/null 2>&1
    time for i in $(seq 1 "$iterations"); do
        source "$__CACHE_DIR/${cmd}-init.sh" >/dev/null 2>&1
    done
}

# Alias para fácil limpieza
alias clear-starship-cache='evalcache_clear starship'
alias clear-zoxide-cache='evalcache_clear zoxide'
alias clear-all-tool-caches='evalcache_clear'
