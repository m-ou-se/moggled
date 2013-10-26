module moggle.core.vao;

import std.typetuple;

import moggle.core.gl;
import moggle.core.vbo;
import moggle.math.matrix;
import moggle.math.normalized;

struct vao {

	private GLuint id_ = 0;

	@property GLuint id() const { return id_; }
	@property bool created() const { return id != 0; }

	void create() {
		if (!id_) glGenVertexArrays(1, &id_);
		assert(id_, "glGenVertexArrays did not generate a vertex array.");
	}

	void destroy() {
		glDeleteVertexArrays(1, &id_);
		id_ = 0;
	}

	void bind() {
		create();
		glBindVertexArray(id_);
	}

	bool opCast(T : bool)() const {
		return created;
	}

	@disable this(this);

	~this() {
		destroy();
	}

	void attribute()(GLuint index, ref generic_vbo vbo, AttributeParameters parameters) {
		bind();
		vbo.bind(GL_ARRAY_BUFFER);
		glEnableVertexAttribArray(index);
		glVertexAttribPointer(index, parameters);
	}

	void attribute(T)(GLuint index, ref specific_vbo!(T) vbo) {
		attribute(index, vbo, attributeParametersFor!T);
	}

}

alias TypeTuple!(GLint, GLenum, bool, GLsizei, const(void)*) AttributeParameters;

template attributeParametersFor(T) {
	static if (is(T == HVector!(E, N), E, size_t N)) {
		alias E element_type;
		enum size = N;
	} else static if (is(T == Matrix!(E, N, M), E, size_t N, size_t M)) {
		alias E element_type;
		enum size = N * M;
	} else {
		alias T element_type;
		enum size = 1;
	}
	enum normalized = is(element_type == Normalized!(base_type), base_type);
	static if (!normalized) alias element_type base_type;
	alias TypeTuple!(size, GL_type!base_type, normalized, T.sizeof, null) attributeParametersFor;
}

