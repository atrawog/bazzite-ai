# vim: set ft=make :

# Install fonts from brew
[group("apps")]
install-fonts:
    #!/usr/bin/bash
    echo "Installing extra fonts..."
    brew bundle --file=/usr/share/ublue-os/homebrew/bazzite-ai-fonts.Brewfile

# Install development tools flatpaks
[group("apps")]
install-flatpaks-dev:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Development Tools Flatpaks${normal}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    APPS=("org.flatpak.Builder.BaseApp" "io.podman_desktop.PodmanDesktop" "io.github.dvlv.boxbuddyrs" "io.github.flattool.Warehouse" "it.mijorus.gearlever" "com.github.tchx84.Flatseal" "org.sqlitebrowser.sqlitebrowser" "org.virt_manager.virt-manager")
    for app in "${APPS[@]}"; do
        if ! flatpak list --columns=application | grep -q "^${app}$"; then
            echo -e "  ${bold}Installing ${app}...${normal}"
            flatpak install --system -y flathub "$app" || echo -e "  ${yellow}⚠ Failed: ${app}${normal}"
        else
            echo -e "  ${green}✓ ${app}${normal}"
        fi
    done
    echo -e "${green}${bold}Done!${normal}"

# Install media and graphics flatpaks
[group("apps")]
install-flatpaks-media:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Media & Graphics Flatpaks${normal}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    APPS=("org.blender.Blender" "org.gimp.GIMP" "org.inkscape.Inkscape" "org.kde.kdenlive" "org.kde.haruna" "org.kde.gwenview" "com.prusa3d.PrusaSlicer" "com.github.iwalton3.jellyfin-media-player" "org.jellyfin.JellyfinServer")
    for app in "${APPS[@]}"; do
        if ! flatpak list --columns=application | grep -q "^${app}$"; then
            echo -e "  ${bold}Installing ${app}...${normal}"
            flatpak install --system -y flathub "$app" || echo -e "  ${yellow}⚠ Failed: ${app}${normal}"
        else
            echo -e "  ${green}✓ ${app}${normal}"
        fi
    done
    echo -e "${green}${bold}Done!${normal}"

# Install gaming tools flatpaks
[group("apps")]
install-flatpaks-gaming:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Gaming Tools Flatpaks${normal}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    APPS=("com.github.Matoking.protontricks" "io.github.fastrizwaan.WineZGUI" "net.davidotek.pupgui2" "net.supertuxkart.SuperTuxKart")
    for app in "${APPS[@]}"; do
        if ! flatpak list --columns=application | grep -q "^${app}$"; then
            echo -e "  ${bold}Installing ${app}...${normal}"
            flatpak install --system -y flathub "$app" || echo -e "  ${yellow}⚠ Failed: ${app}${normal}"
        else
            echo -e "  ${green}✓ ${app}${normal}"
        fi
    done
    echo -e "${green}${bold}Done!${normal}"

# Install communication flatpaks
[group("apps")]
install-flatpaks-communication:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Communication Flatpaks${normal}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    APPS=("com.discordapp.Discord" "org.signal.Signal" "org.squidowl.halloy")
    for app in "${APPS[@]}"; do
        if ! flatpak list --columns=application | grep -q "^${app}$"; then
            echo -e "  ${bold}Installing ${app}...${normal}"
            flatpak install --system -y flathub "$app" || echo -e "  ${yellow}⚠ Failed: ${app}${normal}"
        else
            echo -e "  ${green}✓ ${app}${normal}"
        fi
    done
    echo -e "${green}${bold}Done!${normal}"

# Install productivity flatpaks
[group("apps")]
install-flatpaks-productivity:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Productivity Flatpaks${normal}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    APPS=("org.mozilla.firefox" "com.google.Chrome" "org.kde.kcalc" "org.kde.kcolorchooser" "org.kde.filelight" "org.kde.okular" "org.qgis.qgis")
    for app in "${APPS[@]}"; do
        if ! flatpak list --columns=application | grep -q "^${app}$"; then
            echo -e "  ${bold}Installing ${app}...${normal}"
            flatpak install --system -y flathub "$app" || echo -e "  ${yellow}⚠ Failed: ${app}${normal}"
        else
            echo -e "  ${green}✓ ${app}${normal}"
        fi
    done
    echo -e "${green}${bold}Done!${normal}"

# Install utilities flatpaks
[group("apps")]
install-flatpaks-utilities:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Utilities Flatpaks${normal}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    APPS=("org.remmina.Remmina" "org.kde.krdc" "com.github.unrud.VideoDownloader" "de.leopoldluley.Clapgrep" "org.fkoehler.KTailctl")
    for app in "${APPS[@]}"; do
        if ! flatpak list --columns=application | grep -q "^${app}$"; then
            echo -e "  ${bold}Installing ${app}...${normal}"
            flatpak install --system -y flathub "$app" || echo -e "  ${yellow}⚠ Failed: ${app}${normal}"
        else
            echo -e "  ${green}✓ ${app}${normal}"
        fi
    done
    echo -e "${green}${bold}Done!${normal}"

# Install experimental flatpaks
[group("apps")]
install-flatpaks-experimental:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing Experimental Flatpaks${normal}"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    APPS=("io.github.Dretch.MonomerFlatpakExample" "com.parsecgaming.parsec")
    for app in "${APPS[@]}"; do
        if ! flatpak list --columns=application | grep -q "^${app}$"; then
            echo -e "  ${bold}Installing ${app}...${normal}"
            flatpak install --system -y flathub "$app" || echo -e "  ${yellow}⚠ Failed: ${app}${normal}"
        else
            echo -e "  ${green}✓ ${app}${normal}"
        fi
    done
    echo -e "${green}${bold}Done!${normal}"

# Install all flatpaks
[group("apps")]
install-flatpaks-all:
    #!/usr/bin/bash
    set -euo pipefail
    source /usr/lib/ujust/ujust.sh 2>/dev/null || true

    echo -e "${bold}Installing All Flatpaks (38 total)${normal}"
    echo ""

    just install-flatpaks-dev
    just install-flatpaks-media
    just install-flatpaks-gaming
    just install-flatpaks-communication
    just install-flatpaks-productivity
    just install-flatpaks-utilities
    just install-flatpaks-experimental

    echo ""
    echo -e "${green}${bold}✓ All flatpaks installed!${normal}"
