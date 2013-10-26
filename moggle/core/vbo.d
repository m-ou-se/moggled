module moggle.core.vbo;

import moggle.core.gl;

struct GenericVbo {

	private GLuint id_ = 0;

	@property GLuint id() const { return id_; }
	@property bool created() const { return id != 0; }

	void create() {
		if (!id_) glGenBuffers(1, &id_);
		assert(id_, "glGenBuffers did not generate a buffer.");
	}

	void destroy() {
		glDeleteBuffers(1, &id_);
		id_ = 0;
	}

	void bind(GLenum buffer) {
		create();
		glBindBuffer(buffer, id_);
	}

	bool opCast(T : bool)() const {
		return created;
	}

	ref inout(SpecificVbo!(T)) opCast(T : SpecificVbo!(T))() inout {
		return *cast(typeof(return)*)&this;
	}

	@disable this(this);

	~this() {
		destroy();
	}

}

struct SpecificVbo(T) {

	GenericVbo vbo_;

	alias vbo_ this;

	this(T[] data_, GLenum usage = GL_STATIC_DRAW) {
		data(data_, usage);
	}

	this(size_t size_, GLenum usage = GL_STATIC_DRAW) {
		resize(size_);
	}

	size_t size() {
		GLint s;
		bind(GL_ARRAY_BUFFER);
		glGetBufferParameteriv(GL_ARRAY_BUFFER, GL_BUFFER_SIZE, &s);
		return s / T.sizeof;
	}

	void data(T[] data_, GLenum usage = GL_STATIC_DRAW) {
		bind(GL_ARRAY_BUFFER);
		glBufferData(GL_ARRAY_BUFFER, data_.length * T.sizeof, data_.ptr, usage);
	}

	void resize(size_t size_, GLenum usage = GL_STATIC_DRAW) {
		bind(GL_ARRAY_BUFFER);
		glBufferData(GL_ARRAY_BUFFER, size_ * T.sizeof, null, usage);
	}

	void clear(GLenum usage = GL_STATIC_DRAW) {
		resize(0);
	}

	auto mapReadOnly() {
		bind(GL_ARRAY_BUFFER);
		auto p = cast(const T *) glMapBuffer(GL_ARRAY_BUFFER, GL_READ_ONLY);
		return VboMapping!(const T)(p[0..size()]);
	}

	auto mapWriteOnly() {
		bind(GL_ARRAY_BUFFER);
		auto p = cast(T *) glMapBuffer(GL_ARRAY_BUFFER, GL_READ_ONLY);
		return VboMapping!(T)(p[0..size()]);
	}

	auto mapReadWrite() {
		bind(GL_ARRAY_BUFFER);
		auto p = cast(T *) glMapBuffer(GL_ARRAY_BUFFER, GL_READ_WRITE);
		return VboMapping!(T)(p[0..size()]);
	}

}

template Vbo(T) {
	static if (is(T == void)) {
		alias GenericVbo Vbo;
	} else {
		alias SpecificVbo!T Vbo;
	}
}

struct VboMapping(T) {

	private T[] data_;

	@property inout(T[]) data() inout { return data_; }

	alias data this;

	@disable this(this);

	~this() {
		glUnmapBuffer(GL_ARRAY_BUFFER);
	}
}

