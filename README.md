# kali-zsh-anywhere

Traz o visual e o prompt do Zsh do Kali Linux (`┌──(user㉿host)-[~]`) para **qualquer distro
Linux compatível** — Debian, Ubuntu, Arch, Fedora, openSUSE, Alpine e derivados.

## O que o script faz

1. Detecta o gerenciador de pacotes da sua distro (`apt`, `pacman`, `dnf`, `zypper`, `apk`).
2. Instala as dependências (`zsh`, `git`, `curl`, fontes powerline).
3. Aplica o prompt do Kali de uma das duas formas:
   - **Modo nativo** (`--native`, só em Debian/Ubuntu/Kali): baixa o `.zshrc` oficial
     direto do repositório do Kali (`kali-defaults`).
   - **Modo oh-my-zsh** (padrão, funciona em qualquer distro): instala o
     [oh-my-zsh](https://ohmyz.sh/), ativa o tema `kali` já incluso nele e adiciona os
     plugins `zsh-autosuggestions`, `zsh-syntax-highlighting` e `zsh-completions`.
4. Faz backup automático do `.zshrc` anterior antes de qualquer alteração.
5. Define o `zsh` como shell padrão do usuário.
6. Opcionalmente aplica tudo isso também para o `root` (`--root`).

## Uso rápido

```bash
git clone https://github.com/SEU_USUARIO/kali-zsh-anywhere.git
cd kali-zsh-anywhere
chmod +x install.sh
./install.sh
```

### Instalar também para o root

```bash
./install.sh --root
```

### Forçar o `.zshrc` oficial do Kali (Debian/Ubuntu/Kali apenas)

```bash
./install.sh --native
```

### Desfazer (restaura o backup mais recente)

```bash
./install.sh --uninstall
```

### Instalação em uma linha (sem clonar o repo)

```bash
curl -fsSL https://raw.githubusercontent.com/SEU_USUARIO/kali-zsh-anywhere/main/install.sh | bash
```

> Troque `SEU_USUARIO` pelo seu usuário/organização do GitHub depois de publicar o repositório.

## Distros testadas

| Distro            | Gerenciador | Modo recomendado |
|--------------------|-------------|-------------------|
| Debian / Kali      | apt         | `--native` ou padrão |
| Ubuntu / Mint       | apt         | padrão (oh-my-zsh)   |
| Arch / Manjaro      | pacman      | padrão (oh-my-zsh)   |
| Fedora              | dnf         | padrão (oh-my-zsh)   |
| openSUSE            | zypper      | padrão (oh-my-zsh)   |
| Alpine              | apk         | padrão (oh-my-zsh)   |

## Estrutura do repositório

```
kali-zsh-anywhere/
├── install.sh      # script principal
├── README.md
├── LICENSE
└── .gitignore
```

## Como funciona o modo oh-my-zsh

O tema `kali` já vem embutido no oh-my-zsh (não precisa baixar nada extra para o prompt em
si). O script apenas:

- Clona os plugins `zsh-autosuggestions`, `zsh-syntax-highlighting` e `zsh-completions`
  para `~/.oh-my-zsh/custom/plugins/`.
- Gera um `.zshrc` novo com `ZSH_THEME="kali"` e esses plugins habilitados.

## Segurança

O script nunca sobrescreve um `.zshrc` sem antes criar um backup com timestamp
(`~/.zshrc.bak.AAAAMMDD-HHMMSS`). Use `--uninstall` a qualquer momento para reverter.

## Licença

MIT — veja [LICENSE](LICENSE).
