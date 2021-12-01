local module = {}

local bit = require('bit')
local ffi = require('ffi')
local jit = require('jit')

local u32 = ffi.typeof('uint32_t')
local u64 = ffi.typeof('uint64_t')
local i64 = ffi.typeof('int64_t')

if jit and jit.opt then jit.opt.start("maxsnap=1000", "loopunroll=500", "maxmcode=2048") end

local function truncate(num)
	if num >= 0 then
		return math.floor(num)
	else
		return math.ceil(num)
	end
end

do
	local add = {}
	local sub = {}
	local mul = {}
	local div = {}

	local to_signed = bit.tobit

	function add.i32(a, b) return to_signed(a + b) end
	function add.i64(a, b) return a + b end

	function sub.i32(a, b) return to_signed(a - b) end
	function sub.i64(a, b) return a - b end

	function mul.i32(a, b) return to_signed(a * b) end
	function mul.i64(a, b) return a * b end

	function div.i32(lhs, rhs)
		assert(rhs ~= 0, 'division by zero')

		return truncate(lhs / rhs)
	end

	function div.u32(lhs, rhs)
		assert(rhs ~= 0, 'division by zero')

		lhs = tonumber(u32(lhs))
		rhs = tonumber(u32(rhs))

		return to_signed(math.floor(lhs / rhs))
	end

	function div.u64(lhs, rhs)
		assert(rhs ~= 0, 'division by zero')

		return i64(u64(lhs) / u64(rhs))
	end

	module.add = add
	module.sub = sub
	module.mul = mul
	module.div = div
end

do
	local clz = {}
	local ctz = {}
	local popcnt = {}

	local lj_band = bit.band
	local lj_lshift = bit.lshift

	function clz.i32(num)
		for i = 0, 31 do
			local mask = lj_lshift(1, 31 - i)

			if lj_band(num, mask) ~= 0 then return i end
		end

		return 32
	end

	function ctz.i32(num)
		for i = 0, 31 do
			local mask = lj_lshift(1, i)

			if lj_band(num, mask) ~= 0 then return i end
		end

		return 32
	end

	function popcnt.i32(num)
		local count = 0

		while num ~= 0 do
			num = lj_band(num, num - 1)
			count = count + 1
		end

		return count
	end

	module.clz = clz
	module.ctz = ctz
	module.popcnt = popcnt
end

do
	local eqz = {}
	local eq = {}
	local ne = {}
	local le = {}
	local lt = {}
	local ge = {}
	local gt = {}

	local function to_boolean(cond)
		if cond then
			return 1
		else
			return 0
		end
	end

	function eq.i32(lhs, rhs) return to_boolean(lhs == rhs) end
	function eq.i64(lhs, rhs) return to_boolean(lhs == rhs) end
	function eq.num(lhs, rhs) return to_boolean(lhs == rhs) end
	function eqz.i32(lhs) return to_boolean(lhs == 0) end
	function eqz.i64(lhs) return to_boolean(lhs == 0) end
	function ne.i32(lhs, rhs) return to_boolean(lhs ~= rhs) end
	function ne.i64(lhs, rhs) return to_boolean(lhs ~= rhs) end
	function ne.num(lhs, rhs) return to_boolean(lhs ~= rhs) end

	function ge.i32(lhs, rhs) return to_boolean(lhs >= rhs) end
	function ge.i64(lhs, rhs) return to_boolean(lhs >= rhs) end
	function ge.u32(lhs, rhs) return to_boolean(u32(lhs) >= u32(rhs)) end
	function ge.u64(lhs, rhs) return to_boolean(u64(lhs) >= u64(rhs)) end

	function gt.i32(lhs, rhs) return to_boolean(lhs > rhs) end
	function gt.i64(lhs, rhs) return to_boolean(lhs > rhs) end
	function gt.u32(lhs, rhs) return to_boolean(u32(lhs) > u32(rhs)) end
	function gt.u64(lhs, rhs) return to_boolean(u64(lhs) > u64(rhs)) end

	function le.i32(lhs, rhs) return to_boolean(lhs <= rhs) end
	function le.i64(lhs, rhs) return to_boolean(lhs <= rhs) end
	function le.u32(lhs, rhs) return to_boolean(u32(lhs) <= u32(rhs)) end
	function le.u64(lhs, rhs) return to_boolean(u64(lhs) <= u64(rhs)) end

	function lt.i32(lhs, rhs) return to_boolean(lhs < rhs) end
	function lt.i64(lhs, rhs) return to_boolean(lhs < rhs) end
	function lt.u32(lhs, rhs) return to_boolean(u32(lhs) < u32(rhs)) end
	function lt.u64(lhs, rhs) return to_boolean(u64(lhs) < u64(rhs)) end

	module.eqz = eqz
	module.eq = eq
	module.ne = ne
	module.le = le
	module.lt = lt
	module.ge = ge
	module.gt = gt
end

do
	local band = {}
	local bor = {}
	local bxor = {}
	local bnot = {}

	band.i32 = bit.band
	band.i64 = bit.band
	bnot.i32 = bit.bnot
	bnot.i64 = bit.bnot
	bor.i32 = bit.bor
	bor.i64 = bit.bor
	bxor.i32 = bit.bxor
	bxor.i64 = bit.bxor

	module.band = band
	module.bor = bor
	module.bxor = bxor
	module.bnot = bnot
end

do
	local shl = {}
	local shr = {}
	local rotl = {}
	local rotr = {}

	local lj_lshift = bit.lshift
	local lj_rshift = bit.rshift
	local lj_arshift = bit.arshift

	rotl.i32 = bit.rol
	rotl.i64 = bit.rol
	rotr.i32 = bit.ror
	rotr.i64 = bit.ror

	shl.i32 = lj_lshift
	shl.i64 = lj_lshift
	shl.u32 = lj_lshift
	shl.u64 = lj_lshift
	shr.i32 = lj_arshift
	shr.i64 = lj_arshift
	shr.u32 = lj_rshift
	shr.u64 = lj_rshift

	module.shl = shl
	module.shr = shr
	module.rotl = rotl
	module.rotr = rotr
end

do
	local wrap = {}
	local trunc = {}
	local extend = {}
	local convert = {}
	local reinterpret = {}

	-- This would surely be an issue in a multi-thread environment...
	-- ... thankfully this isn't one.
	local RE_INSTANCE = ffi.new [[union {
		int32_t i32;
		int64_t i64;
		float f32;
		double f64;
	}]]

	local function truncate_i64(num) return i64(truncate(num)) end

	function wrap.i32_i64(num)
		RE_INSTANCE.i64 = num

		return RE_INSTANCE.i32
	end

	trunc.i32_f32 = truncate
	trunc.i32_f64 = truncate
	trunc.u32_f32 = truncate
	trunc.u32_f64 = truncate
	trunc.i64_f32 = truncate_i64
	trunc.i64_f64 = truncate_i64
	trunc.u64_f32 = truncate_i64
	trunc.u64_f64 = truncate_i64

	extend.i64_i32 = i64

	function extend.u64_i32(num)
		RE_INSTANCE.i64 = 0
		RE_INSTANCE.i32 = num

		return RE_INSTANCE.i64
	end

	function convert.f32_i32(num) return num end
	function convert.f32_u32(num) return tonumber(u32(num)) end
	function convert.f32_i64(num) return tonumber(num) end
	function convert.f32_u64(num) return tonumber(u64(num)) end

	function convert.f64_i32(num) return num end
	function convert.f64_u32(num) return tonumber(u32(num)) end
	function convert.f64_i64(num) return tonumber(num) end
	function convert.f64_u64(num) return tonumber(u64(num)) end

	function reinterpret.i32_f32(num)
		RE_INSTANCE.f32 = num

		return RE_INSTANCE.i32
	end

	function reinterpret.i64_f64(num)
		RE_INSTANCE.f64 = num

		return RE_INSTANCE.i64
	end

	function reinterpret.f32_i32(num)
		RE_INSTANCE.i32 = num

		return RE_INSTANCE.f32
	end

	function reinterpret.f64_i64(num)
		RE_INSTANCE.i64 = num

		return RE_INSTANCE.f64
	end

	module.wrap = wrap
	module.trunc = trunc
	module.extend = extend
	module.convert = convert
	module.reinterpret = reinterpret
end

do
	local load = {}
	local store = {}

	local copy = ffi.copy

	local RE_INSTANCE = ffi.new [[union {
		int8_t i8;
		int16_t i16;
		int32_t i32;
		int64_t i64;

		uint8_t u8;
		uint16_t u16;
		uint32_t u32;
		uint64_t u64;

		float f32;
		double f64;
	}]]

	function load.i32_i8(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 1)

		return RE_INSTANCE.i8
	end

	function load.i32_u8(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 1)

		return RE_INSTANCE.u8
	end

	function load.i32_i16(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 2)

		return RE_INSTANCE.i16
	end

	function load.i32_u16(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 2)

		return RE_INSTANCE.u16
	end

	function load.i32(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 4)

		return RE_INSTANCE.i32
	end

	function load.i64_i8(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 1)

		return i64(RE_INSTANCE.i8)
	end

	function load.i64_u8(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 1)

		return i64(RE_INSTANCE.u8)
	end

	function load.i64_i16(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 2)

		return i64(RE_INSTANCE.i16)
	end

	function load.i64_u16(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 2)

		return i64(RE_INSTANCE.u16)
	end

	function load.i64_i32(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 4)

		return i64(RE_INSTANCE.i32)
	end

	function load.i64_u32(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 4)

		return i64(RE_INSTANCE.u32)
	end

	function load.i64(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 8)

		return RE_INSTANCE.i64
	end

	function load.f32(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 4)

		return RE_INSTANCE.f32
	end

	function load.f64(memory, addr)
		copy(RE_INSTANCE, memory.data + addr, 8)

		return RE_INSTANCE.f64
	end

	function store.i32_n8(memory, addr, value)
		RE_INSTANCE.i32 = value

		copy(memory.data + addr, RE_INSTANCE, 1)
	end

	function store.i32_n16(memory, addr, value)
		RE_INSTANCE.i32 = value

		copy(memory.data + addr, RE_INSTANCE, 2)
	end

	function store.i32(memory, addr, value)
		RE_INSTANCE.i32 = value

		copy(memory.data + addr, RE_INSTANCE, 4)
	end

	function store.i64_n8(memory, addr, value)
		RE_INSTANCE.i64 = value

		copy(memory.data + addr, RE_INSTANCE, 1)
	end

	function store.i64_n16(memory, addr, value)
		RE_INSTANCE.i64 = value

		copy(memory.data + addr, RE_INSTANCE, 2)
	end

	function store.i64_n32(memory, addr, value)
		RE_INSTANCE.i64 = value

		copy(memory.data + addr, RE_INSTANCE, 4)
	end

	function store.i64(memory, addr, value)
		RE_INSTANCE.i64 = value

		copy(memory.data + addr, RE_INSTANCE, 8)
	end

	function store.f32(memory, addr, value)
		RE_INSTANCE.f32 = value

		copy(memory.data + addr, RE_INSTANCE, 4)
	end

	function store.f64(memory, addr, value)
		RE_INSTANCE.f64 = value

		copy(memory.data + addr, RE_INSTANCE, 8)
	end

	module.load = load
	module.store = store
end

do
	local memory = {}

	local WASM_PAGE_SIZE = 65536

	ffi.cdef [[
	struct Memory {
		uint32_t min;
		uint32_t max;
		uint8_t *data;
	};

	void *calloc(size_t num, size_t size);
	void *realloc(void *ptr, size_t size);
	void free(void *ptr);
	]]

	local function finalizer(memory) ffi.C.free(memory.data) end

	local function grow_unchecked(memory, old, new)
		memory.data = ffi.C.realloc(memory.data, new)

		assert(memory.data ~= nil, 'failed to reallocate')

		ffi.fill(memory.data + old, new - old, 0)
	end

	function memory.new(min, max)
		local data = ffi.C.calloc(max, WASM_PAGE_SIZE)

		assert(data ~= nil, 'failed to allocate')

		local memory = ffi.new('struct Memory', min, max, data)

		return ffi.gc(memory, finalizer)
	end

	function memory.init(memory, offset, data) ffi.copy(memory.data + offset, data) end

	function memory.grow(memory, num)
		local old = memory.min
		local new = old + num

		if new > memory.max then
			return -1
		else
			grow_unchecked(memory, old * WASM_PAGE_SIZE, new * WASM_PAGE_SIZE)
			memory.min = new

			return old
		end
	end

	module.memory = memory
end

return module
