module moggle.math.matrix;

import std.conv;
import std.traits;
import std.math;
import std.algorithm;

/// An N by M Matrix of T.
struct Matrix(T, size_t N, size_t M = N) {

	static assert(N > 0 && M > 0, "Zero sized matrices are not supported.");
	static assert(is(Unqual!T == T), "Don't use const or immutable types as elements.");

	private T[N*M] values;

	alias N height;
	alias M width;

	pure nothrow {

		this()(in const(T)[N*M] v ...) { this = v; }
		this(T2)(in Matrix!(T2, N, M) m) { this = m; }

		ref Matrix opAssign()(in const(T)[N*M] v) {
			values = v;
			return this;
		}

		ref Matrix opAssign(T2)(in Matrix!(T2, N, M) m) {
			foreach (i; 0 .. N*M) values[i] = m[i];
			return this;
		}

		@property auto ptr() inout { return values.ptr; }

		static if (M == 1) {

			this(size_t N2)(in const(T)[N2] v ...) if (N2 < N) { this = v; }
			this(T2, size_t N2)(in Matrix!(T2, N2, 1) v) if (N2 < N) { this = v; }

			ref Matrix opAssign(size_t N2)(in const(T)[N2] v ...) if (N2 < N) {
				values[0..v.length] = v;
				values[v.length..$] = 0;
				return this;
			}

			ref Matrix opAssign(T2, size_t N2)(in Matrix!(T2, N2, 1) v) if (N2 < N) {
				foreach (i; 0 .. N2) values[i] = v[i];
				values[N2 .. $] = 0;
				return this;
			}

		}

		@property static Matrix zero() {
			Matrix m;
			m[] = cast(T)0;
			return m;
		}

		static if (N == M)
		@property static Matrix identity() {
			auto m = zero;
			foreach (i; 0 .. N) m[i, i] = 1;
			return m;
		}

		ref auto opIndex(size_t i) inout { return values[i]; }
		ref auto opIndex(size_t n, size_t m) inout { return values[n*M + m]; }

		auto opSlice() inout { return values[]; }
		auto opSliceAssign(T2)(in T2 v) { values[] = v; }
		auto opSliceOpAssign(string op, T2)(in T2 v) { mixin("values[] " ~ op ~ "= v;"); }

		size_t opDollar() const { return N*M; }

		auto transposed() const {
			Matrix!(T, M, N) result;
			foreach (i; 0 .. N) foreach (j; 0 .. M) result[j, i] = this[i, j];
			return result;
		}

		static if (N > 1 && M > 1) {

			Matrix!(T, N, 1) column(size_t k) const {
				typeof(return) m;
				foreach (i; 0 .. N) m[i] = this[i, k];
				return m;
			}

			Matrix!(T, 1, M) row(size_t k) const {
				T[M] r = values[k*M .. (k+1)*M];
				return typeof(return)(r);
			}

			static if (M > 1)
			Matrix!(T, N, M-1) without_column(size_t k) const {
				typeof(return) m;
				foreach (i; 0 .. N) foreach (j; 0 .. M-1) {
					m[i, j] = this[i, j + (j >= k)];
				}
				return m;
			}

			static if (N > 1)
			Matrix!(T, N-1, M) without_row(size_t k) const {
				typeof(return) m;
				foreach (i; 0 .. N-1) foreach (j; 0 .. M) {
					m[i, j] = this[i + (i >= k), j];
				}
				return m;
			}

			static if (N > 1 && M > 1)
			Matrix!(T, N-1, M-1) without_row_column(size_t r, size_t c) const {
				typeof(return) m;
				foreach (i; 0 .. N-1) foreach (j; 0 .. M-1) {
					m[i, j] = this[i + (i >= r), j + (j >= c)];
				}
				return m;
			}

		}

		static if (M == 1) {

			auto length() const {
				CommonType!(T, float) d = this * this;
				return sqrt(d);
			}

			auto normalized() const {
				return this / length;
			}

			static if (!isIntegral!T)
			void normalize() {
				this /= length;
			}

		}

		static if (N == M) {

			void transpose() {
				this = transposed;
			}

			T determinant() const {
				static if (N == 1) {
					return this[0];
				} else static if (N == 2) {
					return cast(T)(this[0, 0] * this[1, 1] - this[0, 1] * this[1, 0]);
				} else static if (N == 3) {
					return cast(T)(
						this[0, 0] * (this[1, 1] * this[2, 2] - this[2, 1] * this[1, 2]) +
						this[1, 0] * (this[2, 1] * this[0, 2] - this[0, 1] * this[2, 2]) +
						this[2, 0] * (this[0, 1] * this[1, 2] - this[1, 1] * this[0, 2])
					);
				} else { // Generic case. (Would work for any N.)
					T result = 0;
					foreach (i; 0 .. N) result += this[0, i] * cofactor(0, i);
					return result;
				}
			}

			T cofactor(size_t n, size_t m) const {
				static if (N == 1) {
					return cast(T)1;
				} else {
					auto d = without_row_column(n, m).determinant;
					return (n + m) % 2 ? -d : d;
				}
			}

			Matrix cofactor_matrix() const {
				Matrix result;
				foreach (i; 0 .. N) foreach (j; 0 .. M) result[i, j] = cofactor(i, j);
				return result;
			}

			Matrix adjugate() const {
				return cofactor_matrix.transposed;
			}

			Matrix inverse() const {
				auto a = adjugate;
				return a /= determinant;
			}

			void invert() {
				this = inverse;
			}

		}

		// M+=M, M-=M
		ref Matrix opOpAssign(string op, T2)(in Matrix!(T2, N, M) m)
		if (op == "+" || op == "-") {
			foreach (i; 0 .. N*M) mixin("this[i] " ~ op ~ "= m[i];");
			return this;
		}

		// V+=V, V-=V (different sizes)
		static if (M == 1)
		ref Matrix opOpAssign(string op, T2, size_t N2)(in Matrix!(T2, N2, 1) m)
		if ((op == "+" || op == "-") && N2 < N) {
			foreach (i; 0 .. N2) mixin("this[i] " ~ op ~ "= m[i];");
			return this;
		}

		// M+M, M-M
		auto opBinary(string op, T2)(in Matrix!(T2, N, M) m) const
		if (op == "+" || op == "-") {
			Matrix!(Unqual!(typeof(this[0] + m[0])), N, M) result;
			foreach (i; 0 .. N*M) mixin("result[i] = this[i] " ~ op ~ " m[i];");
			return result;
		}

		// V+V, V-V (different sizes)
		static if (M == 1)
		auto opBinary(string op, T2, size_t N2)(in Matrix!(T2, N2, 1) m) const
		if ((op == "+" || op == "-") && N != N2) {
			Matrix!(Unqual!(typeof(this[0] + m[0])), max(N, N2), 1) result;
			foreach (i; 0 .. result.height) mixin("result[i] = (i < N ? this[i] : 0) " ~ op ~ " (i < N2 ? m[i] : 0);");
			return result;
		}

		// +M, -M
		Matrix opUnary(string op)() const
		if (op == "+" || op == "-") {
			Matrix m;
			foreach (i; 0 .. N*M) mixin("m[i] = " ~ op ~ "this[i];");
			return m;
		}

		// M*S, M/S
		auto opBinary(string op, T2)(in T2 v) const
		if ((op == "*" || op == "/") && !isInstanceOf!(moggle.math.matrix.Matrix, T2)) {
			Matrix!(Unqual!(typeof(this[0] * v)), N, M) result;
			foreach (i; 0 .. N*M) mixin("result[i] = this[i] " ~ op ~ " v;");
			return result;
		}

		// S*M
		auto opBinaryRight(string op, T2)(in T2 v) const
		if (op == "*" && !isInstanceOf!(moggle.math.matrix.Matrix, T2)) {
			Matrix!(Unqual!(typeof(v * this[0])), N, M) result;
			foreach (i; 0 .. N*M) mixin("result[i] = v " ~ op ~ " this[i];");
			return result;
		}

		// M*=S, M/=S
		ref Matrix opOpAssign(string op, T2)(in T2 v)
		if ((op == "*" || op == "/") && !isInstanceOf!(moggle.math.matrix.Matrix, T2)) {
			foreach (i; 0 .. N*M) mixin("this[i] " ~ op ~ "= v;");
			return this;
		}

		// V*V
		static if (M == 1)
		auto opBinary(string op, T2, size_t N2)(in Matrix!(T2, N2, 1) m) const
		if (op == "*") {
			Unqual!(typeof(this[0] * m[0])) result = 0;
			foreach (i; 0 .. min(N, N2)) result += this[i] * m[i];
			return result;
		}

		// M*M
		auto opBinary(string op, T2, size_t M2)(in Matrix!(T2, M, M2) m) const
		if (op == "*" && (N != 1 || M != 1 || M2 != 1)) {
			Matrix!(typeof(row(0).transposed * m.column(0)), N, M2) result;
			foreach (i; 0 .. result.height)
			foreach (j; 0 .. result.width) {
				result[i, j] = row(i).transposed * m.column(j);
			}
			return result;
		}

		// M*=M
		static if (N == M)
		ref Matrix opOpAssign(string op, T2)(in Matrix!(T2, N, N) m)
		if (op == "*") {
			this = this * m;
			return this;
		}

	}

	static if (M == 1) {
		auto opSlice(size_t i, size_t j) inout { return values[i..j]; }
		auto opSliceAssign(T2)(T2 v, size_t i, size_t j) { values[i..j] = v; }
		auto opSliceOpAssign(string op, T2)(T2 v, size_t i, size_t j) { mixin("values[i..j] " ~ op ~ "= v;"); }
	}

	string toString() const {
		string s = "[";
		foreach (i; 0 .. N) {
			if (i) s ~= ";";
			foreach (j; 0 .. M) {
				if (i || j) s ~= " ";
				s ~= text(this[i, j]);
			}
		}
		return s ~= "]";
	}

}

///
unittest {
	// Matrix!(T=ElementType, N=Height, M=Width) can be initialized
	// with an array of N*M elements, or by passing N*M values to the constructor.
	auto m = Matrix!(float, 2, 3)(
		7, 3, 2,
		9, 1, 5,
	);

	// Elements can be accessed with [i] (i=0..N*M) and [row, column] (row=0..N, column=0..M)
	assert(m[4] == 1);
	assert(m[1, 1] == 1);
	assert(m[0, 2] == 2);

	// A matrix is default-initialied to just N*M default-initialized Ts.
	{
		Matrix!(float, 3, 3) a;
		Matrix!(int, 2, 3) b;
		assert(isNaN(a[2]));
		assert(b[2] == 0);
	}

	// .zero gives a zero-filled matrix.
	{
		auto a = Matrix!(float, 3, 3).zero;
		assert(a[3] == 0);
	}

	// For square matrices, .identity gives the identity matrix.
	{
		auto a = Matrix!(float, 2, 2).identity;
		// The identity is also accessible as a.identity.
		assert(a[0, 0] == 1);
		assert(a[0, 1] == 0);
	}

	// .width and .height are aliases for N and M.
	assert(Matrix!(int, 13, 37).height == 13);
	assert(m.width == 3);

	// [] gives a T[] slice of all N*M elements.
	assert(m[] == [7, 3, 2, 9, 1, 5]);
	m[] = 0;
	assert(m == m.zero);

	// .transposed gives the transposed M*N matrix.
	assert(m.transposed.width == m.height);
	assert(m.transposed.height == m.width);
	m[0, 2] = 4;
	assert(m.transposed[2, 0] == 4);

	// For square matrices, .transpose() transposes the matrix in place.
	{
		auto a = Matrix!(float, 2, 2)(1, 2, 3, 4);
		a.transpose();
		assert(a[] == [1, 3, 2, 4]);
	}

	// Vectors are just matrices with a width of 1. Vector!(T, N) is just an alias.
	assert(is(Vector!(float, 3) == Matrix!(float, 3, 1)));

	// For vectors, [i..j] can be used to get/set/modify a part of the vector.
	auto a = Vector!(float, 4).zero;
	a[0..2] = 1;
	a[1..3] += 2;
	assert(a[0..3] == [1, 3, 2]);

	// Vectors of different sizes can be used together, they're padded with zeros.
	a += Vector!(float, 2)(1, 2);
	assert(a[] == [2, 5, 2, 0]);
	assert((a - Vector!(float, 5)(0, 0, 0, 0, 1))[] == [2, 5, 2, 0, -1]);

	// .column(i) and .row(i) give you a specific row or column as N*1 or 1*M matrix, respectively.
	assert(m.row(0)[] == [0, 0, 4]);
	assert(m.column(2)[] == [4, 0]);
	assert(m.row(0).height == 1);
	assert(m.column(0).width == 1);

	// .without_row(i), .without_column(i), and .without_row_column(r, c) do as they say.
	assert(m.without_column(1) == Matrix!(float, 2, 2)(0, 4, 0, 0));
	assert(m.without_row(1) == Matrix!(float, 1, 3)(0, 0, 4));
	assert(m.without_row_column(1, 1) == Matrix!(float, 1, 2)(0, 4));

	// For (column) vectors, .length gives the Euclidian length,
	// .normalized and .normalize do what you want.
	Vector!(float, 2) v = [3, 4];
	assert(v.length == 5);
	assert(v.normalized == Vector!(float, 2)(0.6, 0.8));
	v.normalize();
	assert(v.length == 1);

	// For square matrices, there is .determinant, .cofactor(row, column),
	// .cofactor_matrix, .adjugate, .inverse and .invert.
	Matrix!(float, 3, 3) x = [
		1, 2, 3,
		0, 6, 1,
		0, 5, 0,
	];
	assert(x.determinant == -5);
	assert(x.cofactor(1, 0) == -x.without_row_column(1, 0).determinant);
	assert(x.cofactor_matrix[1, 0] == x.cofactor(1, 0));
	assert(x.adjugate == x.cofactor_matrix.transposed);
	assert(x.inverse == x.adjugate / x.determinant);
	x.invert();
	assert(x.column(1)[] == [-3, 0, 1]);

	// You can add and subtract same-sized matrices with +=, -=, + and -,
	// and scale them with *=, /=, *, and /.
	auto y = x.without_row(2) + m;
	y -= -m * 2;
	y /= 0.5;
	assert(y[1] == -6);

	// Matrix multiplication is done with * and *=.
	assert(x * x.inverse == x.identity);
	x *= x.inverse;
	assert(x == x.identity);

	// For vectors, * gives you the dot product.
	assert(v * v == 1);

	// There are aliases available for the most common matrices and vectors.
	// (1..4 in size, for types int, float, double and real.)
	assert(is(Matrix2x3f == Matrix!(float, 2, 3)));
	assert(is(Matrix3d == Matrix!(double, 3, 3)));
	assert(is(Vector2i == Vector!(int, 2)));
	assert(is(HVector4r == HVector!(real, 4)));
}

/// Alias for a Matrix with a width of 1.
template Vector(T, size_t N) {
	alias Matrix!(T, N, 1) Vector;
}

/// A 'homogeneous vector': A vector with the last element set to 1 by default.
struct HVector(T, size_t N) {

	Vector!(T, N) vector;

	alias vector this;

pure nothrow:

	this(size_t N2)(const(T)[N2] v ...) if (N2 <= N) { this = v; }
	this(T2, size_t N2)(in Matrix!(T2, N2, 1) v) if (N2 <= N) { this = v; }

	ref HVector opAssign(size_t N2)(const(T)[N2] v ...) if (N2 <= N) {
		vector = v;
		if (v.length < N) vector[$-1] = 1;
		return this;
	}

	ref HVector opAssign(T2, size_t N2)(in Matrix!(T2, N2, 1) v) if (N2 <= N) {
		vector = v;
		if (v.length < N) vector[$-1] = 1;
		return this;
	}

	// Length (and therefore, normalizing) doesn't make sense for these kind of vectors.
	@disable void length();
	@disable void normalized();
	@disable void normalize();

}

///
unittest {
	// A HVector is a Vector with the last element set to 1 by default.
	// This is handy for 4D representations of positions in 3D graphics
	// and RGBA color vectors.
	auto h = HVector4d(1, 0.3, 0.4);
	assert(h[] == [1, 0.3, 0.4, 1]);
	h = [0, 2, 3];
	assert(h[] == [0, 2, 3, 1]);

	// They can be converted back and forth to normal vectors.
	Vector4d v = h;
	HVector4d h1 = w;
	HVector4d h2 = Vector3d(1, 2, 3);
	h = v;
	v = h;
	h += v;
}

// Aliases for MatrixNxMt, MatrixNt, and VectorNt. (With t = i,f,d,r.)
mixin((){
	string code;
	auto types = ["i":"int", "f":"float", "d":"double", "r":"real"];
	foreach (k, t; types) {
		foreach (n; 1 .. 5) foreach (m; 1 .. 5) {
			if (n == 1 && m == 1) continue;
			code ~= text("alias Matrix!(", t, ",", n, ",", m, ") Matrix", n, "x", m, k, ";\n");
		}
		foreach (m; ["Matrix", "Vector", "HVector"]) foreach (n; 2 .. 5) {
			code ~= text("alias ", m, "!(", t, ",", n, ") ", m, n, k, ";\n");
		}
	}
	return code;
}());

