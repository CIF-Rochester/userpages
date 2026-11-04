# User Pages!  

This one is very simple... Turns out that it's pretty simple to set up user pages like this! 

Our default setup here, is that everything in /home/$USERNAME/www is served via apache, publically.  This is fairly standard, or at least used to be some time ago. 

## Functionality

This repo serves the following functionality

- Automatically create an index of all users that have the potential of having a webpage.  
- Automatically serve any files in /home/$USERNAME/www to http://users.cif.rochester.edu/users/$USERNAME

## That's pretty cool!

Yep, we know.  : )  Web hosting comes with an account at CIF, so if you want to set one up, don't hesitate to create an account!  You can do so at http://cif.rochester.edu/account if you have an affiliation with the University of Rochester.  

# Setup?

I'm going to presume that you are going to be installing this on a Debian computer, and have apache already installed.  If you wish to run this on a nother distribution, you will likely need to change all the paths listed below.  

The index itself is created by `scripts/userpage_generate.sh`.  You should create a directory (We default to `/web`), and place this script in that location.  This script, when run, will create a file called index.html, which should be served by apache.  Of note, is that this script should be run via crontab, as the root user.  I have this set to run daily at 2:30 AM, but that is a completely arbitrary time.  

There is a conf file in `conf-enabled/user-websites.conf`.  This is really what tells apache where files are, and what to serve for each user.  As mentioned before, users.cif.rochester.edu/users/$USERNAME, maps to the local directory /home/$USERNAME/www.  This should be placed in the `/etc/apache2/conf-enabled` directory on your system.  

There is another conf file in `sites-enabled/users.conf`.  This one is a very basic VHost setup for apache, that redirects traffic to users.cif.rochester.edu to users.cif.rochester.edu/users.  This should be palced in `/etc/apache2/sites-enabled` on your system.  

