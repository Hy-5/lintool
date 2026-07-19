---WIP---</br>
Small install script to auto install my personal linux toolstack on VM/LXC provisionning.</br>

[Optional Flags]
* -tmux 
* -nvim

Bash install command example:
Updated to be used with subdomain:</br>
`curl -fsSL lin.ismco.me | bash -s -- <OptionalFlag>`

<OptionalFlag> :
- tmux
- nvim

Bash delete command example:
`curl -fsSL lin.ismco.me | bash -s -- -del nvim`

Initially used with:</br>
`curl -fsSL https://raw.githubusercontent.com/Hy-5/lintool/main/lintool.sh | bash -s -- <OptionalFlag>`

By default, without flag, installs all.
