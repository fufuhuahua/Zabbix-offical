#!/usr/bin/perl

#
# Zabbix
# Copyright (C) 2000-2011 Zabbix SIA
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

#########################################
#### ABOUT ZABBIX SNMP TRAP RECEIVER ####
#########################################

# This is an embedded perl SNMP trapper receiver designed for sending data to the server.
# The receiver will pass the received SNMP traps to Zabbix server or proxy running on the
# same machine. Please configure the server/proxy accordingly.
#
# Read more about using embedded perl with Net-SNMP:
#	http://net-snmp.sourceforge.net/wiki/index.php/Tut:Extending_snmpd_using_perl

#################################################
#### ZABBIX SNMP TRAP RECEIVER CONFIGURATION ####
#################################################

### Option: SNMPTrapperfile
#	Temporary file used for passing data to the server (or proxy). Must be the same
#		as in server (or proxy) configuration file.
#
# Mandatory: yes
# Default:
$SNMPTrapperfile = '/tmp/zabbix_traps.tmp';

### Option: DateTimeFormat
#	The date time format in strftime() format. Please make sure to have a corresponding
#               log time format for the SNMP trap items.
#
# Mandatory: yes
# Default:
$DateTimeFormat = '%H:%M:%S %Y/%m/%d';

###################################
#### ZABBIX SNMP TRAP RECEIVER ####
###################################

use Fcntl qw(O_WRONLY O_APPEND O_CREAT);
use POSIX qw(strftime);

sub zabbix_receiver
{
	my (%pdu_info) = %{$_[0]};
	my (@varbinds) = @{$_[1]};

	# open the output file
	sysopen(OUTPUT_FILE, $SNMPTrapperfile, O_WRONLY|O_APPEND|O_CREAT, 0666) or
		die "Cannot open [$SNMPTrapperfile]: $!\n";

	# get the host name
	my $hostname = $pdu_info{'receivedfrom'} || 'unknown';
	if ($hostname ne 'unknown') {
		$hostname =~ /\[(.*?)\].*/;                    # format: "UDP: [127.0.0.1]:41070->[127.0.0.1]"
		$hostname = $1 || 'unknown';
	}

	# print trap header - the format is "ZBXTRAP [IP] [TIMESTAMP]"
	printf OUTPUT_FILE "ZBXTRAP %s %s\n", $hostname, strftime($DateTimeFormat, localtime);

	# print the PDU info
	print OUTPUT_FILE "PDU INFO:\n";
	foreach my $key(keys(%pdu_info))
	{
		printf OUTPUT_FILE "  %-30s %s\n", $key, $pdu_info{$key};
	}

	# print the variable bindings:
	print OUTPUT_FILE "VARBINDS:\n";
	foreach my $x (@varbinds)
	{
		printf OUTPUT_FILE "  %-30s type=%-2d value=%s\n", $x->[0], $x->[2], $x->[1]; 
	}

	close (OUTPUT_FILE);
}

NetSNMP::TrapReceiver::register("all", \&zabbix_receiver) or
	warn "failed to register Zabbix SNMP trap receiver\n";

print STDOUT "Loaded Zabbix SNMP trap receiver\n";
