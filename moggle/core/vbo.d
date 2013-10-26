module moggle.core.vbo;

import moggle.core.gl;

struct generic_vbo {

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

	ref inout(specific_vbo!(T)) opCast(T : specific_vbo!(T))() inout {
		return *cast(typeof(return)*)&this;
	}

	@disable this(this);

	~this() {
		destroy();
	}

}

struct specific_vbo(T) {

	generic_vbo vbo_;

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

	auto map_read_only() {
		bind(GL_ARRAY_BUFFER);
		auto p = cast(const T *) glMapBuffer(GL_ARRAY_BUFFER, GL_READ_ONLY);
		return vbo_mapping!(const T)(p[0..size()]);
	}

	auto map_write_only() {
		bind(GL_ARRAY_BUFFER);
		auto p = cast(T *) glMapBuffer(GL_ARRAY_BUFFER, GL_READ_ONLY);
		return vbo_mapping!(T)(p[0..size()]);
	}

	auto map_read_write() {
		bind(GL_ARRAY_BUFFER);
		auto p = cast(T *) glMapBuffer(GL_ARRAY_BUFFER, GL_READ_WRITE);
		return vbo_mapping!(T)(p[0..size()]);
	}

}

template vbo(T) {
	static if (is(T == void)) {
		alias generic_vbo vbo;
	} else {
		alias specific_vbo!T vbo;
	}
}

struct vbo_mapping(T) {

	private T[] data_;

	@property inout(T[]) data() inout { return data_; }

	alias data this;

	@disable this(this);

	~this() {
		glUnmapBuffer(GL_ARRAY_BUFFER);
	}
}

