# gitline

## cli for github api v3

### 1. install gitline.sh

`curl 'https://raw.githubusercontent.com/tylerfowle/gitline/master/gitline.sh' > /usr/local/bin/gitline.sh`

### 2. apply permissions to gitline.sh:

`sudo chmod 755 '/usr/local/bin/gitline.sh'`

### 3. add aliases to `~/.bash_profile`:
`alias gitline='/usr/local/bin/gitline.sh'`

`alias gl='/usr/local/bin/gitline.sh'`

### 4. setup a github personal access token
instructions: https://help.github.com/articles/creating-an-access-token-for-command-line-use/

scope:

    repo [x]
  
    repo:status [x]
    
    repo_deployment [x]
    
    public_repo [x]
    
    gist [x]
  
    user [x]
    
    user:email [x]
    
    user:follow [x]


### 5. setup gitline config options
you can set any number of options in any order.
token: personal access token created in step 4.
owner: user or organisation
repo: repo name

`gitline --token=[token] --owner=[owner] --repo=[repo] --username=[your username] --qausername[qa username]`
