# gitline

## cli for github api v3

### 1. Install gitline.sh
##### to install basic version:

`curl 'https://raw.githubusercontent.com/tylerfowle/gitline/master/gitline.sh' > /usr/local/bin/gitline.sh`

##### to install advanced/milestone version:

`curl 'https://raw.githubusercontent.com/tylerfowle/gitline/master/milestones/gitline.sh' > /usr/local/bin/gitline.sh`

### 2.apply permissions to gitline.sh:

`sudo chmod 755 '/usr/local/bin/gitline.sh'`

### 3. add aliases to `~/.bash_profile`:
`alias gitline='/usr/local/bin/gitline.sh'`

`alias gl='/usr/local/bin/gitline.sh'`

### 4. setup gitline config options
`gitline --token=[token] --owner=[owner] --repo=[repo] --username=[your username] --qausername[qa username]`
