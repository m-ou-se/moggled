module moggle.core.shader;

import std.conv;
import std.file;
import moggle.core.gl;

enum ShaderType : GLenum {
	vertex = GL_VERTEX_SHADER,
	fragment = GL_FRAGMENT_SHADER
}

struct Shader {

	private GLuint id_ = 0;

	@property GLuint id() const { return id_; }

	@property bool created() const { return id != 0; }

	bool opCast(T : bool)() const {
		return created;
	}

	this(ShaderType t) { create(t); }

	@disable this(this);

	~this() {
		destroy();
	}

	void create(ShaderType t) {
		if (id_ && type() != t) destroy();
		if (!id_) id_ = glCreateShader(t);
	}

	void destroy() {
		glDeleteShader(id_);
		id_ = 0;
	}

	ShaderType type() const {
		GLint t;
		glGetShaderiv(id, GL_SHADER_TYPE, &t);
		return cast(ShaderType)t;
	}

	static Shader fromSource(ShaderType t, const(char)[] source_code) {
		auto s = Shader(t);
		s.load(source_code);
		s.compile();
		return s;
	}

	static Shader fromFile(ShaderType t, in char[] file_name) {
		auto s = Shader(t);
		s.load(cast(char[])read(file_name));
		s.compile();
		return s;
	}

	void load(const(char)[] source_code) {
		const char* s = source_code.ptr;
		const GLint n = cast(int)source_code.length;
		glShaderSource(id_, 1, &s, &n);
	}

	void try_compile() {
		glCompileShader(id_);
	}

	void compile() {
		try_compile();
		if (!compiled()) throw new ShaderCompilationError("glCompileShader: Unable to compile shader:\n" ~ log());
	}

	bool compiled() const {
		GLint status;
		glGetShaderiv(id, GL_COMPILE_STATUS, &status);
		return status != GL_FALSE;
	}

	string log() const {
		GLint log_size;
		glGetShaderiv(id, GL_INFO_LOG_LENGTH, &log_size);
		auto log = new char[log_size];
		if (log_size) glGetShaderInfoLog(id, log_size, null, log.ptr);
		return cast(string)log;
	}

}

struct ShaderProgram {

	private GLuint id_ = 0;

	@property GLuint id() const { return id_; }

	@property bool created() const { return id != 0; }

	bool opCast(T : bool)() const {
		return created;
	}

	@disable this(this);

	~this() {
		destroy();
	}

	void create() {
		if (!id_) id_ = glCreateProgram();
	}

	void destroy() {
		glDeleteProgram(id_);
		id_ = 0;
	}

	void clear() {
		destroy();
		create();
	}

	void attach(ref const Shader shader) {
		create();
		glAttachShader(id_, shader.id);
	}

	void bindAttribute(GLuint attribute, const(char)* name) {
		create();
		glBindAttribLocation(id_, attribute, name);
	}

	void tryLink() {
		glLinkProgram(id_);
	}

	void link() {
		tryLink();
		if (!linked()) throw new ShaderCompilationError("glLinkProgram: Unable to link program:\n" ~ log());
	}

	bool linked() const {
		GLint status;
		glGetProgramiv(id, GL_LINK_STATUS, &status);
		return status != GL_FALSE;
	}

	string log() const {
		GLint log_size;
		glGetProgramiv(id, GL_INFO_LOG_LENGTH, &log_size);
		auto log = new char[log_size];
		if (log_size) glGetProgramInfoLog(id, log_size, null, log.ptr);
		return cast(string)log;
	}

	void use() {
		glUseProgram(id_);
	}

	auto uniform(T)(const(char)* name) {
		return Uniform!T(glGetUniformLocation(id_, name));
	}

}

/** OpenGL uniform variable.

Really just a wrapper around the 'GLuint id' of the uniform variable.
(This id is also called 'location', obtained by glGetUniformLocation.)

Has a .set(value) that calls the correct glUniform function, based on the type.
(It calls one of:
 glUniform1f, glUniform1i, glUniform1ui, glUniform1fv, glUniform2fv,
 glUniform3fv, glUniform4fv, glUniform1iv, glUniform2iv, glUniform3iv,
 glUniform4iv, glUniform1uiV, glUniform2uiV, glUniform3uiv, glUniform4uiv,
 glUniformMatrix2fv, glUniformMatrix3fv, glUniformMatrix4fv,
 glUniformMatrix3x2fv, glUniformMatrix2x3fv, glUniformMatrix4x2fv,
 glUniformMatrix2x4fv, glUniformMatrix4x3fv,and glUniformMatrix3x4fv.)

Works for GLfloat, GLint, GLuint, Matrices/Vectors/HVectors of GLfloat,
both static and dynamic arrays of GLfloat, GLint and GL uint,
and both static and dynamic arrays of Matrices/Vectors/Hvectors of GLfloat.
*/
struct Uniform(T) {

	private GLuint location_ = 0;

	@property GLuint location() const { return id_; }

	this(GLuint id) { id_ = id; }

	void set(in T value) {

		static if (is(T == T2[length], T2, size_t length)) {
			enum static_length = length;
		} else static if (is(T == T2[], T2)) {
			size_t length = value.length;
			enum static_length = 0;
		} else {
			alias T T2;
			enum length = 1;
			enum static_length = 1;
		}

		static if (!is(T2 == Matrix!(base_type, height, width), base_type, size_t height, size_t width)) {
			enum width = 1;
			static if (!is(T2 == HVector!(base_type, height), base_type, size_t height)) {
				enum height = 1;
				alias T2 base_type;
			}
		}

		     static if (is(base_type == GLfloat)) enum type_name = "f";
		else static if (is(base_type == GLint  )) enum type_name = "i";
		else static if (is(base_type == GLuint )) enum type_name = "ui";
		else static assert(false, "This is not a valid type for glUniform.");

		static if (is(T == base_type)) { // e.g. T == float, T == int
			mixin("glUniform1" ~ type_name ~ "(id_, value);"); // e.g. glUniform1f
		} else {
			static if (is(T == T2) || is(T2 == base_type)) { // e.g. T == float[3], T == int[], T == Matrix!(int, 3)
				auto ptr = value.ptr;
			} else { // e.g. T == Matrix!(int, 3)[], T == Vector!(float, 2)[3]
				auto ptr = value[0].ptr;
			}
			static if (width == 1 || height == 1) {
				mixin("glUniform" ~ to!string(height * width) ~ type_name ~ "v(id_, cast(GLint)length, ptr);"); // e.g. glUniform3fv
			} else {
				mixin(
					"glUniformMatrix" ~ to!string(width) ~ (width == height ? "" : "x" ~ to!string(height)) ~
					type_name ~ "v(id_, cast(GLint)length, GL_TRUE, ptr);"
				); // e.g. glUniformMatrix2x3fv
			}
		}

	}

}

/// The error that is thrown when Shader.compile() or ShaderProgram.link() fail.
class ShaderCompilationError : Exception {
	this(string what, string file = __FILE__, size_t line = __LINE__) {
		super(what, file, line);
	}
};

