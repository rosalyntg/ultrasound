// see https://github.com/alexforencich/xfcp/blob/master/python/xfcp/packet.py

use std::{io, pin::Pin, time::Duration};

use bytes::Bytes;
use futures_core::Stream;
use futures_sink::Sink;
use iced::futures::{SinkExt, StreamExt};
use iced_native::image::Data;
use tokio::time::timeout;

const TIMEOUT: Duration = Duration::from_secs(2);

#[derive(Default, Debug, Clone)]
struct Path(Vec<u8>);

#[derive(Debug)]
struct Packet {
    path: Path,
    rpath: Path,
    payload: PacketPayload,
}

impl Path {
    fn join(&self, port: u8) -> Self {
        let mut ret = self.clone();
        ret.0.push(port);
        ret
    }
}

#[derive(Debug)]
enum PacketPayload {
    MemoryAccess(MemoryAccessPacket),
    IdRequest,
    IdResponse {
        ntype: u16,
        name: String,
        ext_str: String,
        payload: [u8; 14], // bytes between ntype and name
    },
    I2CRequest(Vec<I2CRequestOp>),
    I2CResponse(Vec<I2CResponseOp>), // needs the request to be fully parsed, so just dump payload here
}

#[derive(Debug)]
enum I2CRequestOp {
    SetAddress(u8),
    Read {
        count: u8,
        start: bool,
        stop: bool,
    },
    Write {
        data: Vec<u8>,
        start: bool,
        stop: bool,
    },
}

#[derive(Debug)]
enum I2CResponseOp {
    SetAddress(u8),
    Read(Vec<u8>),
    Write,
}

#[derive(Debug)]
struct MemoryAccessPacket {
    addr: u32,
    kind: MemoryAccessPacketKind,
}

#[derive(Debug)]
enum MemoryAccessPacketKind {
    ReadRequest(u16),
    ReadResponse(Vec<u8>),
    WriteRequest(Vec<u8>),
    WriteResponse(u16),
}

impl Path {}

#[derive(Debug, Clone)]
struct NodeCommon {
    path: Path,
    name: String,
    // ntype: u16,
    ext_str: String,
}

#[derive(Debug)]
pub struct SwitchNode {
    c: NodeCommon,
    up_ports: u8,
    down_ports: u8,
}

#[derive(Debug, Clone)]
pub struct MemoryNode {
    c: NodeCommon,
    addr_width: u16,
    data_width: u16,
    word_size: u16,
    count_width: u16,
}

#[derive(Debug, Clone)]
pub struct I2CNode {
    c: NodeCommon,
}

#[derive(Debug)]
pub enum Node {
    SwitchNode(SwitchNode),
    MemoryNode(MemoryNode),
    I2CNode(I2CNode),
}

impl Node {
    fn new(packet: Packet) -> Self {
        let PacketPayload::IdResponse {
            ntype,
            name,
            ext_str,
            payload,
        } = packet.payload
        else {
            panic!("Expected IdResponse packet")
        };

        if ntype & 0x8000 != 0 {
            // memory node
            Node::MemoryNode(MemoryNode {
                c: NodeCommon {
                    path: packet.path,
                    name,
                    ext_str: ext_str,
                },
                addr_width: u16::from_le_bytes([payload[0], payload[1]]),
                data_width: u16::from_le_bytes([payload[2], payload[3]]),
                word_size: u16::from_le_bytes([payload[4], payload[5]]),
                count_width: u16::from_le_bytes([payload[6], payload[7]]),
            })
        } else if ntype & 0xff00 == 0x0100 {
            // switch node
            Node::SwitchNode(SwitchNode {
                c: NodeCommon {
                    path: packet.path,
                    name,
                    ext_str: ext_str,
                },
                up_ports: payload[0],
                down_ports: payload[1],
            })
        } else if ntype & 0xff00 == 0x2c00 {
            // i2c node
            Node::I2CNode(I2CNode {
                c: NodeCommon {
                    path: packet.path,
                    name,
                    ext_str: ext_str,
                },
            })
        } else {
            todo!("Node type 0x{ntype:04x} not implemented")
        }
    }

    pub fn name(&self) -> &str {
        match self {
            Node::SwitchNode(s) => &s.c.name,
            Node::MemoryNode(m) => &m.c.name,
            Node::I2CNode(i) => &i.c.name,
        }
    }
}

pub struct Interface {
    rx: Pin<Box<dyn Stream<Item = Bytes>>>,
    tx: Pin<Box<dyn Sink<Bytes, Error = io::Error>>>,
}

impl MemoryNode {
    pub async fn read(
        &self,
        interface: &mut Interface,
        addr: u32,
        count: u16,
    ) -> Result<Vec<u8>, io::Error> {
        // only implemented path:
        assert!(self.addr_width == 32);
        assert!(self.data_width == 32);
        assert!(self.word_size == 8);
        assert!(self.count_width == 16);

        let packet = Packet {
            path: self.c.path.clone(),
            rpath: Path(vec![]), // ??
            payload: PacketPayload::MemoryAccess(MemoryAccessPacket {
                addr,
                kind: MemoryAccessPacketKind::ReadRequest(count),
            }),
        };
        interface.tx.send(Bytes::from(packet.to_bytes())).await?;

        let resp = timeout(TIMEOUT, interface.rx.next())
            .await?
            .ok_or(io::Error::from(io::ErrorKind::UnexpectedEof))?;

        let packet = Packet::parse(&resp)?;
        let PacketPayload::MemoryAccess(MemoryAccessPacket {
            addr: _,
            kind: MemoryAccessPacketKind::ReadResponse(data),
        }) = packet.payload
        else {
            panic!(
                "Expected MemoryAccess ReadResponse packet, got {:?}",
                packet.payload
            )
        };

        Ok(data)
    }

    pub async fn write(
        &self,
        interface: &mut Interface,
        addr: u32,
        data: &[u8],
    ) -> Result<(), io::Error> {
        // only implemented path:
        assert!(self.addr_width == 32);
        assert!(self.data_width == 32);
        assert!(self.word_size == 8);
        assert!(self.count_width == 16);

        let packet = Packet {
            path: self.c.path.clone(),
            rpath: Path(vec![]), // ??
            payload: PacketPayload::MemoryAccess(MemoryAccessPacket {
                addr,
                kind: MemoryAccessPacketKind::WriteRequest(data.to_vec()),
            }),
        };
        interface.tx.send(Bytes::from(packet.to_bytes())).await?;

        let resp = timeout(TIMEOUT, interface.rx.next())
            .await?
            .ok_or(io::Error::from(io::ErrorKind::UnexpectedEof))?;

        let packet = Packet::parse(&resp)?;
        let PacketPayload::MemoryAccess(MemoryAccessPacket {
            addr: _,
            kind: MemoryAccessPacketKind::WriteResponse(_),
        }) = packet.payload
        else {
            panic!(
                "Expected MemoryAccess WriteResponse packet, got {:?}",
                packet.payload
            );
        };

        Ok(())
    }
}

impl SwitchNode {
    pub async fn enumerate(&self, interface: &mut Interface) -> Result<Vec<Node>, io::Error> {
        let mut nodes = Vec::new();
        for port in 0..self.down_ports {
            let path = self.c.path.join(port);
            let node = interface.enumerate_at(path).await?;
            nodes.push(node);
        }
        Ok(nodes)
    }
}

impl I2CNode {
    pub async fn read_at_offset_1b(
        &self,
        interface: &mut Interface,
        device_addr: u8,
        offset: u8,
        count: u8,
    ) -> Result<Vec<u8>, io::Error> {
        let packet = Packet {
            path: self.c.path.clone(),
            rpath: Path(vec![]), // ??
            payload: PacketPayload::I2CRequest(vec![
                I2CRequestOp::SetAddress(device_addr),
                I2CRequestOp::Write {
                    data: vec![offset],
                    start: false,
                    stop: false,
                },
                I2CRequestOp::Read {
                    count,
                    start: false,
                    stop: true,
                },
            ]),
        };
        interface.tx.send(Bytes::from(packet.to_bytes())).await?;

        let resp = timeout(TIMEOUT, interface.rx.next())
            .await?
            .ok_or(io::Error::from(io::ErrorKind::UnexpectedEof))?;

        let packet = Packet::parse(&resp)?;

        let PacketPayload::I2CResponse(ops) = packet.payload else {
            panic!("Expected I2CResponse packet, got {:?}", packet.payload);
        };

        let I2CResponseOp::Read(data) = &ops[2] else {
            panic!("Expected I2CResponse Read op, got {:?}", ops[2]);
        };

        Ok(data.clone())
    }

    pub async fn write(&self, interface: &mut Interface, device_addr: u8, data: &[u8]) -> Result<(), io::Error> {
        let packet = Packet {
            path: self.c.path.clone(),
            rpath: Path(vec![]), // ??
            payload: PacketPayload::I2CRequest(vec![
                I2CRequestOp::SetAddress(device_addr),
                I2CRequestOp::Write {
                    data: data.to_vec(),
                    start: false,
                    stop: true,
                },
            ]),
        };
        interface.tx.send(Bytes::from(packet.to_bytes())).await?;
        timeout(TIMEOUT, interface.rx.next()).await?
            .ok_or(io::Error::from(io::ErrorKind::UnexpectedEof))?;
        Ok(())
    }
    
    pub async fn read(&self, interface: &mut Interface, address: u8, count: u8) -> Result<Vec<u8>, io::Error> {
        let packet = Packet {
            path: self.c.path.clone(),
            rpath: Path(vec![]), // ??
            payload: PacketPayload::I2CRequest(vec![
                I2CRequestOp::SetAddress(address),
                I2CRequestOp::Read {
                    count,
                    start: false,
                    stop: true,
                },
            ]),
        };
        interface.tx.send(Bytes::from(packet.to_bytes())).await?;
        let resp = timeout(TIMEOUT, interface.rx.next()).await?
            .ok_or(io::Error::from(io::ErrorKind::UnexpectedEof))?;

        let packet = Packet::parse(&resp)?;

        let PacketPayload::I2CResponse(ops) = packet.payload else {
            panic!("Expected I2CResponse packet, got {:?}", packet.payload);
        };

        let I2CResponseOp::Read(data) = &ops[1] else {
            panic!("Expected I2CResponse Read op, got {:?}", ops[1]);
        };
        Ok(data.clone())
    }
}

impl Interface {
    pub fn new(
        rx: impl Stream<Item = Bytes> + Unpin + 'static,
        tx: impl Sink<Bytes, Error = io::Error> + Unpin + 'static,
    ) -> Self {
        Self {
            rx: Box::pin(rx),
            tx: Box::pin(tx),
        }
    }

    pub async fn enumerate(&mut self) -> Result<Node, io::Error> {
        self.enumerate_at(Path(vec![])).await
    }

    async fn enumerate_at(&mut self, path: Path) -> Result<Node, io::Error> {
        let id_request = Packet {
            path,
            rpath: Path(vec![]), // ??
            payload: PacketPayload::IdRequest,
        };

        self.tx.send(Bytes::from(id_request.to_bytes())).await?;
        let resp = timeout(TIMEOUT, self.rx.next())
            .await?
            .ok_or(io::Error::from(io::ErrorKind::UnexpectedEof))?;

        let packet = Packet::parse(&resp)?;

        Ok(Node::new(packet))
    }
}

impl Packet {
    fn to_bytes(&self) -> Vec<u8> {
        let mut ret = Vec::new();
        for p in &self.path.0 {
            ret.push(*p);
        }

        if self.rpath.0.len() > 0 {
            ret.push(0xFE);
            for rp in &self.rpath.0 {
                ret.push(*rp);
            }
        }

        ret.push(0xFF);
        ret.push(self.payload.ptype());

        self.payload.append_to_bytes(&mut ret);

        ret
    }

    fn parse(data: &[u8]) -> Result<Packet, io::Error> {
        let mut path = Path(vec![]);

        let mut iter = data.iter().copied();
        let mut delim = None;
        while let Some(n) = iter.next() {
            if n >= 0xFE {
                delim = Some(n);
                break;
            }
            path.0.push(n);
        }

        let mut rpath = Path(vec![]);

        let mut delim = delim.ok_or(io::Error::from(io::ErrorKind::UnexpectedEof))?;
        if delim == 0xfe {
            while let Some(n) = iter.next() {
                if n >= 0xfe {
                    break;
                }
                rpath.0.push(n);
            }
            delim = iter
                .next()
                .ok_or(io::Error::from(io::ErrorKind::UnexpectedEof))?;
        }

        if delim != 0xff {
            return Err(io::Error::from(io::ErrorKind::InvalidData));
        }

        let ptype = iter
            .next()
            .ok_or(io::Error::from(io::ErrorKind::UnexpectedEof))?;

        Ok(Packet {
            path,
            rpath,
            payload: PacketPayload::parse(ptype, iter),
        })
    }
}

impl PacketPayload {
    fn append_to_bytes(&self, ret: &mut Vec<u8>) {
        match self {
            PacketPayload::MemoryAccess(ma) => ma.append_to_bytes(ret),
            PacketPayload::IdRequest => {}
            PacketPayload::IdResponse { .. } => todo!(),
            PacketPayload::I2CRequest(ops) => {
                for op in ops {
                    match op {
                        I2CRequestOp::SetAddress(addr) => {
                            assert!(*addr < 0x80);
                            ret.push(0x80 | addr)
                        }
                        I2CRequestOp::Read { count, start, stop } => {
                            let cmd = 0x02
                                | if *start { 0x01 } else { 0x00 }
                                | if *stop { 0x08 } else { 0x00 };
                            if *count == 1 {
                                ret.push(cmd);
                            } else {
                                ret.push(cmd | 0x10);
                                ret.push(*count);
                            }
                        }
                        I2CRequestOp::Write { data, start, stop } => {
                            let cmd = 0x04
                                | if *start { 0x01 } else { 0x00 }
                                | if *stop { 0x08 } else { 0x00 };
                            if data.len() == 1 {
                                ret.push(cmd);
                            } else {
                                ret.push(cmd | 0x10);
                                ret.push(data.len() as u8);
                            }
                            ret.extend_from_slice(data);
                        }
                    }
                }
            }
            PacketPayload::I2CResponse(items) => todo!(),
        }
    }

    fn ptype(&self) -> u8 {
        match self {
            PacketPayload::MemoryAccess(MemoryAccessPacket {
                kind: MemoryAccessPacketKind::ReadRequest(_),
                ..
            }) => 0x10,
            PacketPayload::MemoryAccess(MemoryAccessPacket {
                kind: MemoryAccessPacketKind::ReadResponse(_),
                ..
            }) => 0x11,
            PacketPayload::MemoryAccess(MemoryAccessPacket {
                kind: MemoryAccessPacketKind::WriteRequest(_),
                ..
            }) => 0x12,
            PacketPayload::MemoryAccess(MemoryAccessPacket {
                kind: MemoryAccessPacketKind::WriteResponse(_),
                ..
            }) => 0x13,
            PacketPayload::IdRequest => 0xfe,
            PacketPayload::IdResponse { .. } => 0xf1,
            PacketPayload::I2CRequest(_) => 0x2c,
            PacketPayload::I2CResponse(_) => 0x2d,
        }
    }

    fn parse(ptype: u8, iter: impl Iterator<Item = u8>) -> PacketPayload {
        let rest: Vec<u8> = iter.collect();
        match ptype {
            0xff => {
                // id response
                let ntype = u16::from_le_bytes([rest[0], rest[1]]);
                let name = parse_str(&rest[16..32]);
                let ext_str = if rest.len() > 32 {
                    parse_str(&rest[32..])
                } else {
                    String::new()
                };

                PacketPayload::IdResponse {
                    ntype,
                    name,
                    ext_str,
                    payload: rest[2..16].try_into().unwrap(),
                }
            }
            0x11 => {
                // memory read response
                let addr = u32::from_le_bytes([rest[0], rest[1], rest[2], rest[3]]);
                let len = u16::from_le_bytes([rest[4], rest[5]]);
                let data = rest[6..].to_vec();
                assert!(data.len() == len as usize);
                PacketPayload::MemoryAccess(MemoryAccessPacket {
                    addr,
                    kind: MemoryAccessPacketKind::ReadResponse(data),
                })
            }
            0x13 => {
                // memory write response
                let addr = u32::from_le_bytes([rest[0], rest[1], rest[2], rest[3]]);
                let count = u16::from_le_bytes([rest[4], rest[5]]);
                PacketPayload::MemoryAccess(MemoryAccessPacket {
                    addr,
                    kind: MemoryAccessPacketKind::WriteResponse(count),
                })
            }
            0x2d => {
                // i2c response
                let mut ops = Vec::new();
                let mut i = 0;
                while i != rest.len() {
                    if rest[i] & 0x80 == 0x80 {
                        // set address
                        ops.push(I2CResponseOp::SetAddress(rest[i] & 0x7f));
                        i += 1;
                    } else if rest[i] & 0x02 == 0x02 {
                        // read
                        let count = if rest[i] & 0x10 == 0x10 {
                            i += 1;
                            rest[i] as usize
                        } else {
                            1
                        };
                        i += 1;
                        let data = rest[i..i + count].to_vec();
                        ops.push(I2CResponseOp::Read(data));
                        i += count;
                    } else if rest[i] & 0x04 == 0x04 {
                        // write
                        let count = if rest[i] & 0x10 == 0x10 {
                            i += 1;
                            rest[i] as usize
                        } else {
                            1
                        };
                        i += 1;
                        // let data = rest[i..i + count].to_vec();
                        ops.push(I2CResponseOp::Write);
                        i += count;
                    } else {
                        panic!("Unknown I2C response op: {:02x}", rest[i]);
                    }
                }
                PacketPayload::I2CResponse(ops)
            }
            _ => unimplemented!("Packet type {ptype} not implemented"),
        }
    }
}

impl MemoryAccessPacket {
    fn append_to_bytes(&self, ret: &mut Vec<u8>) {
        match &self.kind {
            MemoryAccessPacketKind::ReadRequest(count) => {
                ret.extend_from_slice(&self.addr.to_le_bytes());
                ret.extend_from_slice(&count.to_le_bytes());
            }
            MemoryAccessPacketKind::WriteRequest(data) => {
                ret.extend_from_slice(&self.addr.to_le_bytes());
                ret.extend_from_slice(&(data.len() as u16).to_le_bytes());
                ret.extend_from_slice(data);
            }
            _ => unimplemented!("MemoryAccessPacketKind {:?} not implemented", self.kind),
        }
    }
}

fn parse_str(data: &[u8]) -> String {
    str::from_utf8(data)
        .unwrap()
        .trim_end_matches(|b| b == '\0')
        .to_string()
}
