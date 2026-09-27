-- XFCP (Xilinx FPGA Control Protocol) dissector for Wireshark
-- Protocol reference: https://github.com/alexforencich/xfcp
-- Matches the implementation in src/xfcp.rs; one XFCP packet per UDP
-- datagram on the control port (8001, see src/net.rs).
--
-- Install: copy into ~/.local/lib/wireshark/plugins/
-- or run:  wireshark -X lua_script:xfcp_dissector.lua

local xfcp = Proto("xfcp", "XFCP (Xilinx FPGA Control Protocol)")

local XFCP_UDP_PORT = 8001

local PTYPE_NAMES = {
    [0x10] = "Memory Read Request",
    [0x11] = "Memory Read Response",
    [0x12] = "Memory Write Request",
    [0x13] = "Memory Write Response",
    [0x2c] = "I2C Request",
    [0x2d] = "I2C Response",
    [0xfe] = "ID Request",
    [0xff] = "ID Response",
}

local NODE_CLASS_MEMORY = "Memory"
local NODE_CLASS_SWITCH = "Switch"
local NODE_CLASS_I2C    = "I2C"

local f_path  = ProtoField.string("xfcp.path",  "Path")
local f_rpath = ProtoField.string("xfcp.rpath", "Return Path")
local f_ptype = ProtoField.uint8 ("xfcp.ptype", "Packet Type", base.HEX, PTYPE_NAMES)

local f_mem_addr  = ProtoField.uint32("xfcp.mem.addr",  "Address", base.HEX)
local f_mem_count = ProtoField.uint16("xfcp.mem.count", "Count",   base.DEC)
local f_mem_data  = ProtoField.bytes ("xfcp.mem.data",  "Data")

local f_id_ntype       = ProtoField.uint16("xfcp.id.ntype",       "Node Type", base.HEX)
local f_id_class       = ProtoField.string("xfcp.id.class",       "Node Class")
local f_id_name        = ProtoField.string("xfcp.id.name",        "Name")
local f_id_ext         = ProtoField.string("xfcp.id.ext",         "Extended ID String")
local f_id_payload     = ProtoField.bytes ("xfcp.id.payload",     "Type-specific Payload")
local f_id_addr_width  = ProtoField.uint16("xfcp.id.addr_width",  "Address Width", base.DEC)
local f_id_data_width  = ProtoField.uint16("xfcp.id.data_width",  "Data Width",    base.DEC)
local f_id_word_size   = ProtoField.uint16("xfcp.id.word_size",   "Word Size",     base.DEC)
local f_id_count_width = ProtoField.uint16("xfcp.id.count_width", "Count Width",   base.DEC)
local f_id_up_ports    = ProtoField.uint8 ("xfcp.id.up_ports",    "Upstream Ports",   base.DEC)
local f_id_down_ports  = ProtoField.uint8 ("xfcp.id.down_ports",  "Downstream Ports", base.DEC)

local f_i2c_cmd   = ProtoField.uint8("xfcp.i2c.cmd",   "Command Byte",   base.HEX)
local f_i2c_addr  = ProtoField.uint8("xfcp.i2c.addr",  "Device Address", base.HEX, nil, 0x7f)
local f_i2c_start = ProtoField.bool ("xfcp.i2c.start", "Start", 8, nil, 0x01)
local f_i2c_stop  = ProtoField.bool ("xfcp.i2c.stop",  "Stop",  8, nil, 0x08)
local f_i2c_count = ProtoField.uint8("xfcp.i2c.count", "Count", base.DEC)
local f_i2c_data  = ProtoField.bytes("xfcp.i2c.data",  "Data")

local f_payload = ProtoField.bytes("xfcp.payload", "Payload")

xfcp.fields = {
    f_path, f_rpath, f_ptype,
    f_mem_addr, f_mem_count, f_mem_data,
    f_id_ntype, f_id_class, f_id_name, f_id_ext, f_id_payload,
    f_id_addr_width, f_id_data_width, f_id_word_size, f_id_count_width,
    f_id_up_ports, f_id_down_ports,
    f_i2c_cmd, f_i2c_addr, f_i2c_start, f_i2c_stop, f_i2c_count, f_i2c_data,
    f_payload,
}

local ef_malformed = ProtoExpert.new("xfcp.malformed", "Malformed XFCP packet",
    expert.group.MALFORMED, expert.severity.ERROR)
local ef_unknown = ProtoExpert.new("xfcp.unknown_ptype", "Unknown XFCP packet type",
    expert.group.UNDECODED, expert.severity.WARN)

xfcp.experts = { ef_malformed, ef_unknown }

-- single-bit test without bit32/bitops (portable across Wireshark Lua versions)
local function testbit(v, mask)
    return v % (mask * 2) >= mask
end

-- strip at the first NUL, like parse_str() in xfcp.rs
local function cstring(range)
    return range:string():match("^[^%z]*")
end

local function node_class(ntype)
    if testbit(ntype, 0x8000) then
        return NODE_CLASS_MEMORY
    end
    local hi = math.floor(ntype / 256) % 128 -- high byte sans memory flag
    if hi == 0x01 then return NODE_CLASS_SWITCH end
    if hi == 0x2c then return NODE_CLASS_I2C end
    return nil
end

-- I2C op stream: shared coding between request (0x2C) and response (0x2D).
--   bit 7 set          -> set address (low 7 bits)
--   bit 1 set          -> read  (data present only in responses)
--   bit 2 set          -> write (data present in both directions)
--   bit 4 set          -> explicit count byte follows, else count = 1
--   bit 0 / bit 3      -> start / stop flags
-- Returns a short summary string for the info column.
local function dissect_i2c_ops(buf, off, tree, is_response)
    local len = buf:len()
    local summary = {}

    while off < len do
        local cmd = buf(off, 1):uint()

        if cmd >= 0x80 then
            local addr = cmd % 0x80
            local st = tree:add(buf(off, 1), string.format("Op: Set Address 0x%02x", addr))
            st:add(f_i2c_cmd, buf(off, 1))
            st:add(f_i2c_addr, buf(off, 1))
            summary[#summary + 1] = string.format("SetAddr(0x%02x)", addr)
            off = off + 1

        elseif testbit(cmd, 0x02) or testbit(cmd, 0x04) then
            local is_read = testbit(cmd, 0x02)
            local has_count = testbit(cmd, 0x10)
            local hdr_len = has_count and 2 or 1

            if off + hdr_len > len then
                tree:add_proto_expert_info(ef_malformed, "truncated I2C op header")
                return table.concat(summary, " ")
            end
            local count = has_count and buf(off + 1, 1):uint() or 1

            -- read ops carry data only in responses; write ops in both directions
            local data_len = (is_read and not is_response) and 0 or count
            if off + hdr_len + data_len > len then
                tree:add_proto_expert_info(ef_malformed, "truncated I2C op data")
                data_len = len - off - hdr_len
            end

            local flags = (testbit(cmd, 0x01) and " start" or "")
                       .. (testbit(cmd, 0x08) and " stop" or "")
            local name = is_read and "Read" or "Write"
            local st = tree:add(buf(off, hdr_len + data_len),
                string.format("Op: %s %d byte(s)%s", name, count, flags))
            st:add(f_i2c_cmd, buf(off, 1))
            st:add(f_i2c_start, buf(off, 1))
            st:add(f_i2c_stop, buf(off, 1))
            if has_count then st:add(f_i2c_count, buf(off + 1, 1)) end
            if data_len > 0 then st:add(f_i2c_data, buf(off + hdr_len, data_len)) end

            summary[#summary + 1] = string.format("%s(%d)", name, count)
            off = off + hdr_len + data_len

        else
            tree:add_proto_expert_info(ef_malformed,
                string.format("unknown I2C op 0x%02x", cmd))
            return table.concat(summary, " ")
        end
    end

    return table.concat(summary, " ")
end

function xfcp.dissector(buf, pinfo, tree)
    local len = buf:len()
    if len < 2 then return 0 end

    pinfo.cols.protocol = "XFCP"
    local t = tree:add(xfcp, buf())

    -- header: [path bytes < 0xFE] [0xFE rpath-bytes]? 0xFF ptype
    local i = 0
    local path = {}
    while i < len and buf(i, 1):uint() < 0xfe do
        path[#path + 1] = tostring(buf(i, 1):uint())
        i = i + 1
    end
    if i >= len then
        t:add_proto_expert_info(ef_malformed, "missing 0xFF start-of-payload delimiter")
        return len
    end
    local path_str = #path > 0 and table.concat(path, ".") or "(local)"
    t:add(f_path, buf(0, i), path_str)

    local delim = buf(i, 1):uint()
    if delim == 0xfe then
        i = i + 1
        local rstart = i
        local rpath = {}
        while i < len and buf(i, 1):uint() < 0xfe do
            rpath[#rpath + 1] = tostring(buf(i, 1):uint())
            i = i + 1
        end
        if i >= len then
            t:add_proto_expert_info(ef_malformed, "missing 0xFF start-of-payload delimiter")
            return len
        end
        t:add(f_rpath, buf(rstart, i - rstart),
            #rpath > 0 and table.concat(rpath, ".") or "(local)")
        delim = buf(i, 1):uint()
    end

    if delim ~= 0xff then
        t:add_proto_expert_info(ef_malformed, "expected 0xFF start-of-payload delimiter")
        return len
    end
    i = i + 1

    if i >= len then
        t:add_proto_expert_info(ef_malformed, "missing packet type")
        return len
    end
    local ptype = buf(i, 1):uint()
    t:add(f_ptype, buf(i, 1))
    i = i + 1

    local pname = PTYPE_NAMES[ptype] or string.format("Unknown (0x%02x)", ptype)
    local info = string.format("%s path=%s", pname, path_str)
    local plen = len - i

    if ptype == 0x10 or ptype == 0x13 then
        -- memory read request / write response: addr(u32 LE) count(u16 LE)
        if plen < 6 then
            t:add_proto_expert_info(ef_malformed, "truncated memory access payload")
        else
            t:add_le(f_mem_addr, buf(i, 4))
            t:add_le(f_mem_count, buf(i + 4, 2))
            info = info .. string.format(" addr=0x%08x count=%d",
                buf(i, 4):le_uint(), buf(i + 4, 2):le_uint())
        end

    elseif ptype == 0x11 or ptype == 0x12 then
        -- memory read response / write request: addr(u32 LE) len(u16 LE) data
        if plen < 6 then
            t:add_proto_expert_info(ef_malformed, "truncated memory access payload")
        else
            t:add_le(f_mem_addr, buf(i, 4))
            t:add_le(f_mem_count, buf(i + 4, 2))
            local count = buf(i + 4, 2):le_uint()
            local avail = plen - 6
            if count > avail then
                t:add_proto_expert_info(ef_malformed, "memory data shorter than count")
                count = avail
            end
            if count > 0 then t:add(f_mem_data, buf(i + 6, count)) end
            info = info .. string.format(" addr=0x%08x len=%d",
                buf(i, 4):le_uint(), buf(i + 4, 2):le_uint())
        end

    elseif ptype == 0xff then
        -- ID response: ntype(u16 LE) payload[14] name[16] ext_str[..]
        if plen < 32 then
            t:add_proto_expert_info(ef_malformed, "truncated ID response (need 32 bytes)")
        else
            local ntype = buf(i, 2):le_uint()
            t:add_le(f_id_ntype, buf(i, 2))

            local class = node_class(ntype)
            if class then
                t:add(f_id_class, buf(i, 2), class):set_generated()
            end

            local pt = t:add(f_id_payload, buf(i + 2, 14))
            if class == NODE_CLASS_MEMORY then
                pt:add_le(f_id_addr_width, buf(i + 2, 2))
                pt:add_le(f_id_data_width, buf(i + 4, 2))
                pt:add_le(f_id_word_size, buf(i + 6, 2))
                pt:add_le(f_id_count_width, buf(i + 8, 2))
            elseif class == NODE_CLASS_SWITCH then
                pt:add(f_id_up_ports, buf(i + 2, 1))
                pt:add(f_id_down_ports, buf(i + 3, 1))
            end

            local name = cstring(buf(i + 16, 16))
            t:add(f_id_name, buf(i + 16, 16), name)
            if plen > 32 then
                t:add(f_id_ext, buf(i + 32), cstring(buf(i + 32)))
            end

            info = info .. string.format(" ntype=0x%04x name=%s", ntype, name)
            if class then info = info .. string.format(" (%s)", class) end
        end

    elseif ptype == 0x2c or ptype == 0x2d then
        local ops = dissect_i2c_ops(buf, i, t, ptype == 0x2d)
        if ops ~= "" then info = info .. " " .. ops end

    elseif ptype == 0xfe then
        -- ID request: no payload

    else
        t:add_proto_expert_info(ef_unknown)
        if plen > 0 then t:add(f_payload, buf(i)) end
    end

    pinfo.cols.info = info
    return len
end

DissectorTable.get("udp.port"):add(XFCP_UDP_PORT, xfcp)
