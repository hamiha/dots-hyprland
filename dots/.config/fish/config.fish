function hypr_move
    for i in (seq 1 10)
        hyprctl dispatch "hl.dsp.workspace.move({ workspace = $i, monitor = 'eDP-1' })"
    end
end

function nvm
    bash -c "source $HOME/.nvm/nvm.sh; nvm $argv"
end

# set -gx XDG_DATA_DIRS /usr/local/share:/usr/share

fish_add_path /home/hai/.npm-global/bin
# 
# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    fastfetch

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != linux
        starship init fish | source
        enable_transience
    end

    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    # alias clear "printf '\033[2J\033[3J\033[1;1H'"
    # alias celar "printf '\033[2J\033[3J\033[1;1H'"
    # alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != linux
        alias ls 'eza --icons'
    end
    if test "$TERM" = xterm-kitty
        alias ssh 'kitten ssh'
    end

    zoxide init fish | source
    direnv hook fish | source
end
