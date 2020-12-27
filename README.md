# bash-http-monitoring

![all is well image][1]

HTTP(s) monitoring webpage via shell script. Parallel checking, thus very fast, only dependencies are
curl and bash (version 4 or above). For all of you who want a simple script with a nice webpage to check
a few websites. Perfect for a wall mounted monitoring display and a Raspberry Pi.

Installation and configuration is easy to do inside the script. It scales well, both on the checking side
as the information display page (dense on purpose). Failed checks appear right on top for you to act on.

You can set an expected status code and a max timeout per check, so if you consider your site up when
it returns a 302 (redirect) or 401 (unauthorized) the script consider that okay. If the status code
is not what is configured or there is a timeout or another error, the script considers the check failed.

Author: [Remy van Elst][6]

[Website with more information][8]

## Installation & Configuration

Make sure you have curl installed (`apt install curl`). If you need a very simple webserver, try [micro-httpd, by ACME][5]. (`apt install micro-httpd`).

Clone the git repository:

	git clone https://github.com/RaymiiOrg/bash-http-monitoring.git
	cd bash-http-monitoring

Edit the `srvmon.sh` script and add your sites. A few examples are provided. This is the syntax:

	urls[gists]="https://gist.github.com"
	urls[lobsters]="https://lobste.rs"
	urls[raymii.org]="https://raymii.org"
	urls[example]="http://example.org:3000/this/is/a/test"

The first part between the square brackets is the name, the second part between the quotes is the URL you want
to monitor. It can be just a domain, an IP or an actual URL, including port and such.

If you want to override the default status code for a check, this is the syntax:

	statuscode[gist.github.com]=302

The first part between the square brackets must match the `urls[]` part.

Execute the script and send the output to a file in your webservers documentroot:

	bash srvmon.sh > /var/www/index.html

View that file in a web browser.

### Cronjob setup

If you want to set up a cronjob, send the output to a temp file and when finished, move that temp
file over the "actual" file. Otherwise you might end up with an incomplete page when the checks are 
running. Like so:

	* * * * * /bin/bash /opt/srvmon/srvmon.sh > /var/www/index.html.tmp && /bin/mv /var/www/index.html.tmp /var/www/index.html

If the check fails for whatever reason, the "old" page will not be overridden.


## Screenshots 

All checks are okay:

![all is well image][1]

A check has failed:

![failed checks][2]

Here is how it looks with many hosts (also note how fast it executes, 6 seconds):

![many hosts][4]

This is what the early version looked like:

![beta][3]

I had this script running at home for at least a year in that form, when I showed it to a friend he liked it, 
asked me to make it public, but before I did that I polished it up a bit.


[1]: screenshots/okay.png
[2]: screenshots/fail.png
[3]: screenshots/firstVersion.png
[4]: screenshots/many.png
[5]: https://acme.com/software/micro_httpd/
[6]: https://raymii.org
[8]: https://raymii.org/s/software/Bash_HTTP_Monitoring_Dashboard.html