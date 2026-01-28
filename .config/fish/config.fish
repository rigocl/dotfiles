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
    set -l inhibitors (systemd-inhibit --list --no-legend 2>/dev/null | grep -v "PowerDevil\|Screen Locker\|NetworkManager\|Realtime Kit\|UPower")
    if test -n "$inhibitors"
        echo
        set_color --bold cyan
        echo "Sleep inhibitors active:"
        set_color normal
        echo "$inhibitors" | while read -l line
            set -l who (echo $line | awk '{print $1}')
            set -l why (echo $line | awk '{for(i=7;i<=NF-1;i++) printf $i" "; print ""}')
            echo "  - $who: $why"
        end
        echo
    end
end
