# From: https://www.av8n.com/computer/disk-hw-host-bus-id
#!/bin/bash

function usage() {
cat <<\EoF
Usage:
   disk-hw-host-bus-id [options]

Options include:
   -h           # print this message (and immediately exit)
   -v           # more verbose output

We scan all /dev/sd? drives, and report the /dev/sd? name and the
corresponding hardware attachment, plus the make, model, and serial
number of the drive.

 *) For ATA drives, the attachment point is something like "ata1.00",
  where the three digits are the host, bus, and target number, also
  known as the adapter, channel, and target number.  The three numbers
  together specify a target device.  (We do not report the lun,
  although this feature could easily be added.)

 *) For USB drives, the attachment point is something like "1:6" where
  the two digits are the Bus and Device numbers.  Note that will then
  give you additional information about the drive.

All this information is useful when dealing with disk errors.
 -- The drive serial number is important because drive letters can
  change, especially when disks drop offline, and you need to be
  able to reliably interpret SMART messages.
 -- The drive serial number is also important for RAID arrays, where
  you have many disks that look alike. Hint: Write the serial number
  on each drive, someplace where it can be easily seen.
 -- The ATA attachment is important because some messages in
  /var/log/syslog and /var/log/kern.log give only the ATA
  host/bus/target number, without explicitly saying what you need to
  know, such as the /dev/sd? drive letter and/or the hardware serial
  number.
 -- The USB attachment is useful because you can pass it to 'lsusb'
  to obtain additional information about the drive, e.g.
        lsusb -v -s 1:6

You can sometimes get this information by scrutinizing /var/log/dmesg,
but our way is more efficient, more robust, and more informative.

This is significantly more informative than 'lsscsi' or 'cat
/proc/scsi/scsi'.  When working with a RAID array, you often need the
serial numbers.

Unlike 'hdparm' and 'lsusb', we can find the serial number without
needing root privileges.

We use only /bin/sed and /bin/grep, to permit use in emergencies, even
when /usr is not mounted.  We use only posix-specified non-extended
regular expressions, for maximum portability.

SEE ALSO:
  :; lsblk -f /dev/sda          # fstype, label, UUID, mountpoint
  :; fdisk -l /dev/sda          # partition sizes, et cetera
  :; hdparm -i /dev/sda         # root only; fails ugly for USB drives
  :; lsusb -v -s 1:6
  :; lsscsi
  :; lspci
  :; lshw
  :; cat /proc/scsi/scsi
  :; cat /proc/mdstat           # RAID array status

Reference: http://tldp.org/HOWTO/SCSI-2.4-HOWTO/scsiaddr.html

 Linux's flavor of SCSI addressing is a four level hierarchy:
        <scsi_adapter_number, channel, id, lun>

  Using the naming conventions of devfs this becomes:
        <host, bus, target, lun>

 Each SCSI device can contain multiple Logical Unit Numbers
 (LUNs). These are typically used by sophisticated tape and cdrom
 devices that support multiple media.  To identify the target device
 per_se, you don't need the lun.
EoF
}

verbose=0
didsome=0
zap=0
flags=''

while test $# -gt 0 ; do
  arg="$1" ; shift
  case $arg in
    -h*|--h*)
      usage
      exit
      ;;
    -v*)
      ((verbose++))
      ;;
    -p)
      flags='--posix'   # to test for compatibility
      ;;
    -z)
      ((zap++))         # for testing, for wizards only
      ;;
    *)
      1>&2 echo "Unrecognized cmdline option '$arg'"
      exit 1
  esac
done

# example:
# long: /sys/devices/pci0000:00/0000:00:1f.2/ata1/host0/target0:0:0/0:0:0:0/block/sda
# base: /sys/devices/pci0000:00/0000:00:1f.2/ata1/host0/

q="'"               # single quote
t=$(echo -e '\t')   # tab
e='[^/]*/'          # element of path
d='\([0-9]*\)'      # string of digits
part1='s=^\('"/sys/devices/$e$e$e$e"'\)'        # base path
part2='.*target'"$d:$d:$d/"                     # the adapter : atabus : target numbers
part3='.*/\(.*\)='                              # the /dev/ name at the end, e.g. 'sda'
part4="\\1$t\\2$t\\3$t\\4$t\\5=;"               # collect the results
for ptr in /sys/block/*; do                     # loop over all devices
  link=$(readlink $ptr |                        # each entry is a complicated symlink
    sed $flags 's=^[.][.]/=/sys/=' )            # replace '..' with absolute path
  if ! echo $link | grep -q devices/pci ; then
    continue                    # exclude non-pci block devices such as /dev/loop0
  fi

  if ((verbose > 0 && didsome++ > 0)) ; then
     echo                                       # separate the stanzas
  fi
  if ((verbose >> 0)) ; then
    echo "link: $link"                          # show the long-form link
  fi
  hack=''
  if ((zap > 0)) ; then
    hack='s/target\(.\):0:0/target\1:7:8/;'     # for testing
  fi
  echo $link |
  sed $flags "$hack$part1$part2$part3$part4" |
# Idiomatic while-once block;  not really a loop, just once through
  while read base adapter atabus target device junk; do
    if ((verbose >> 0)) ; then
      echo base: $base adapter: $adapter atabus: $atabus target: $target device: $device
    fi
    if echo $base | grep -q '/usb[0-9]*/'; then # must be USB device, not ATA device
      bus=$( cat "$base/busnum")
      dev=$( cat "$base/devnum")
      mfgr=$( cat "$base/manufacturer")
      product=$( cat "$base/product")
      serial=$( cat "$base/serial")
      echo -e "$device : USB $bus:$dev == '$mfgr $product'$t$serial"
    else                        # must be ATA device
#xxxx would be very slow, and require root privilege:
#xxxx       serial=$( 2>/dev/null hdparm -i /dev/$device | grep SerialNo )
      sed1='s=^.......==;      # remove first field, fixed width
        s=  *= =g;             # collapse multiple spaces to one
        s=^ ==;                # get rid of initial space
        s= $==;'               # get rid of (unlinkely) trailing space
      sed2='s=\(.*\)[ ]\([^ ]*\)='     # separate the first N-1 words
      sed3=$q'\1'"$q$t"'\2=;'  # so we can single-quote them
# wwid contains make, model, and serial number,
# but sometimes the file is unreadable, even though it exists:
      if ! m_m_serial=$( <$link/../../wwid \
          sed $flags "$sed1$sed2$sed3" 2>/dev/null) ; then
# do the best we can otherwise:
        m_m_serial="$( cat $link/../../vendor $link/../../model  |
                sed -n '        # start with vendor name
                N;              # append model name
                s=\n= =;        # two lines become one
                s=^ *='$q'=;    # trim spaces and add quotes
                s= *$='$q'=;
                p'              #   then print
          )"
      fi
      idfile="$base/scsi_host/host$adapter/unique_id"
      atanum="ata$(< "$idfile").$atabus$target"
      echo "$device : $atanum == $m_m_serial"
    fi
  done # end while-once read block
done # end main loop over devices
exit 000
