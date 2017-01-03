LOG="~/init_ip_notifier.log"
DATE=$(date)

chmod +x ./vm_tools/register_ip.py

echo "$DATE: Initialize IP Notifier..." >> $LOG
./vm_tools/IP_Change_Trigger.sh ens3 ./vm_tools/register_ip.py &
