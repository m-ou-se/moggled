module moggle.core.vao;

import std.typetuple;

import moggle.core.gl;
import moggle.core.vbo;
import moggle.math.matrix;
import moggle.math.normalized;

/++ A vertex attribute object.

This is a wrapper around a GLuint generated by glGenVertexArrays(1, &id).
Initially, this id is 0.
glGenVertexArrays is automatically called the first time bind() is called.
+/
struct Vao {

	private GLuint id_ = 0;

	/// The id of this Vao, or 0 if it is not yet created in OpenGL.
	@property GLuint id() const { return id_; }

	/// Check if this Vao is already created in OpenGL.
	@property bool created() const { return id != 0; }

	/// ditto
	bool opCast(T : bool)() const { return created; }

	/// Force the creation of a OpenGL Vao, or do nothing if already created. (Calls glGenVertexArrays.)
	void create() {
		if (!id_) glGenVertexArrays(1, &id_);
		assert(id_, "glGenVertexArrays did not generate a vertex array.");
	}

	/// Destroy the OpenGL Vao and reset the id back to 0. (Calls glDeleteVertexArrays.)
	void destroy() {
		glDeleteVertexArrays(1, &id_);
		id_ = 0;
	}

	/// ditto
	~this() { destroy(); }

	/// Create the OpenGL Vao, if needed, and bind it. (Calls glBindVertexArray.)
	void bind() {
		create();
		glBindVertexArray(id_);
	}

	@disable this(this);

	/** Add or change an attribute. (Calls glEnableVertexAttribArray and glVertexAttribPointer.)

	The second version automatically deduces the parameters for
	glVertexAttribPointer using attributeParametersFor!T.
	*/
	void setAttribute()(GLuint index, ref GenericVbo vbo, AttributeParameters parameters) {
		bind();
		vbo.bind(GL_ARRAY_BUFFER);
		glEnableVertexAttribArray(index);
		glVertexAttribPointer(index, parameters);
	}

	/// ditto
	void setAttribute(T)(GLuint index, ref SpecificVbo!(T) vbo) {
		setAttribute(index, vbo, attributeParametersFor!T);
	}

	/// Disable an attribute. (Calls glDisableVertexAttribArray.)
	void disableAttribute(GLuint index) {
		bind();
		glDisableVertexAttribArray(index);
	}

}

/++ The tuple of parameters for glVertexAttribPointer that specify the type information.

The parameters are:

$(UL
	$(LI The size of the matrix/vector, or 1 for single elements.)
	$(LI The type of the elements. (One of GL_FLOAT, GL_INT, etc.))
	$(LI Whether the integral type is normalized (true) or not (false).)
	$(LI The stride, the distance in bytes to the next element.)
	$(LI The offset from the beginning of the buffer.)
)

You should check the documentation of glVertexAttribPointer for their details.
+/
alias TypeTuple!(GLint, GLenum, bool, GLsizei, const(void)*) AttributeParameters;

/++ The (automatically deduced) correct AttributeParameters for T.

Works for GLdouble, GLfloat, GLint, GLuint, GLshort, GLushort, GLbyte, GLubyte,
Normalized versions of these, and Matrices, Vectors and HVectors of all these.

The second version takes the name the member of T, for when the buffer contains
an array of T but only a single member of that T is what you want parameters for.
This automatically sets the stride and the offset to to the correct values
(T.sizeof and T.member.offsetof, respectively).

Examples:
---
// These two lines do the exact same.
glVertexAttribPointer(1, attributeParametersFor!int);
glVertexAttribPointer(1, 1, GL_INT, false, int.sizeof, null);
---
---
// These two lines do the exact same.
glVertexAttribPointer(1, attributeParametersFor!Matrix3f);
glVertexAttribPointer(1, 9, GL_FLOAT, false, Matrix3f.sizeof, null);
---
---
// These two lines do the exact same.
glVertexAttribPointer(1, attributeParametersFor!(Vector!(Normalized!ubyte, 4)));
glVertexAttribPointer(1, 4, GL_UBYTE, true, Vector!(Normalized!ubyte, 4).sizeof, null);
---
---
struct Vertex { HVector4f position; Vector3f normal; HVector4f color; }
// These two lines do the exact same.
glVertexAttribPointer(1, attributeParametersFor!(Vertex, "normal"));
glVertexAttribPointer(1, 3, GL_FLOAT, false, Vertex.size, cast(const(void)*)Vertex.normal.offsetof);
---
+/
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

/// ditto
template attributeParametersFor(T, string member) if (is(T == struct)) {
	alias attributeParametersFor!(typeof(__traits(getMember, T, member))) parameters;
	enum offset = __traits(getMember, T, member).offsetof;
	alias TypeTuple!(parameters[0..$-2], T.sizeof, cast(const(void)*)offset) attributeParametersFor;
}

