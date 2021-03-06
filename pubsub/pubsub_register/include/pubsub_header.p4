/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

#ifndef __HEADER__
#define __HEADER__

#include "pubsub_define.p4"

header ethernet_t {
    mac_addr_t   dstAddr;
    mac_addr_t   srcAddr;
    ether_type_t etherType;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     totalLen;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     fragOffset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdrChecksum;
    ipv4_addr_t srcAddr;
    ipv4_addr_t dstAddr;
}

header udp_t {
    bit<16> srcPrt;
    bit<16> dstPrt;           // here 65432(0xff98) => ip.dst is pubsub header
    bit<16> lenght;
    bit<16> chksum;
}

struct local_metadata_t {
    bit<4> mcastGrp_id;       // The id of multi_cast group to be set for output.
    bit<4> port_indx;         // The input port_mask number for incoming sub packet.

    bit<22> pubsub_indx;      // The (pub or sub) index for temp use.
    bit<2> pubsub_flags;      // '11'=sub_add, '10'=sub_rem, '00'=pub,
                              // '01'=(send to the REPLICA controller
                              // for (INIT_NF_ID, INIT_PUB_ID,Variable_ID_REQ, RECOVER)).
    bit<8> ipDstCode;
    bit<8> ipSrcCode;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    udp_t        udp;
}

#endif
