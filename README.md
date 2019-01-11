ZHdK Switch-AAI Shibboleth leihs Authentication-System
======================================================

This repository hosts code to authenticate users via
[SWITCHaai](https://www.switch.ch/aai/) for the [_leihs_](https://github.com/leihs/leihs) 
instance of the ZHdK.

The resulting service uses the external authentication-system (TODO link to
documentation) of leihs. 


Production Set-up and Deployment
--------------------------------

### Switch AAI Configuration and Registration

Configure your server according to [SWITCH Shibboleth Service Provider (SP) 3.0 Configuration Guide
](https://www.switch.ch/aai/guides/sp/configuration/)
and register your application with the [AAI Resource Registry](https://rr.aai.switch.ch/).


#### Debian Notes

At the time of writing Switch files for Shibboleth 3.0 werent available yet for
Debian 9. It is possible to install shiboleth 2.6 and using the documentation
for version 2.5 

* https://www.switch.ch/aai/guides/sp/configuration-2.5/?osType=nonwindows&os=debian&federation=SWITCHaai&hostname=aai.leihs.zhdk.ch&entityID=https%3A%2F%2Faai.leihs.zhdk.ch%2Fshibboleth&configDir=%2Fetc%2Fshibboleth%2F&keyPath=%2Fetc%2Fshibboleth%2Fsp-key.pem&certPath=%2Fetc%2Fshibboleth%2Fsp-cert.pem&targetURL=https%3A%2F%2Faai.leihs.zhdk.ch%2FShibboleth.sso%2FSession&supportEmail=aai%40aai.leihs.zhdk.ch&submit=Update+Configuration+Guide+with+above+Data#setupprofile

 
### Deployment 

This project comes with deployment recipies for [ansible](https://docs.ansible.com/). An example invocation 
looks like the following:

		ansible-playbook -i ../zhdk-inventory/aai-hosts  deploy/deploy_play.yml 

We reference our [leihs ZHdK Inventory](https://github.com/leihs/leihs_zhdk-inventory) here. 


Development 
-----------

### Run the application 

1. Install ruby version >= 2.6.0, e.g. with [ruby-install](https://github.com/postmodern/ruby-install).

2. Export the path, e.g. with `bash`

      export PATH=~/.rubies/ruby-2.6.0/bin:$PATH

3. Install dependencies

      bundle

4. Start the server

      bundle exec passenger start --port 4000

5. Set up (per request) automatic Reloading (optional)

      touch tmp/always_restart.txt

### Prototyping and debugging

Try 

		curl http://localhost:4000/debug

and 

		bundle exec pry-remote

in a separate terminal.
	


