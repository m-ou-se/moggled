module moggle.math.normalized;

import std.algorithm;

unittest {
	Normalized!(byte) b; // Behaves like a float, but stores -1..1 in a byte as -127..127.
	Normalized!(uint) u; // Stores 0..1 in a uint as 0..uint.max.

	// Just use them as if they are floats.
	b = 0.5;
	u = 0.2;
	b *= u;
	u = b * u + 0.1;
	assert(b < u);
	assert(b + 0.05 > u);

	// They are automatically capped at 0..1 for unsigned and -1..1 for signed.
	b += 3.5;
	assert(b == 1);
	b = 10 * -0.3;
	u = -2.4;
	assert(b == -1);
	assert(u == 0);

	// .raw gives access to the underlying storage.
	b = 0.5;
	assert(b.raw == 63);
	b.raw = -127;
	assert(b == -1);
	u = 0;
	assert(u.raw == 0);
	u.raw = 2147483648;
	assert(u >= 0.49 && u <= 0.51);

	// fromRaw constructs from the raw value.
	auto x = Normalized!(ubyte)(0.4);
	auto y = Normalized!(ubyte).fromRaw(102); // 102/255
	assert(x == y);

	// The floating point type it behaves as is the smallest of [float, double, real] with
	// at least as much precision as the underlying type.
	static assert(is(Normalized!(byte).float_type == float));
	static assert(is(Normalized!(uint).float_type == double));
	static assert(is(Normalized!(long).float_type == real));

	// Normalized!(T) only contains a T, so a T[] and a Normalized!(T)[] can be
	// casted to eachother.
	static assert(Normalized!(byte).sizeof == 1);
	ubyte[3] rgb_b = [255, 102, 0];
	auto rgb_f = cast(Normalized!(ubyte)[])rgb_b;
	// rgb_f is now [1, 0.4, 0]
	assert(rgb_f[0] == 1);
	rgb_f[1] = 0.6; // Modifies the original byte in rgb_b.
	assert(rgb_b[1] == 153);
}

struct Normalized(T) {

pure:
nothrow:

	static if (T.max < 1 << float.mant_dig) {
		private alias float F;
	} else static if (T.max < 1L << double.mant_dig) {
		private alias double F;
	} else {
		private alias real F;
	}

	alias T raw_type;
	alias F float_type;

	T raw;

	this(in F v) { this = v; }

	static Normalized fromRaw(T v) {
		Normalized n;
		n.raw = v;
		return n;
	}

	@property F value() const {
		return cast(F)raw / T.max;
	}

	@property ref Normalized value(F v) {
		v = min(v, 1);
		v = max(v, T.min < 0 ? -1 : 0);
		raw = cast(T)(v * T.max);
		return this;
	}

	alias value this;

	ref Normalized opOpAssign(string op, T2)(in T2 v) {
		mixin("return this = this " ~ op ~ " v;");
	}

}

