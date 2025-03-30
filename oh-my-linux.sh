#!/bin/bash
# Seletor de Temas Oh My Posh para Linux com Dialog
# Versão Linux/WSL

# Cores para formatação
CYAN='\033[0;36m'
DARK_CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RESET='\033[0m'

# Verificar Oh My Posh
if ! command -v oh-my-posh &> /dev/null; then
    echo -e "${RED}Oh My Posh não está instalado!${RESET}"
    echo "Para instalar, visite: https://ohmyposh.dev/docs/installation/linux"
    exit 1
fi

# Verificar Dialog
if ! command -v dialog &> /dev/null; then
    echo -e "${YELLOW}O utilitário Dialog não está instalado. Tentando instalar...${RESET}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y dialog
    elif command -v yum &> /dev/null; then
        sudo yum install -y dialog
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y dialog
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm dialog
    else
        echo -e "${RED}Não foi possível instalar o Dialog automaticamente.${RESET}"
        echo "Por favor, instale o Dialog manualmente com o gerenciador de pacotes do seu sistema."
        exit 1
    fi

    # Verificar se a instalação foi bem-sucedida
    if ! command -v dialog &> /dev/null; then
        echo -e "${RED}Falha ao instalar o Dialog. Por favor, instale manualmente.${RESET}"
        exit 1
    fi
    
    echo -e "${GREEN}Dialog instalado com sucesso!${RESET}"
fi

# Configurar caminhos
POSH_THEMES_PATH="$HOME/.cache/oh-my-posh/themes"
if [ ! -d "$POSH_THEMES_PATH" ]; then
    POSH_THEMES_PATH="$HOME/.poshthemes"
    if [ ! -d "$POSH_THEMES_PATH" ]; then
        POSH_THEMES_PATH="/usr/local/share/oh-my-posh/themes"
        if [ ! -d "$POSH_THEMES_PATH" ]; then
            # Tente encontrar temas em caminhos comuns
            for path in "/usr/share/oh-my-posh/themes" "$HOME/.local/share/oh-my-posh/themes"; do
                if [ -d "$path" ]; then
                    POSH_THEMES_PATH="$path"
                    break
                fi
            done
        fi
    fi
fi

# Verificar se o diretório de temas existe
if [ ! -d "$POSH_THEMES_PATH" ]; then
    echo -e "${RED}Diretório de temas não encontrado!${RESET}"
    echo "O Oh My Posh pode estar instalado incorretamente."
    exit 1
fi

# Obter lista de temas
THEMES=($(find "$POSH_THEMES_PATH" -name "*.omp.json" -type f | sort | sed 's/.*\///;s/\.omp\.json//'))

# Aplicar tema temporariamente
apply_theme_temporarily() {
    local theme_name="$1"
    local theme_config="$POSH_THEMES_PATH/$theme_name.omp.json"
    
    # Verificar se o arquivo existe
    if [ ! -f "$theme_config" ]; then
        dialog --title "Erro" --msgbox "Arquivo do tema não encontrado: $theme_config" 8 50
        return 1
    fi
    
    # Aplicar tema no ambiente atual
    clear
    echo -e "${CYAN}Aplicando tema '$theme_name' temporariamente...${RESET}"
    eval "$(oh-my-posh init bash --config "$theme_config")"
    echo -e "${GREEN}Tema aplicado temporariamente. Veja as mudanças acima.${RESET}"
    echo -e "${YELLOW}Pressione ENTER para continuar...${RESET}"
    read
}


# Abrir novo terminal com tema (versão melhorada)
preview_theme_in_new_terminal() {
    local theme_name="$1"
    local theme_config="$POSH_THEMES_PATH/$theme_name.omp.json"
    
    # Tentar abrir um novo terminal, sem usar wt.exe
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "eval \"\$(oh-my-posh init bash --config '$theme_config')\"; exec bash"
    elif command -v konsole &> /dev/null; then
        konsole -e bash -c "eval \"\$(oh-my-posh init bash --config '$theme_config')\"; exec bash"
    elif command -v xterm &> /dev/null; then
        xterm -e bash -c "eval \"\$(oh-my-posh init bash --config '$theme_config')\"; exec bash"
    elif command -v xfce4-terminal &> /dev/null; then
        xfce4-terminal -e "bash -c \"eval \\\"\$(oh-my-posh init bash --config '$theme_config')\\\"; exec bash\""
    else
        echo -e "${RED}>> Não foi possível abrir um novo terminal. Seu ambiente pode não ser suportado.${RESET}"
        sleep 2
    fi
}


# Salvar tema no perfil, aplicar completamente e fechar o dialog
save_theme_to_profile() {
    local theme_name="$1"
    local theme_config="$POSH_THEMES_PATH/$theme_name.omp.json"
    local bashrc="$HOME/.bashrc"
    
    # Verificar se o arquivo do tema existe
    if [ ! -f "$theme_config" ]; then
        dialog --title "Erro" --msgbox "Arquivo do tema não encontrado: $theme_config" 8 50
        return 1
    fi
    
    # Fazer backup do .bashrc
    cp "$bashrc" "$bashrc.bak.$(date +%Y%m%d%H%M%S)"
    
    # Remover configurações anteriores do Oh My Posh
    sed -i '/eval "$(oh-my-posh init bash/d' "$bashrc"
    
    # Adicionar nova configuração do tema com correção para caracteres especiais
    echo "eval \"\$(oh-my-posh init bash --config '$theme_config' | sed 's/export POSH_SHELL_VERSION=\\([^)]*\\))/export POSH_SHELL_VERSION=\"\\1\"/g')\"" >> "$bashrc"
    
    # Criar um script temporário para aplicar o tema completamente
    local temp_script="/tmp/apply_theme_$$.sh"
    
    # Escrever o script temporário
    cat > "$temp_script" << EOF
#!/bin/bash
# Carregar o bashrc completo e executar o terminal
source "$bashrc"
clear
echo -e "\033[0;32mTema '$theme_name' aplicado com sucesso!\033[0m"
echo -e "\033[0;33mO tema está completamente ativo agora.\033[0m"
echo
exec bash
EOF
    
    # Tornar o script executável
    chmod +x "$temp_script"
    
    # Fechar o dialog e executar o script temporário
    clear
    exec "$temp_script"
}

# Função principal usando Dialog
select_theme_dialog() {
    # Preparar a lista de temas para o Dialog
    local theme_options=()
    local i=1
    
    for theme in "${THEMES[@]}"; do
        theme_options+=("$i" "$theme")
        ((i++))
    done
    
    # Mostrar o menu de seleção de temas
    local cmd=(dialog --backtitle "Oh My Posh Theme Selector" --title "Temas Disponíveis" --menu "Escolha um tema:" 22 60 15)
    local choice=$("${cmd[@]}" "${theme_options[@]}" 2>&1 >/dev/tty)
    
    # Verificar se o usuário cancelou
    if [ $? -ne 0 ]; then
        return
    fi
    
    # Obter o tema selecionado (ajuste para índice base-0)
    local selected_index=$((choice - 1))
    local selected_theme="${THEMES[$selected_index]}"
    
    # Mostrar opções para o tema selecionado
    while true; do
        local option=$(dialog --backtitle "Oh My Posh Theme Selector" --title "Tema: $selected_theme" \
                            --menu "Escolha uma opção:" 15 60 3 \
                            "1" "Visualizar (abre novo terminal)" \
                            "2" "Visualizar no terminal atual" \
                            "3" "Salvar e aplicar permanentemente" \
                            "4" "Voltar para a lista de temas" \
                            2>&1 >/dev/tty)
        
        # Verificar se o usuário cancelou
        if [ $? -ne 0 ]; then
            break
        fi
        
        case $option in
            1) # Visualizar em novo terminal
                preview_theme_in_new_terminal "$selected_theme"
                ;;
            2) # Visualizar no terminal atual
                apply_theme_temporarily "$selected_theme"
                ;;
            3) # Salvar e aplicar
                save_theme_to_profile "$selected_theme"
                return
                ;;
            4|*) # Voltar para a lista
                break
                ;;
        esac
    done
}


# Mostrar ajuda
show_help() {
    cat << EOF
${CYAN}Seletor de Temas Oh My Posh - Ajuda${RESET}

${WHITE}Parâmetros disponíveis:${RESET}

${YELLOW}  --help                Mostra esta mensagem de ajuda${RESET}
${YELLOW}  --list                Lista todos os temas disponíveis${RESET}
${YELLOW}  --theme=<nome>        Aplica um tema específico diretamente${RESET}

${WHITE}Este script usa Dialog para uma interface amigável de seleção de temas.${RESET}
${WHITE}Funciona perfeitamente no WSL (Windows Subsystem for Linux).${RESET}

EOF
    echo -e "${GREEN}Pressione ENTER para continuar...${RESET}"
    read
}

# Listar todos os temas disponíveis
list_all_themes() {
    clear
    echo -e "${CYAN}Temas Oh My Posh Disponíveis:${RESET}"
    echo
    
    for theme in "${THEMES[@]}"; do
        echo "  $theme"
    done
    
    echo
    echo -e "${CYAN}Total: ${#THEMES[@]} temas${RESET}"
    echo
    echo -e "${YELLOW}Pressione ENTER para continuar...${RESET}"
    read
}

# Aplicar tema específico
apply_specific_theme() {
    local theme_name="$1"
    
    # Verificar se o tema existe
    local theme_exists=false
    for theme in "${THEMES[@]}"; do
        if [ "$theme" == "$theme_name" ]; then
            theme_exists=true
            break
        fi
    done
    
    if $theme_exists; then
        local theme_config="$POSH_THEMES_PATH/$theme_name.omp.json"
        
        # Verificar se o arquivo existe
        if [ ! -f "$theme_config" ]; then
            echo -e "${RED}Erro: O arquivo do tema não foi encontrado: $theme_config${RESET}"
            sleep 2
            return 1
        fi
        
        # Mostrar opções para o tema selecionado
        local option=$(dialog --backtitle "Oh My Posh Theme Selector" --title "Tema: $theme_name" \
                          --menu "Escolha uma opção:" 15 60 3 \
                          "1" "Visualizar (abre novo terminal)" \
                          "2" "Visualizar no terminal atual" \
                          "3" "Salvar e aplicar permanentemente" \
                          "4" "Voltar" \
                          2>&1 >/dev/tty)
        
        # Verificar se o usuário cancelou
        if [ $? -ne 0 ]; then
            return
        fi
        
        case $option in
            1) # Visualizar em novo terminal
                preview_theme_in_new_terminal "$theme_name"
                ;;
            2) # Visualizar no terminal atual
                apply_theme_temporarily "$theme_name"
                ;;
            3) # Salvar e aplicar
                save_theme_to_profile "$theme_name"
                return
                ;;
            4|*) # Voltar
                return
                ;;
        esac
    else
        # Tentar pesquisar temas semelhantes
        local similar_themes=()
        for theme in "${THEMES[@]}"; do
            if [[ $theme == *"$theme_name"* ]]; then
                similar_themes+=("$theme")
            fi
        done
        
        if [ ${#similar_themes[@]} -gt 0 ]; then
            local message="Tema '$theme_name' não encontrado, mas encontramos temas semelhantes:\n\n"
            for theme in "${similar_themes[@]}"; do
                message+="  - $theme\n"
            done
            
            if dialog --title "Temas Similares" --yesno "$message\nDeseja selecionar um destes temas?" 15 60; then
                # Preparar a lista de temas para o Dialog
                local sim_options=()
                local i=1
                
                for theme in "${similar_themes[@]}"; do
                    sim_options+=("$i" "$theme")
                    ((i++))
                done
                
                # Mostrar o menu de seleção de temas similares
                local sim_cmd=(dialog --backtitle "Oh My Posh Theme Selector" --title "Temas Similares" --menu "Escolha um tema:" 15 60 8)
                local sim_choice=$("${sim_cmd[@]}" "${sim_options[@]}" 2>&1 >/dev/tty)
                
                # Verificar se o usuário cancelou
                if [ $? -eq 0 ]; then
                    # Obter o tema selecionado (ajuste para índice base-0)
                    local sim_index=$((sim_choice - 1))
                    local sim_theme="${similar_themes[$sim_index]}"
                    apply_specific_theme "$sim_theme"
                fi
            fi
        else
            dialog --title "Erro" --msgbox "Tema '$theme_name' não encontrado.\nUse o parâmetro --list para ver temas disponíveis." 8 60
        fi
    fi
}

# Exibir o banner
show_banner() {
    clear
    cat << EOF
${DARK_CYAN}                                                                  
 _____ _____ _____ _____ _____ _____ _____    _____ _____ _____ _____ 
|  |  |     |__   |     |     |     |   | |  |  _  |     |   __|  |  |
|  |  |-   -|   __|-   -|  |  |  |  | | | |  |   __|  |  |__   |     |
 \___/|_____|_____|_____|_____|_____|_|___|  |__|  |_____|_____|__|__|
 
- Author : Daniel Estevao Martins Mendes
- Git : https://github.com/dvizioon/VIZIOONPOSH
- Version : 0.0.103 (Linux/WSL - Dialog Edition)
${RESET}
EOF
    sleep 1
}

# Menu principal
main_menu() {
    show_banner
    
    # Exibir menu principal
    local option=$(dialog --backtitle "Oh My Posh Theme Selector" --title "Menu Principal" \
                      --menu "Escolha uma opção:" 15 60 4 \
                      "1" "Selecionar um tema" \
                      "2" "Listar todos os temas" \
                      "3" "Mostrar ajuda" \
                      "4" "Sair" \
                      2>&1 >/dev/tty)
    
    # Verificar se o usuário cancelou
    if [ $? -ne 0 ]; then
        clear
        echo -e "${CYAN}Obrigado por usar o Seletor de Temas Oh My Posh!${RESET}"
        exit 0
    fi
    
    case $option in
        1) # Selecionar tema
            select_theme_dialog
            main_menu
            ;;
        2) # Listar temas
            list_all_themes
            main_menu
            ;;
        3) # Mostrar ajuda
            show_help
            main_menu
            ;;
        4|*) # Sair
            clear
            echo -e "${CYAN}Obrigado por usar o Seletor de Temas Oh My Posh!${RESET}"
            exit 0
            ;;
    esac
}

# Processamento dos argumentos
if [ $# -gt 0 ]; then
    # Verificar argumentos
    if [[ $1 == "--help" ]]; then
        show_help
    elif [[ $1 == "--list" ]]; then
        list_all_themes
    elif [[ $1 == --theme=* ]]; then
        theme_name="${1#--theme=}"
        apply_specific_theme "$theme_name"
    else
        # Se não reconheceu o parâmetro, mostrar ajuda
        echo -e "${RED}Parâmetro desconhecido: $1${RESET}"
        echo -e "${YELLOW}Use --help para ver os parâmetros disponíveis.${RESET}"
        sleep 2
        show_help
    fi
else
    # Sem argumentos, executar o menu principal
    main_menu
fi

clear