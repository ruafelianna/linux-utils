# \u user
# \h host
# \w pwd

source $HOME/.bashrc.d/colors.sh

set_ps1() {
  PS1="$BB$up_corner$BY[ $1\u$BY@$BB\h $BY]$BB:$BY[ $BB\w $BY]$R\n$BB$down_corner$BY[ $BB\$ $BY] $R"
}

# up_corner='.-'
# down_corner='|___'

# if you have unicode support:
# up_corner='┌╴'
# down_corner='└─╴'

# normal user
# set_ps1 $BP

# root user
# set_ps1 $BR
