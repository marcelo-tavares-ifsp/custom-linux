# Construindo um Sistema Wayland Minimalista com Budgie Desktop no VirtualBox

Este guia detalha como criar um ambiente gráfico moderno (Wayland) utilizando o Budgie Desktop em uma máquina virtual (VirtualBox), focado em extrema leveza e modularidade.

### O Ponto de Partida: Debian *testing* (Modo Texto)

Todos os comandos deste tutorial pressupõem que você crie **uma instalação limpa do Debian sem interface gráfica**. Durante a instalação do sistema operacional, na tela de "Seleção de software" após a instalação do sistema base, **desmarque todas as opções de ambiente de área de trabalho** e deixe marcado apenas os "utilitários padrão do sistema". O resultado será uma instalação básica, inicializando direto no terminal.

Será necessário usar o Debian *testing*, mesmo porque o Debian *stable* durante a redação da primeira versão deste tutorial não tinha suporte a Wayland no Budgie Desktop, por ser uma implementação muito nova. O instalador dessa versão pode ser baixado em <https://www.debian.org/devel/debian-installer/>; apesar do nome a versão *testing* é recomendada para uso em computadores de mesa, enquanto a versão *stable* é mais recomendada para uso em equipamentos servidores.

Para execução e compatibilidade deste tutorial em outros derivados do Debian, é preciso instalar alguns pacotes. Execute no terminal:
```bash
apt install sed sudo
```

---

### Configurando o APT para o minimalismo absoluto

Para garantir que o sistema instale apenas o quê pedimos, sem ocupar o armazenamento interno com programas, jogos ou ferramentas indesejados, vamos alterar o comportamento padrão do gerenciador de pacotes para ignorar "Recomendações" e "Sugestões".

Execute no terminal:
```bash
echo 'APT::Install-Recommends "false";' | sudo tee /etc/apt/apt.conf.d/99-no-recommends

echo 'APT::Install-Suggests "false";' | sudo tee -a /etc/apt/apt.conf.d/99-no-recommends
```
A partir de agora, o APT instalará o quê for estritamente necessário.

---

### Uma instalação Semi-Rolling Release

No ecossistema das distribuições Linux existem aquelas que não possuem versões definidas porque estão em constante atualização, são chamadas de distribuições `Rolling Release`. Para termos uma instalação que equilibre atualizações e estabilidade para *desktops* com o Debian é preciso combinar suas linhas de desenvolvimento numa configuração que é normalmente chamada de `Semi-Rolling Release`.

O Debian tem um processo de qualidade de *software* que divide as versões de programas em três linhas de desenvolvimento principais que são:

- *unstable*: versões de programas que são consideradas estáveis pelos desenvolvedores originais mas que não foram minimamente testadas no Debian;
- *testing*: versões de programas que passaram pelos testes da *unstable* e podem ser considerados adequados para uso individual mas continuam em observação e testes;
- *stable*: versões de programas que passaram um tempo considerável na *testing* e são considerados estáveis e seguros suficientes para uso geral e em servidores.

Nosso Debian `Semi-Rolling Release` será uma combinação de programas das linhas *testing* e *unstable*, com prioridade para instalar os que estiverem na *testing*. Para isso usaremos um recurso de preferências conhecido como APT Pinning, onde os programas em *testing* terão a prioridade padrão (500) e os programas em *unstable* terão prioridade 50 (cinquenta). 

Vamos modernizar as fontes de repositórios de programas e editá-las:
```bash
sudo apt modernize-sources

sudo nano /etc/apt/sources.list.d/debian.sources
```

Acrescente o texto abaixo no final, trocando o endereço em  `URIs` pela o mesma que estiver em outros blocos:
```ini
Types: deb deb-src
URIs: http://mirrors.ic.unicamp.br/debian/
Suites: unstable
Components: main non-free-firmware contrib non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```

Salve, saia (`Ctrl+O`, `Enter`, `Ctrl+X`). Vamos criar o arquivo de prioridades de instalação:

```bash
sudo nano /etc/apt/preferences.d/preferences
```

Coloque o texto a seguir nele:

```
Package:  *
Pin:  release a=unstable
Pin-Priority:  50
```

Salve, saia. Atualize a lista de pacotes e confira a política de prioridades:

```bash
sudo apt update

sudo apt policy
```

Notará que as fontes de programas em *testing* terão o número 500 (quinhentos), indicando maior prioridade de instalação, e os em *unstable* terão 50 (cinquenta).

---

### Instalando a base do Budgie Desktop

Como desativamos as recomendações no passo anterior, precisamos declarar manualmente alguns pacotes vitais (como temas, ícones e orquestradores de sessão) para que o Budgie não inicie em uma tela preta. 

Também usaremos o hífen (`-`) no final de pacotes indesejados para evitar a instalação do antigo servidor X e orquestradores gráficos como o Mutter. Permitiremos propositalmente o `xserver-xorg-core` para satisfazer a dependência de integração do VirtualBox.

Execute os comandos:
```bash
sudo apt update

sudo apt install budgie-desktop labwc greetd tuigreet dbus-user-session libpam-systemd polkitd network-manager fonts-noto virtualbox-guest-utils virtualbox-guest-x11 adwaita-icon-theme hicolor-icon-theme gsettings-desktop-schemas budgie-session gnome-settings-daemon swaybg xdg-desktop-portal-wlr xserver-xorg- xserver-xorg-video-all- mutter-
```

---

### Criando o *script* de inicialização 

A aceleração 3D do VirtualBox atualmente possui conflitos com o Wayland (`wlroots`). Para evitar travamentos, criaremos um *script* que força o sistema a usar renderização gráfica por *software* e configura as variáveis de compatibilidade para que aplicativos do GNOME apareçam no menu.

Crie o arquivo:
```bash
sudo nano /usr/local/bin/start-budgie-vm.sh
```

Cole o seguinte conteúdo:
```bash
#!/bin/bash

# Força o sistema a usar o processador para renderização
export LIBGL_ALWAYS_SOFTWARE=1
export WLR_RENDERER=pixman

# Desativa cursores de hardware (evita travamentos do mouse na VM)
export WLR_NO_HARDWARE_CURSORS=1

# Diz ao menu para exibir aplicativos nativos do Budgie e do GNOME
export XDG_CURRENT_DESKTOP=Budgie:GNOME

# Configuração do teclado para Português do Brasil (ABNT2)
export XKB_DEFAULT_LAYOUT=br
export XKB_DEFAULT_MODEL=abnt2

# Define a hierarquia de pastas de aplicativos (Freedesktop)
export XDG_DATA_DIRS=/usr/local/share:/usr/share

# Inicia a sessão Wayland oficial do Budgie via labwc, enviando avisos (e mensagens de erro) para /dev/null 
exec /usr/bin/startbudgielabwc 2> /dev/null
```

Salve, saia (`Ctrl+O`, `Enter`, `Ctrl+X`) e dê permissão de execução:
```bash
sudo chmod +x /usr/local/bin/start-budgie-vm.sh
```

---

### Configurando o Gerenciador de Login

Precisamos conectar o gerenciador de *login* (`greetd`) ao nosso novo *script*, e também criar um menu personalizado para nossa interface de *login*, o `tuigreet`. Crie a pasta de sessões customizadas e um arquivo para a sessão padrão:

```bash
sudo mkdir -p /etc/greetd/custom-sessions

sudo nano /etc/greetd/custom-sessions/budgie-vm.desktop
```

Copie o conteúdo abaixo no arquivo:

```ini
[Desktop Entry]
Name=Budgie Wayland (VM)
Comment=Sessão otimizada do Budgie para o VirtualBox
Exec=/usr/local/bin/start-budgie-vm.sh
Type=Application
```
Salve e feche.

Edite o arquivo de configuração do `greetd`:
```bash
sudo nano /etc/greetd/config.toml
```

Altere a seção `[default_session]` para ficar assim:
```toml
[default_session]
command = "tuigreet --time --power-shutdown 'systemctl poweroff' --power-reboot 'systemctl reboot' --sessions /etc/greetd/custom-sessions"
user = "_greetd"
```
Salve e feche.

Em seguida, garantiremos que o usuário do `greetd` tenha permissão para desenhar na tela e ler o teclado:
```bash
sudo usermod -aG video,input _greetd
```

Como existirá somente uma sessão, ela vai ser a padrão e única opção no `tuigreet`.

---

### Providenciando compatibilidade com ecossistemas Gnome, KDE e X11
Para finalizar, vamos instalar os aplicativos do Gnome (`gnome-terminal`) e do KDE (`okular`) para compatibilidade com esses ecossistemas, garantindo que suas respectivas janelas de diálogo (portais) funcionem, e que também exista compatibilidade com o legado X11 (`nedit`), tudo isso evitando excesso de bibliotecas visuais de outros ambientes. Também vamos instalar o Firefox ESR em português do Brasil para acesso à Web.

Execute:
```bash
sudo apt install gnome-terminal nedit okular firefox-esr-l10n-pt-br xdg-desktop-portal-gtk xdg-desktop-portal-kde xwayland mutter- xdg-desktop-portal-gnome-
```

Com isso a instalação de diversos aplicativos desses ecossistemas terão compatibilidade facilitada nessa instalação.

---

### Ocultando Aplicações Indesejadas

Podem existir aplicações selecionadas nos programas originais que preferimos ocultar para reduzir possibilidades de confusão pelo usuário, ou seja, reduzir o quê chamamos de carga cognitiva de uso do ambiente gráfico. Como exemplo, usaremos os serviços de *bluetooth* (`blueman`) e filtro de luz azul (`gammastep`), que são desnecessários na máquina virtual e também não foram selecionados, simplesmente vieram junto. Como são dependências do ambiente, não devemos desinstalá-los, mas sim bloqueá-los ou ocultá-los.

Para impedir que os ícones carreguem na bandeja do painel próximo ao relógio, injetamos a regra `Hidden=true` nos arquivos de autostart globais:

```bash
sudo sed -i '/^\[Desktop Entry\]/a Hidden=true' /etc/xdg/autostart/blueman.desktop

sudo sed -i '/^\[Desktop Entry\]/a Hidden=true' /etc/xdg/autostart/gammastep-indicator.desktop
```

Para tirar esses programas do menu de aplicativos, criamos máscaras de sobreposição numa pasta local conforme padrões [freedesktop.org](https://pt.wikipedia.org/wiki/Freedesktop.org), injetando a regra `NoDisplay=true` na seção `[Desktop Entry]`:

```bash
# Criar o diretório para as máscaras se não existir
sudo mkdir -p /usr/local/share/applications

# Copiar os atalhos originais
sudo cp /usr/share/applications/gammastep-indicator.desktop /usr/local/share/applications/
sudo cp /usr/share/applications/blueman-manager.desktop /usr/local/share/applications/

# Injetar a regra de ocultação
sudo sed -i '/^\[Desktop Entry\]/a NoDisplay=true' /usr/local/share/applications/gammastep-indicator.desktop
sudo sed -i '/^\[Desktop Entry\]/a NoDisplay=true' /usr/local/share/applications/blueman-manager.desktop

# Atualizar o banco de dados de aplicativos do Freedesktop
sudo update-desktop-database /usr/local/share/applications/
```

O Budgie Desktop possui uma pasta que tem prioridade sobre as regras globais (`/usr/share/budgie-desktop/applications`). Para impedir que o pacote do *bluetooth* reapareça no menu por esse meio (mesmo após atualizações do APT), utilizamos o recurso de desvio de instalações do Debian para evitar que determinados arquivos sejam reconhecidos e utilizados:

```bash
# Desativar o Gerenciador de Bluetooth nativo do Budgie
sudo dpkg-divert --divert /usr/share/budgie-desktop/applications/blueman-manager.desktop.disabled --rename /usr/share/budgie-desktop/applications/blueman-manager.desktop

# Desativar o aplicativo Adaptadores Bluetooth nativo do Budgie
sudo dpkg-divert --divert /usr/share/budgie-desktop/applications/blueman-adapters.desktop.disabled --rename /usr/share/budgie-desktop/applications/blueman-adapters.desktop
```

---

### Ativação Final

Com todas as peças no lugar, limpe o cache de pacotes, ative os serviços a seguir para que iniciem automaticamente no boot e reinicie a máquina:

```bash
sudo apt clean
sudo systemctl enable NetworkManager.service
sudo systemctl enable greetd.service
sudo systemctl reboot
```

Ao retornar, faça login pelo `tuigreet`. O Budgie Desktop com Wayland será iniciado e teremos um ambiente gráfico limpo, veloz, capaz de rodar aplicativos Gnome, KDE e X11.
