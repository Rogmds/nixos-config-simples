
# Configuração de referência: NixOS + KDE Plasma
#
# Este arquivo representa uma configuração pessoal.
# Antes de utilizá-lo, revise as opções e adapte-as ao seu hardware.
# Consulte: https://nixos.org/manual/nixos/stable/
#
# IMPORTANTE:
# - Ajuste o nome de usuário e o login automático.
# - Substitua os UUIDs de exemplo pelos valores do seu sistema.
# - Revise as regras de montagem e o Polkit antes de aplicá-las.
# - Este arquivo pressupõe a existência de hardware-configuration.nix.

{ config, pkgs, ... }:

{
  # =========================================================
  # HARDWARE E SISTEMAS DE ARQUIVOS
  # =========================================================

  imports = [
    ./hardware-configuration.nix
  ];

  # Exemplo de montagem de um volume adicional.
  # Substitua o UUID pelo do volume que deseja montar.
  fileSystems."/mnt/vms" = {
    device = "/dev/disk/by-uuid/SUBSTITUA-PELO-UUID-DO-VOLUME";
    fsType = "ext4";
    options = [ "x-gvfs-hide" ];
  };

  # Oculta o volume da montagem automática pelo UDisks.
  # O UUID deve corresponder ao volume acima.
  services.udev.extraRules = ''
    ENV{ID_FS_UUID}=="SUBSTITUA-PELO-UUID-DO-VOLUME", ENV{UDISKS_IGNORE}="1"
  '';

  # Exemplo de regra Polkit para autorizar a montagem
  # de um volume específico pelo usuário escolhido.
  # Revise o usuário, o UUID e a necessidade desta regra.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "SEU_USUARIO" &&
          action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
          action.lookup("id.uuid") == "SUBSTITUA-PELO-UUID-AUTORIZADO") {
        return polkit.Result.YES;
      }
    });
  '';

  # =========================================================
  # INICIALIZAÇÃO
  # =========================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  # Limpeza automática de gerações antigas.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # =========================================================
  # REDE
  # =========================================================

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Portas utilizadas pelo LocalSend nesta configuração.
  # Ajuste o firewall conforme a necessidade da sua rede.

  # =========================================================
  # LOCALIZAÇÃO E TECLADO
  # =========================================================

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };

  console.keyMap = "br-abnt2";

  # =========================================================
  # AMBIENTE GRÁFICO: KDE PLASMA
  # =========================================================

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Login automático: adapte ao seu usuário e às suas necessidades.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "SEU_USUARIO";

  # =========================================================
  # ÁUDIO
  # =========================================================

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # JACK, se necessário:
    # jack.enable = true;
  };

  # =========================================================
  # BLUETOOTH
  # =========================================================

  hardware.bluetooth.enable = true;

  # =========================================================
  # IMPRESSÃO E DESCOBERTA DE DISPOSITIVOS
  # =========================================================

  services.printing.enable = true;

  services.printing.drivers = with pkgs; [
    hplip
  ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # =========================================================
  # ZSH
  # =========================================================

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      rebuild = "sudo nixos-rebuild switch";
      atualizar = "sudo nixos-rebuild switch --upgrade";
      historico = "nix --extra-experimental-features nix-command profile diff-closures --profile /nix/var/nix/profiles/system";
    };

    promptInit = ''
      PROMPT='%F{green}%n@%m%f:%~ > '
    '';
  };

  # =========================================================
  # PROGRAMAS DO SISTEMA
  # =========================================================

  environment.systemPackages = with pkgs; [
    # Ferramentas do sistema
    vim
    wget
    pciutils
    usbutils
    git
    curl
    btop
    nmap
    fastfetch
    lm_sensors
    iw
    ethtool
    file
    tree
    unzip
    zip
    killall
    pstree
    ncdu
    inxi
    wl-clipboard

    # KDE
    kdePackages.kcalc
    kdePackages.skanlite
    kdePackages.ksystemlog
    kdePackages.partitionmanager
    kdePackages.filelight

    # Jogos
    kdePackages.kpat
    kdePackages.ksudoku
    kdePackages.kmines
    kdePackages.kmahjongg

    # Gráficos
    kdePackages.kolourpaint
    gimp

    # Internet e acesso remoto
    kdePackages.ktorrent
    remmina
    wireshark
    localsend

    # Multimídia
    ffmpeg
    vlc
    handbrake
    shotcut

    # Escritório
    libreoffice

    # Impressão
    hplip

    # Virtualização
    virt-manager

    # Outros
    papirus-icon-theme
    conky
  ];

  # =========================================================
  # USUÁRIO
  # =========================================================

  users.users."SEU_USUARIO" = {
    isNormalUser = true;
    description = "Seu nome";
    shell = pkgs.zsh;

    extraGroups = [
      "networkmanager"
      "wheel"
      "wireshark"
      "libvirtd"
    ];

    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # =========================================================
  # FIREFOX E WIRESHARK
  # =========================================================

  programs.firefox.enable = true;
  programs.wireshark.enable = true;

  # =========================================================
  # ARMAZENAMENTO E VIRTUALIZAÇÃO
  # =========================================================

  services.fstrim.enable = true;
  virtualisation.libvirtd.enable = true;

  # =========================================================
  # PACOTES NÃO LIVRES
  # =========================================================

  nixpkgs.config.allowUnfree = true;

  # =========================================================
  # VERSÃO DO ESTADO DO SISTEMA
  # =========================================================

  # Mantenha o valor correspondente à instalação original.
  system.stateVersion = "26.05";
}
