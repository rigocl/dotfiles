source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
#
# https://sameemul-haque.vercel.app/blog/dotfiles
function config
    /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
end

function mpv-hdr
    ENABLE_HDR_WSI=1 mpv $argv
end

# Monthly maintenance reminder
if status is-interactive
    set -l log_dir "$HOME/.local/var/log"
    set -l logs $log_dir/spring-clean-*.log
    set -l needs_reminder 1

    if test -e "$logs[1]"
        set -l latest_time 0
        for log in $logs
            set -l mtime (stat -c %Y "$log")
            if test $mtime -gt $latest_time
                set latest_time $mtime
            end
        end
        set -l file_age (math (date +%s) - $latest_time)
        if test $file_age -lt 2592000
            set needs_reminder 0
        end
    end

    if test $needs_reminder -eq 1
        echo
        set_color --bold yellow
        echo "***************************************************"
        echo "*                                                 *"
        echo "*         SYSTEM MAINTENANCE OVERDUE              *"
        echo "*   ~/.config/scripts/sysmaintenance.sh           *"
        echo "*   Use --upgrade to include system update        *"
        echo "*                                                 *"
        echo "***************************************************"
        set_color normal
        echo
    end

    # Show sleep inhibitors (services preventing sleep)
    # Parse column positions from header so it adapts to any column width
    set -l raw_output (systemd-inhibit --list 2>/dev/null)
    if test (count $raw_output) -gt 2
        set -l header $raw_output[1]
        # Find column start positions from the header to handle any width
        set -l col_who (string match -r -n 'WHO' "$header" | string replace -r '(\d+).*' '$1')
        set -l col_uid (string match -r -n 'UID' "$header" | string replace -r '(\d+).*' '$1')
        set -l col_pid (string match -r -n 'PID' "$header" | string replace -r '(\d+).*' '$1')
        set -l col_comm (string match -r -n 'COMM' "$header" | string replace -r '(\d+).*' '$1')
        set -l col_what (string match -r -n 'WHAT' "$header" | string replace -r '(\d+).*' '$1')
        set -l col_mode (string match -r -n 'MODE' "$header" | string replace -r '(\d+).*' '$1')

        set -l shown 0
        for line in $raw_output[2..-2] # skip header and "N inhibitors listed." footer
            test -z "$line"; and continue
            # Skip known system inhibitors
            string match -q '*PowerDevil*' "$line"; and continue
            string match -q '*Screen Locker*' "$line"; and continue
            string match -q '*NetworkManager*' "$line"; and continue
            string match -q '*Realtime Kit*' "$line"; and continue
            string match -q '*UPower*' "$line"; and continue

            set -l who (printf '%s' "$line" | cut -c$col_who-(math $col_uid - 1) | string trim)
            set -l pid (printf '%s' "$line" | cut -c$col_pid-(math $col_comm - 1) | string trim)
            set -l comm (printf '%s' "$line" | cut -c$col_comm-(math $col_what - 1) | string trim)
            set -l mode (printf '%s' "$line" | cut -c$col_mode- | string trim)

            # Resolve a friendly name from the process command line
            set -l label "$comm"
            if test "$comm" = "code-oss" -o "$comm" = "code"
                set -l workspace (ps -p $pid -o args= 2>/dev/null | string match -r '/home/\S+' | path basename)
                if test -n "$workspace"
                    set label "Code OSS ($workspace)"
                else
                    set label "Code OSS"
                end
            else if test "$comm" = "electron" -o "$comm" = "chrome" -o "$comm" = "chromium"
                set -l cmdline (ps -p $pid -o args= 2>/dev/null)
                set -l app_name (echo $cmdline | string match -r '(?:--app-name=|/lib/)(\S+)' | tail -1)
                if test -n "$app_name"
                    set label "$app_name"
                else
                    set label "$comm (PID $pid)"
                end
            else if test "$comm" = "systemd-inhibit"
                # systemd-inhibit wraps another service — use WHO instead
                set label "$who"
            end

            if test $shown -eq 0
                echo
                set_color --bold cyan
                echo "Sleep inhibitors active:"
                set_color normal
                set shown 1
            end
            echo "  - $label [$mode]"
        end
        if test $shown -eq 1
            echo
        end
    end

    # Dotfiles reminder
    set_color --dim
    echo "dotfiles: config status | config add <file> | config commit | config push"
    set_color normal
    set -l dotfile_changes (/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status --porcelain 2>/dev/null)
    if test -n "$dotfile_changes"
        set_color --bold yellow
        echo "Uncommitted dotfile changes:"
        set_color normal
        for change in $dotfile_changes
            echo "  $change"
        end
        echo
    end

    # Show screen idle inhibitors (apps preventing screen dimming)
    set -l screen_raw (qdbus6 --literal org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/PolicyAgent org.kde.Solid.PowerManagement.PolicyAgent.ListInhibitions 2>/dev/null)
    if test -n "$screen_raw"
        # Parse the aas format: {{app, reason}, {app, reason}, ...}
        set -l pairs (string match -r -a '"[^"]*",\s*"[^"]*"' "$screen_raw")
        if test (count $pairs) -gt 0
            set_color --bold magenta
            echo "Screen inhibitors active:"
            set_color normal
            for pair in $pairs
                set -l parts (string match -r -a '"([^"]*)"' "$pair")
                # parts[1] is full match, parts[2] is app, parts[3] is full match, parts[4] is reason
                set -l app (path basename "$parts[2]")
                set -l reason "$parts[4]"
                echo "  - $app: $reason"
            end
            echo
        end
    end
end
