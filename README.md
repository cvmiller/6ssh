## Synopsis

A bash script which calls `ssh` bound to a the local IPv6 Stable SLAAC address. Enables persistent `ssh` sessions across laptop sleep/awake cycles.

### Why?

By default IPv6 will use temporary addresses ([RFC 8981](https://www.rfc-editor.org/rfc/rfc8981)) for outbound connections, including `ssh`. While it possible to disable this *feature*, in most cases I prefer temporary addresses to be used (e.g. `https` sessions). 

However, in the modern world, putting a laptop to sleep, will cause `systemd` to generate new temporary addresses, and the `ssh` connection will **not** be restored after waking up the laptop.

By *binding* the `ssh` session to a local Stable SLAAC address, the `ssh` session will remain connected after the laptop wakes up from sleep and reconnects to the network.

## Motivation

Apparently, I put my laptop to sleep a lot. I grew tired of re-establishing my `ssh` session, and all my GUI X-forwarded apps (mostly editors) as well.

By *binding* the `ssh` session with the `-b <address>` parameter, the sessions remain up, even through short sleeps.

This script merely automates the process of finding which interface has a valid Stable SLAAC Address, and then calls `ssh` with the appropriate *bind address*. 


## The Script

The script checks all the interfaces for a Stable SLAAC Address, and uses the first one it finds for the `ssh` session. 

### Help

Like any script there is help. With this first release there is only `-i <interface>` which allows the user to control which interface is used, and `-X` for X11 forwarding. 

```
$ ./6ssh.sh -h
	./6ssh.sh - ssh using Stable SLAAC Source Address 
	e.g. ./6ssh.sh <host> 
	-i  use this interface
	-X  use X forwarding
	
```


### Why Bash?

Bash is terrible at string handling, why write this script in bash? Because I wanted it to run on my router (OpenWRT), and just about every where else, with the minimal amount of dependencies. It is possible to run Python on OpenWRT, but Python requires more storage (more packages) than just `bash`.



## Dependencies
The script is dependent on `bash`, `ip`, and `grep`, both of which should be readily available on any linux distro.

BSD support (as of v0.9.2) requires **[ip command emulator](https://raw.githubusercontent.com/cvmiller/v6disc/master/ip_em.sh)**, download and place in same directory as `6ssh.sh`.


## Contributors

All code by Craig Miller cvmiller at gmail dot com. But ideas, and ports to other languages are welcome. 


## License

This project is open source, under the GPLv2 license (see [LICENSE](LICENSE))
