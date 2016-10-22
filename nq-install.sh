#!/bin/bash
#
# NodeQuery Agent Installation Script
#
# @version		1.0.6
# @date			2014-07-30
# @copyright	(c) 2014 http://nodequery.com
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Set environment
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Prepare output
echo -e "|\n|   NodeQuery BSD Installer\n|   ===================\n|"

# Root required
if [ $(id -u) != "0" ];
then
	echo -e "|   Error: You need to be root to install the NodeQuery agent\n|"
	echo -e "|          The agent itself will NOT be running as root but instead under its own non-privileged user\n|"
	exit 1
fi

# Parameters required
if [ $# -lt 1 ]
then
	echo -e "|   Usage: bash $0 'token'\n|"
	exit 1
fi

# Check if crontab is installed
if [ ! -n "$(command -v crontab)" ]
then

	# Confirm crontab installation
	echo "|" && read -p "|   Crontab is required and could not be found. "
	
	if [ ! -n "$(command -v crontab)" ]
	then
	    # Show error
	    echo -e "|\n|   Error: Crontab is required and could not be installed\n|"
	    exit 1
	fi	
fi

# Check if cron is running
if [ -z "$(ps -Al | grep cron | grep -v grep)" ]
then
	
	# Confirm cron service
	echo "|" && read -p "|   Cron is available but not running. Do you want to start it? [Y/n] " input_variable_service

	# Attempt to start cron
	if [ -z $input_variable_service ] || [ $input_variable_service == "Y" ] || [ $input_variable_service == "y" ]
	then
		if [ -n "$(command -v pkg)" ]
		then
			echo -e "|\n|   Notice: Starting 'cron' via 'service'"
			service cron onestart
	fi
	
	# Check if cron was started
	if [ -z "$(ps -Al | grep cron)" ]
	then
		# Show error
		echo -e "|\n|   Error: Cron is available but could not be started\n|"
		exit 1
	fi
fi

# Attempt to delete previous agent
if [ -f /etc/nodequery/nq-agent.sh ]
then
	# Remove agent dir
	rm -Rf /etc/nodequery

	# Remove cron entry and user
	if id -u nodequery >/dev/null 2>&1
	then
		(crontab -u nodequery -l | grep -v "/etc/nodequery/nq-agent.sh") | crontab -u nodequery - && rmuser -y nodequery
	else
		(crontab -u root -l | grep -v "/etc/nodequery/nq-agent.sh") | crontab -u root -
	fi
fi

# Create agent dir
mkdir -p /etc/nodequery

# Download agent
echo -e "|   Downloading nq-agent.sh to /etc/nodequery\n|\n|   + $(wget -nv -o /dev/stdout -O /etc/nodequery/nq-agent.sh --no-check-certificate https://raw.githubusercontent.com/thebitstick/nq-agent-BSD/master/nq-agent.sh)"

if [ -f /etc/nodequery/nq-agent.sh ]
then
	# Create auth file
	echo "$1" > /etc/nodequery/nq-auth.log
	
	# Create user
	pw user add nodequery -d /etc/nodequery -s /usr/bin/false
	
	# Modify user permissions
	chown -R nodequery:nodequery /etc/nodequery && chmod -R 700 /etc/nodequery

	# Configure cron
	crontab -u nodequery -l 2>/dev/null | { cat; echo "*/3 * * * * bash /etc/nodequery/nq-agent.sh > /etc/nodequery/nq-cron.log 2>&1"; } | crontab -u nodequery -
	
	# Show success
	echo -e "|\n|   Success: The NodeQuery agent has been installed\n|"
	
else
	# Show error
	echo -e "|\n|   Error: The NodeQuery agent could not be installed\n|"
fi
fi
