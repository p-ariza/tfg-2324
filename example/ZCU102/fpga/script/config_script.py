import argparse

import xfcp.interface
import xfcp.node
import xfcp.i2c_node

def main():
    #parser = argparse.ArgumentParser(description=__doc__.strip())
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--port', type=str, default='/dev/ttyUSB4', help="Port")
    parser.add_argument('-b', '--baud', type=int, default=115200, help="Baud rate")
    parser.add_argument('-H', '--host', type=str, help="Host (i.e. 192.168.1.128:14000)")

    args = parser.parse_args()

    port = args.port
    baud = args.baud
    host = args.host

    intf = None

    if host is not None:
        # ethernet interface
        intf = xfcp.interface.UDPInterface(host)
    else:
        # serial interface
        intf = xfcp.interface.SerialInterface(port, baud)

    n = intf.enumerate()

    print("XFCP node tree:")
    n.print_tree()

    d_mac      = 'AAAAAAAAAA'
    s_mac      = 'BBBBBBBBBB'
    ethertype  = '0000'
    payload    = '88'
    manager_id = '00000000'
    command    = '00000001'

    n[0].write(0x0004, bytes.fromhex(d_mac))
    n[0].write(0x000C, bytes.fromhex(s_mac))
    n[0].write(0x0014, bytes.fromhex(ethertype))
    n[0].write(0x0018, bytes.fromhex(payload))
    n[0].write(0x001C, bytes.fromhex(manager_id))
    n[0].write(0x0000, bytes.fromhex(command))
