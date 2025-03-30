# Seletor de Temas Oh My Posh
# Versao Final
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'



# Verificar Oh My Posh
try {
    $null = Get-Command oh-my-posh -ErrorAction Stop
}
catch {
    Write-Host "Oh My Posh nao esta instalado!" -ForegroundColor Red
    exit
}

# Configurar caminho dos temas e perfil
$env:POSH_THEMES_PATH = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
$profilePath = $PROFILE.CurrentUserCurrentHost

# Obter lista de temas
$themes = Get-ChildItem -Path $env:POSH_THEMES_PATH -Filter "*.omp.json" | 
        Select-Object -ExpandProperty Name | 
        ForEach-Object { $_ -replace "\.omp\.json$", "" } | 
        Sort-Object

# Funcao para salvar tema no perfil do PowerShell
function Save-ThemeToProfile {
    param (
        [string]$ThemeName
    )

    $themeConfig = "$env:POSH_THEMES_PATH\$ThemeName.omp.json"
    $profileContent = Get-Content $profilePath -Raw

    # Remover configuracoes anteriores do Oh My Posh
    $cleanedContent = $profileContent -replace '(?m)^oh-my-posh init pwsh.*$', ''

    # Adicionar nova configuracao do tema
    $newContent = $cleanedContent + "`n`noh-my-posh init pwsh --config `"$themeConfig`" | Invoke-Expression`n"

    # Salvar perfil
    Set-Content -Path $profilePath -Value $newContent.Trim()
    
    # Aplicar tema imediatamente na sessão atual
    Apply-ThemeTemporarily -ThemeName $ThemeName
    
    Write-Host "Tema aplicado na sessao atual e salvo no perfil." -ForegroundColor Green
}

# Funcao para aplicar tema temporariamente
function Apply-ThemeTemporarily {
    param (
        [string]$ThemeName
    )

    $themeConfig = "$env:POSH_THEMES_PATH\$ThemeName.omp.json"
    
    # Aplicar tema na sessao atual
    oh-my-posh init pwsh --config "$themeConfig" | Invoke-Expression
}

# Funcao para listar todos os temas DISPONIVEIS
function List-AllThemes {
    Clear-Host
    Write-Host "Temas Oh My Posh Disponiveis:" -ForegroundColor Cyan
    Write-Host

    foreach ($theme in $themes) {
        Write-Host "  $theme" -ForegroundColor White
    }
    
    Write-Host
    Write-Host "Total: $($themes.Count) temas" -ForegroundColor Cyan
    Write-Host
    Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Yellow
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

# Funcao para mostrar ajuda
function Show-Help {
    Clear-Host
    Write-Host "Seletor de Temas Oh My Posh - Ajuda" -ForegroundColor Cyan
    Write-Host
    Write-Host "Parametros disponiveis:" -ForegroundColor White
    Write-Host
    Write-Host "  --help                Mostra esta mensagem de ajuda" -ForegroundColor Yellow
    Write-Host "  --list                Lista todos os temas disponiveis" -ForegroundColor Yellow
    Write-Host "  --theme=<nome>        Aplica um tema especifico diretamente" -ForegroundColor Yellow
    Write-Host
    Write-Host "Navegacao no menu interativo:" -ForegroundColor White
    Write-Host "  Setas para cima/baixo   Navega pelos temas" -ForegroundColor Yellow
    Write-Host "  Page Up/Page Down       Navega entre paginas" -ForegroundColor Yellow
    Write-Host "  Enter                   Seleciona um tema" -ForegroundColor Yellow
    Write-Host "  ;                       Ativa modo de pesquisa" -ForegroundColor Magenta
    Write-Host "  ESC                     Volta/Cancela" -ForegroundColor Yellow
    Write-Host
    Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Green
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}


# Funcao principal de selecao de tema
function Select-OhMyPoshTheme {
    $currentPos = 0
    $pageSize = 15
    $startIndex = 0
    $originalCursor = [Console]::CursorVisible
    [Console]::CursorVisible = $false
    $filteredThemes = @() + $themes  # Criar uma cópia da lista
    $searchQuery = ""
    $inSearchMode = $false

    try {
        while ($true) {
            # Limpar a tela
            Clear-Host
            
            # Exibir cabeçalho com setas e estilo
Write-Host "                                                                  
 _____ _____ _____ _____ _____ _____ _____    _____ _____ _____ _____ 
|  |  |     |__   |     |     |     |   | |  |  _  |     |   __|  |  |
|  |  |-   -|   __|-   -|  |  |  |  | | | |  |   __|  |  |__   |     |
 \___/|_____|_____|_____|_____|_____|_|___|  |__|  |_____|_____|__|__|

- Author : Daniel Estevao Martins Mendes
- Git : https://github.com/dvizioon/VIZIOONPOSH
- Version : 0.0.102

" -ForegroundColor DarkCyan
            # Write-Host "=====================================" -ForegroundColor DarkCyan
            # Write-Host ">>  Seletor de Temas Oh My Posh  <<" -ForegroundColor Cyan
            # Write-Host "=====================================" -ForegroundColor DarkCyan
            # Write-Host
            Write-Host "  NAVEGACAO:" -ForegroundColor White
            Write-Host "    |--> [ ARROWUP ] [ ARROWDOWN ] "  -ForegroundColor Gray
            Write-Host "    |--> PgUp/PgDown Mudar de pagina" -ForegroundColor Gray
            Write-Host "    |--> Enter       Selecionar tema" -ForegroundColor Gray
            Write-Host "    |--> [ ; ]       Pesquisar temas" -ForegroundColor Magenta
            Write-Host "    |--> ESC         Sair do seletor" -ForegroundColor Gray
            
            if ($searchQuery -ne "") {
                Write-Host
                Write-Host ">> Pesquisando: '$searchQuery'" -ForegroundColor Yellow
            }
            
            Write-Host
            Write-Host "------ TEMAS DISPONIVEIS ------" -ForegroundColor DarkCyan

            # Exibir lista de temas
            $endIndex = [Math]::Min($startIndex + $pageSize - 1, $filteredThemes.Count - 1)
            
            for ($i = $startIndex; $i -le $endIndex; $i++) {
                if ($i -eq $currentPos) {
                    Write-Host " --> $($filteredThemes[$i])" -ForegroundColor Black -BackgroundColor Green
                } else {
                    Write-Host "     $($filteredThemes[$i])" -ForegroundColor White
                }
            }
            
            # Exibir informações de paginação e rodapé
            $currentPage = [Math]::Floor($startIndex / $pageSize) + 1
            $totalPages = [Math]::Ceiling($filteredThemes.Count / $pageSize)
            
            Write-Host
            Write-Host "---------------------------------" -ForegroundColor DarkCyan
            Write-Host "pagina $currentPage de $totalPages (Total: $($filteredThemes.Count) temas)" -ForegroundColor Cyan

            # Verificar se há filtro ativo
            if ($filteredThemes.Count -lt $themes.Count) {
                Write-Host ">> Filtro ativo: exibindo $($filteredThemes.Count) de $($themes.Count) temas" -ForegroundColor Magenta
            }
            
            # Se estiver em modo de pesquisa, mostrar prompt
            if ($inSearchMode) {
                Write-Host
                Write-Host ">> Digite termo de pesquisa: " -ForegroundColor Magenta -NoNewline
                Write-Host "$searchQuery" -ForegroundColor Yellow -NoNewline
            }

            # Ler input do usuário
            $key = $Host.UI.RawUI.ReadKey("IncludeKeyDown,NoEcho")
            
            # Se estiver em modo de pesquisa
            if ($inSearchMode) {
                switch ($key.VirtualKeyCode) {
                    27 { # ESC - Sair da pesquisa
                        $inSearchMode = $false
                        $searchQuery = ""
                        $filteredThemes = @() + $themes  # Resetar para lista completa
                        $currentPos = 0
                        $startIndex = 0
                    }
                    13 { # Enter - Executar pesquisa
                        $inSearchMode = $false
                        if ($searchQuery -ne "") {
                            # Filtrar temas pelo termo de pesquisa
                            $filteredThemes = @() + ($themes | Where-Object { $_ -like "*$searchQuery*" })
                            
                            if ($filteredThemes.Count -eq 0) {
                                $filteredThemes = @() + $themes
                                $searchQuery = ""
                                Write-Host
                                Write-Host ">> Nenhum tema encontrado com o termo '$searchQuery'" -ForegroundColor Red
                                Start-Sleep -Seconds 1
                            }
                            $currentPos = 0
                            $startIndex = 0
                        }
                    }
                    8 { # Backspace - Apagar caractere
                        if ($searchQuery.Length -gt 0) {
                            $searchQuery = $searchQuery.Substring(0, $searchQuery.Length - 1)
                            
                            # Atualizar resultados conforme digita
                            if ($searchQuery -ne "") {
                                $filteredThemes = @() + ($themes | Where-Object { $_ -like "*$searchQuery*" })
                                $currentPos = 0
                                $startIndex = 0
                            } else {
                                $filteredThemes = @() + $themes
                                $currentPos = 0
                                $startIndex = 0
                            }
                        }
                    }
                    default {
                        # Adicionar caractere se for válido
                        if ([char]::IsLetterOrDigit($key.Character) -or [char]::IsPunctuation($key.Character) -or [char]::IsWhiteSpace($key.Character)) {
                            if ($key.Character -ne '`0') {
                                $searchQuery += $key.Character
                                
                                # Atualizar resultados conforme digita
                                $filteredThemes = @() + ($themes | Where-Object { $_ -like "*$searchQuery*" })
                                $currentPos = 0
                                $startIndex = 0
                            }
                        }
                    }
                }
                continue
            }
            
            # Modo normal (não pesquisa)
            if ($key.Character -eq ';') {
                $inSearchMode = $true
                $searchQuery = ""
                continue
            }
            
            switch ($key.VirtualKeyCode) {
                38 { # Seta para cima
                    if ($currentPos -gt 0) {
                        $currentPos--
                        if ($currentPos -lt $startIndex) {
                            $startIndex = [Math]::Max(0, $startIndex - $pageSize)
                        }
                    } else {
                        $currentPos = $filteredThemes.Count - 1
                        $startIndex = [Math]::Max(0, $filteredThemes.Count - $pageSize)
                    }
                }
                40 { # Seta para baixo
                    if ($currentPos -lt ($filteredThemes.Count - 1)) {
                        $currentPos++
                        if ($currentPos -gt ($startIndex + $pageSize - 1)) {
                            $startIndex += $pageSize
                        }
                    } else {
                        $currentPos = 0
                        $startIndex = 0
                    }
                }
                33 { # Page Up
                    $startIndex = [Math]::Max(0, $startIndex - $pageSize)
                    $currentPos = $startIndex
                }
                34 { # Page Down
                    if ($filteredThemes.Count -gt $pageSize) {
                        $startIndex = [Math]::Min($startIndex + $pageSize, $filteredThemes.Count - 1)
                        $currentPos = $startIndex
                    }
                }
                13 { # Enter
                    if ($filteredThemes.Count -eq 0) {
                        continue
                    }
                    
                    # Pegando o tema exato da lista filtrada
                    $selectedTheme = $filteredThemes[$currentPos]
                    
                    # Verificando se o tema existe
                    $themeConfig = "$env:POSH_THEMES_PATH\$selectedTheme.omp.json"
                    if (-not (Test-Path $themeConfig)) {
                        Write-Host
                        Write-Host ">> ERRO: O arquivo do tema '$selectedTheme' não foi encontrado." -ForegroundColor Red
                        Start-Sleep -Seconds 2
                        continue
                    }
                    
                    Clear-Host
                    Write-Host "=====================================" -ForegroundColor DarkCyan
                    Write-Host ">>       TEMA SELECIONADO        <<" -ForegroundColor Cyan
                    Write-Host "=====================================" -ForegroundColor DarkCyan
                    Write-Host
                    Write-Host "Tema: $selectedTheme" -ForegroundColor White
                    Write-Host
                    Write-Host "------ OPÇÕES DISPONIVEIS ------" -ForegroundColor DarkCyan
                    Write-Host
                    Write-Host " [V] --> Visualizar (abre novo prompt)" -ForegroundColor Green
                    Write-Host " [S] --> Salvar e aplicar agora" -ForegroundColor Yellow
                    Write-Host " [C] --> Cancelar OPERACAO" -ForegroundColor Red
                    Write-Host
                    Write-Host "---------------------------------" -ForegroundColor DarkCyan
                    Write-Host "Digite V, S ou C (ou ESC para voltar): " -ForegroundColor Cyan -NoNewline
                    
                    $optionKey = $Host.UI.RawUI.ReadKey("IncludeKeyDown")
                    
                    # Verificar se ESC foi pressionado
                    if ($optionKey.VirtualKeyCode -eq 27) {
                        # Voltar para a lista de seleção
                        continue
                    }
                    
                    $choice = $optionKey.Character.ToString().ToLower()
                    
                    switch ($choice) {
                        'v' {
                            # Visualizar
                            $command = "oh-my-posh init pwsh --config '$themeConfig' | Invoke-Expression"
                            
                            Write-Host
                            Write-Host ">> Abrindo novo prompt com o tema..." -ForegroundColor Cyan
                            Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $command
                            
                            continue
                        }
                        's' {
                            # Salvar
                            Write-Host
                            Write-Host ">> Salvando e aplicando o tema..." -ForegroundColor Yellow
                            Save-ThemeToProfile -ThemeName $selectedTheme
                            Write-Host ">> Tema aplicado com sucesso!" -ForegroundColor Green
                            Start-Sleep -Seconds 2
                            return
                        }
                        'c' {
                            # Voltar ao menu principal
                            Write-Host
                            Write-Host ">> OPERACAO cancelada. Voltando ao menu..." -ForegroundColor Red
                            Start-Sleep -Milliseconds 800
                            continue
                        }
                        default {
                            Write-Host
                            Write-Host ">> Opcao Invalida. Voltando ao menu principal..." -ForegroundColor Red
                            Start-Sleep -Seconds 1
                            continue
                        }
                    }
                }
                27 { # ESC - Na tela principal
                    Clear-Host
                    Write-Host "=====================================" -ForegroundColor DarkCyan
                    Write-Host ">>      OPERACAO CANCELADA       <<" -ForegroundColor Yellow
                    Write-Host "=====================================" -ForegroundColor DarkCyan
                    Write-Host
                    Write-Host "Obrigado por usar o Seletor de Temas!" -ForegroundColor Cyan
                    Write-Host
                    return
                }
            }
        }
    }
    finally {
        [Console]::CursorVisible = $originalCursor
    }
}

# Função para aplicar tema específico
function Apply-SpecificTheme {
    param (
        [string]$ThemeName
    )
    
    # Verificar se o tema existe
    if ($themes -contains $ThemeName) {
        $themeConfig = "$env:POSH_THEMES_PATH\$ThemeName.omp.json"
        
        # Verificar se o arquivo existe
        if (-not (Test-Path $themeConfig)) {
            Write-Host "Erro: O arquivo do tema nao foi encontrado: $themeConfig" -ForegroundColor Red
            Start-Sleep -Seconds 2
            return
        }
        
        Clear-Host
        Write-Host "Tema: $ThemeName" -ForegroundColor Cyan
        Write-Host
        Write-Host "Escolha uma opcao:" -ForegroundColor White
        Write-Host "[V] Visualizar (abre novo prompt)" -ForegroundColor Green
        Write-Host "[S] Salvar e aplicar agora" -ForegroundColor Yellow
        Write-Host "[C] Cancelar" -ForegroundColor Red
        Write-Host
        Write-Host "Digite V, S ou C (ou ESC para voltar): " -ForegroundColor Cyan -NoNewline
        
        $optionKey = $Host.UI.RawUI.ReadKey("IncludeKeyDown")
        
        # Verificar se ESC foi pressionado
        if ($optionKey.VirtualKeyCode -eq 27) {
            # Voltar para o inicio
            Select-OhMyPoshTheme
            return
        }
        
        $choice = $optionKey.Character.ToString().ToLower()
        
        if ($choice -eq 'v') {
            # Visualizar
            $command = "oh-my-posh init pwsh --config '$themeConfig' | Invoke-Expression"
            
            Write-Host
            Write-Host "Abrindo novo prompt com o tema..." -ForegroundColor Cyan
            Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $command
            
            # Perguntar se quer salvar
            Write-Host
            Write-Host "Deseja salvar e aplicar este tema? (S/N): " -ForegroundColor Yellow -NoNewline
            $saveChoice = $Host.UI.RawUI.ReadKey("IncludeKeyDown").Character.ToString().ToLower()
            
            if ($saveChoice -eq 's') {
                Write-Host
                # Salvar tema
                Save-ThemeToProfile -ThemeName $ThemeName
            } else {
                Write-Host
                Write-Host "Tema nao foi salvo." -ForegroundColor Yellow
            }
        }
        elseif ($choice -eq 's') {
            # Salvar
            Save-ThemeToProfile -ThemeName $ThemeName
        }
        elseif ($choice -eq 'c') {
            Clear-Host
            Write-Host "Operacao cancelada." -ForegroundColor Yellow
            Select-OhMyPoshTheme
            return
        }
        else {
            Write-Host
            Write-Host "Opcao invalida." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Apply-SpecificTheme -ThemeName $ThemeName
        }
    }
    else {
        # Tentar pesquisar temas semelhantes
        $similarThemes = $themes | Where-Object { $_ -like "*$ThemeName*" }
        
        if ($similarThemes.Count -gt 0) {
            Clear-Host
            Write-Host "Tema '$ThemeName' nao encontrado exatamente, mas encontramos temas semelhantes:" -ForegroundColor Yellow
            Write-Host
            
            foreach ($theme in $similarThemes) {
                Write-Host "  $theme" -ForegroundColor White
            }
            
            Write-Host
            Write-Host "Deseja selecionar um destes temas? (S/N): " -ForegroundColor Yellow -NoNewline
            $choiceSelect = $Host.UI.RawUI.ReadKey("IncludeKeyDown").Character.ToString().ToLower()
            
            if ($choiceSelect -eq 's') {
                # Iniciar seletor com os temas filtrados
                Select-OhMyPoshTheme
                return
            }
        } else {
            Write-Host "Tema '$ThemeName' nao encontrado." -ForegroundColor Red
            Write-Host "Use o parametro --list para ver temas disponiveis." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
}

# Processamento dos argumentos
$scriptArgs = $args

if ($scriptArgs.Count -gt 0) {
    # Verificar argumentos
    if ($scriptArgs -contains "--help") {
        Show-Help
    }
    elseif ($scriptArgs -contains "--list") {
        List-AllThemes
    }
    else {
        # Verificar se há argumento --theme=
        $themeArg = $scriptArgs | Where-Object { $_ -like "--theme=*" }
        
        if ($themeArg) {
            $themeName = $themeArg.Substring(8)  # Remover "--theme="
            Apply-SpecificTheme -ThemeName $themeName
        }
        else {
            # Se não reconheceu o parâmetro, mostrar ajuda
            Write-Host "Parametro desconhecido." -ForegroundColor Red
            Write-Host "Use --help para ver os parametros disponiveis." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            Show-Help
        }
    }
}
else {
    # Sem argumentos, executar o menu interativo
    Select-OhMyPoshTheme
}