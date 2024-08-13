#!/bin/bash

set -e

#############
# Variables #
#############

DNS=(192.168.0.1)
NTP=(192.168.0.1)

declare -A INPUT_TCP
declare -A INPUT_UDP
declare -A OUTPUT_TCP
declare -A OUTPUT_UDP

INPUT_TCP['0.0.0.0/0']=''
INPUT_UDP['0.0.0.0/0']=''
OUTPUT_TCP['0.0.0.0/0']=''
OUTPUT_UDP['0.0.0.0/0']=''

ICMP=true
LOOPBACK=true
FORWARDING=true
MIRROR_RULES=true
RESET_CHAINS=true
FLUSH_TABLES=true
RESET_TABLES=true

declare -A LOGGING
LOGGING[ACCEPT]="false"
LOGGING[DROP]="true"
LOGGING[FORWARD_ACCEPT]="true"
LOGGING[FORWARD_DROP]="true"

#######################################

##################
# Reset Firewall #
##################

iptables -F

if [ "$RESET_CHAINS" = "true" ]; then
    iptables -X
fi

if [ "$FLUSH_TABLES" = "true" ]; then
    iptables -t nat -F
    iptables -t mangle -F
fi

if [ "$RESET_TABLES" = "true" ]; then
    iptables -t nat -X
    iptables -t mangle -X
fi

iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

##########
# Chains #
##########

##
# ACCEPT_LOG
##

iptables -N ACCEPT_LOG

if [ "${LOGGING[ACCEPT]}" = "true" ]; then
    iptables -A ACCEPT_LOG -j LOG --log-level 6 --log-prefix ':accept_log: '
fi

iptables -A ACCEPT_LOG -j ACCEPT


##
# DROP_LOG
##

iptables -N DROP_LOG

if [ "${LOGGING[DROP]}" = "true" ]; then
    iptables -A DROP_LOG -j LOG --log-level 6 --log-prefix ':drop_log: '
fi

iptables -A DROP_LOG -j DROP

##
# FORWARD_ACCEPT_LOG
##

iptables -N FORWARD_ACCEPT_LOG

if [ "${LOGGING[FORWARD_ACCEPT]}" = "true" ]; then
    iptables -A FORWARD_ACCEPT_LOG -j LOG --log-level 6 --log-prefix ':forward_accept_log: '
fi

iptables -A FORWARD_ACCEPT_LOG -j ACCEPT

##
# FORWARD_DROP_LOG
##

iptables -N FORWARD_DROP_LOG

if [ "${LOGGIN[FORWARD_DROP]}" = "true" ]; then
    iptables -A FORWARD_DROP_LOG -j LOG --log-level 6 --log-prefix ':forward_drop_log: '
fi

iptables -A FORWARD_DROP_LOG -j DROP

###########
# Routing #
###########

if [ "$FORWARDING" = "true" ]; then
    iptables -A FORWARD -j FORWARD_ACCEPT_LOG
else
    iptables -A FORWARD -j FORWARD_DROP_LOG
fi

##################
# Primary Chains #
##################

if [ "$ICMP" = "true" ]; then
    iptables -A INPUT -p icmp -j ACCEPT_LOG
    iptables -A OUTPUT -p icmp -j ACCEPT_LOG
fi

if [ "$LOOPBACK" = "true" ]; then
    iptables -A INPUT -i lo -j ACCEPT_LOG
    iptables -A OUTPUT -o lo -j ACCEPT_LOG
fi

for key in "${!DNS[@]}"; do
    if [ -n "$key" ]; then
        iptables -A INPUT -p tcp -s "${DNS[$key]}" --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT_LOG
        iptables -A INPUT -p udp -s "${DNS[$key]}" --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT_LOG
        iptables -A OUTPUT -p tcp -d "${DNS[$key]}" --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT_LOG
        iptables -A OUTPUT -p udp -d "${DNS[$key]}" --dport 53 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT_LOG
    fi
done

for key in "${!NTP[@]}"; do
    if [ -n "$key" ]; then
        iptables -A INPUT -p udp -s "${NTP[$key]}" --sport 123 -m state --state ESTABLISHED,RELATED -j ACCEPT_LOG
        iptables -A OUTPUT -p udp -d "${NTP[$key]}" --dport 123 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT_LOG
    fi
done

for key in "${!INPUT_TCP[@]}"; do
    if [ -n "$key" ]; then
        ports_d=''
        ports_s=''
        if [ -n "${INPUT_TCP[$key]}" ]; then
            ports_d="-m multiport --dports ${INPUT_TCP[$key]}"
            ports_s="-m multiport --sports ${INPUT_TCP[$key]}"
        fi
    
        iptables -A INPUT -p tcp -s $key $ports -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT_LOG

        if [ "$MIRROR_RULES" = "true" ]; then
            iptables -A OUTPUT -p tcp -s $key $ports -m state --state ESTABLISHED,RELATED -j ACCEPT_LOG
        fi
    fi
done

for key in "${!INPUT_UDP[@]}"; do
    if [ -n "$key" ]; then
        ports_d=''
        ports_s=''
        if [ -n "${INPUT_UDP[$key]}" ]; then
            ports_d="-m multiport --dports ${INPUT_UDP[$key]}"
            ports_s="-m multiport --sports ${INPUT_UDP[$key]}"
        fi
    
        iptables -A INPUT -p udp -s $key $ports -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT_LOG

        if [ "$MIRROR_RULES" = "true" ]; then
            iptables -A OUTPUT -p udp -s $key $ports -m state --state ESTABLISHED,RELATED -j ACCEPT_LOG
        fi
    fi
done

for key in "${!OUTPUT_TCP[@]}"; do
    if [ -n "$key" ]; then
        ports_d=''
        ports_s=''
        if [ -n "${OUTPUT_TCP[$key]}" ]; then
            ports_d="-m multiport --dports ${OUTPUT_TCP[$key]}"
            ports_s="-m multiport --sports ${OUTPUT_TCP[$key]}"
        fi
    
        iptables -A OUTPUT -p tcp -s $key $ports -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT_LOG

        if [ "$MIRROR_RULES" = "true" ]; then
            iptables -A INPUT -p tcp -s $key $ports -m state --state ESTABLISHED,RELATED -j ACCEPT_LOG
        fi
    fi
done

for key in "${!OUTPUT_UDP[@]}"; do
    if [ -n "$key" ]; then
        ports_d=''
        ports_s=''
        if [ -n "${OUTPUT_UDP[$key]}" ]; then
            ports_d="-m multiport --dports ${OUTPUT_UDP[$key]}"
            ports_s="-m multiport --sports ${OUTPUT_UDP[$key]}"
        fi
    
        iptables -A OUTPUT -p udp -s $key $ports -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT_LOG

        if [ "$MIRROR_RULES" = "true" ]; then
            iptables -A INPUT -p udp -s $key $ports -m state --state ESTABLISHED,RELATED -j ACCEPT_LOG
        fi
    fi
done


iptables -A INPUT -j DROP_LOG
iptables -A OUTPUT -j DROP_LOG
