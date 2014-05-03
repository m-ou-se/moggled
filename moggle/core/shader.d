module moggle.core.shader;

import std.conv;
import std.file;
import moggle.core.gl;

/// The type of a Shader.
enum ShaderType : GLenum {
	vertex = GL_VERTEX_SHADER, /// A vertex shader (GL_VERTEX_SHADER).
	fragment = GL_FRAGMENT_SHADER /// A fragment shader (GL_FRAGMENT_SHADER).
}

/++ An OpenGL shader.

This is a wrapper around a GLuint created by glCreateShader(type).
+/
struct Shader {

	private GLuint id_ = 0;

	/// Ths id of this Shader, or 0 if it is not yet created in OpenGL.
	@property GLuint id() const { return id_; }

	/// Check if this Shader is already created in OpenGL.
	@property bool created() const { return id != 0; }
	/// ditto
	bool opCast(T : bool)() const { return created; }

	@disable this(this);

	/++ Create a shader of the specified type.

	If the shader is already created, nothing will happen
	if it is of the same type, or it is destroyed and (re)created
	if it is of a different type.
	+/
	this(ShaderType t) { create(t); }

	/// ditto
	void create(ShaderType t) {
		if (id_ && type() != t) destroy();
		if (!id_) id_ = glCreateShader(t);
	}

	/// Create, load, and compile a shader directly from source code.
	static Shader fromSource(ShaderType t, in char[] source_code) {
		auto s = Shader(t);
		s.load(source_code);
		s.compile();
		return s;
	}

	/// Create, load, and compile a shader directly from a file.
	static Shader fromFile(ShaderType t, in char[] file_name) {
		auto s = Shader(t);
		s.load(cast(char[])read(file_name));
		s.compile();
		return s;
	}

	/// Destroy the OpenGL Shader and reset the id back to 0.
	void destroy() {
		glDeleteShader(id_);
		id_ = 0;
	}

	/// ditto
	~this() { destroy(); }

	/// The type of this shader.
	ShaderType type() const {
		GLint t;
		glGetShaderiv(id, GL_SHADER_TYPE, &t);
		return cast(ShaderType)t;
	}

	/// Load the source code for the shader.
	void load(in char[] source_code) {
		const char* s = source_code.ptr;
		const GLint n = cast(int)source_code.length;
		glShaderSource(id_, 1, &s, &n);
	}

	/// Try to compile the Shader, check compiled() to see if it succeeded.
	void try_compile() {
		glCompileShader(id_);
	}

	/++ Try to compile, and throw if it didn't succeed.

	Throws: ShaderCompilationError containing the error log on failure.
	+/
	void compile() {
		try_compile();
		if (!compiled()) throw new ShaderCompilationError("glCompileShader: Unable to compile shader:\n" ~ log());
	}

	/// Check if the Shader is succesfully compiled.
	bool compiled() const {
		GLint status;
		glGetShaderiv(id, GL_COMPILE_STATUS, &status);
		return status != GL_FALSE;
	}

	/// The log of errors for when compilation fails.
	string log() const {
		GLint log_size;
		glGetShaderiv(id, GL_INFO_LOG_LENGTH, &log_size);
		auto log = new char[log_size];
		if (log_size) glGetShaderInfoLog(id, log_size, null, log.ptr);
		return cast(string)log;
	}

}

/++ An OpenGL shader program.

This is a wrapper around a GLuint created by glCreateProgram().
Initially, this id is 0.
glCreateProgram is automatically called the first time anything is done with the object.
+/
struct ShaderProgram {

	private GLuint id_ = 0;

	/// Ths id of this ShaderProgram, or 0 if it is not yet created in OpenGL.
	@property GLuint id() const { return id_; }

	/// Check if this ShaderProgram is already created in OpenGL.
	@property bool created() const { return id != 0; }
	/// ditto
	bool opCast(T : bool)() const { return created; }

	@disable this(this);

	/// Force the creation of a OpenGL ShaderProgram, or do nothing if already created. (Calls glCreateProgram.)
	void create() {
		if (!id_) id_ = glCreateProgram();
		assert(id_, "glCreateProgram did not generate a shader program.");
	}

	/// Destroy the OpenGL Vao and reset the id back to 0. (Calls glDeleteProgram.)
	void destroy() {
		glDeleteProgram(id_);
		id_ = 0;
	}

	/// ditto
	~this() { destroy(); }

	/// destroy() and create().
	void clear() {
		destroy();
		create();
	}

	/// Attach a Shader to this program. (Calls glAttachShader.)
	void attach(ref const Shader shader) {
		create();
		glAttachShader(id_, shader.id);
	}

	/// Bind an attribute name to a location. (Calls glBindAttribLocation.)
	void bindAttribute(GLuint attribute, const(char)[] name) {
		name ~= '\0';
		create();
		glBindAttribLocation(id_, attribute, name.ptr);
	}

	/// Try to link the ShaderProgram, check linked() to see if it succeeded. (Calls glLinkProgram.)
	void tryLink() {
		glLinkProgram(id_);
	}

	/++ Try to link, and throw if it didn't succeed.

	Throws: ShaderCompilationError containing the error log on failure.
	+/
	void link() {
		tryLink();
		if (!linked()) throw new ShaderCompilationError("glLinkProgram: Unable to link program:\n" ~ log());
	}

	/// Check if the ShaderProgram is succesfully linked. (Calls glGetProgramiv with GL_LINK_STATUS.)
	bool linked() const {
		GLint status;
		glGetProgramiv(id, GL_LINK_STATUS, &status);
		return status != GL_FALSE;
	}

	/// The log of errors for when linking fails. (Calls glGetProgramInfoLog.)
	string log() const {
		GLint log_size;
		glGetProgramiv(id, GL_INFO_LOG_LENGTH, &log_size);
		auto log = new char[log_size];
		if (log_size) glGetProgramInfoLog(id, log_size, null, log.ptr);
		return cast(string)log;
	}

	/// Use this ShaderProgram. (Calls glUseProgram.)
	void use() {
		glUseProgram(id_);
	}

	/// Look up a uniform variable by its name. (Calls glGetUniformLocation.)
	Uniform!T uniform(T)(const(char)* name) {
		create();
		return Uniform!T(glGetUniformLocation(id_, name));
	}

}

/++ OpenGL uniform variable.

This is a wrapper around a GLuint generated by glGetUniformLocation(program, name).

An object of this type is returned by ShaderProgram.uniform(name).
+/
struct Uniform(T) {

	private GLuint id_ = 0;

	/// The location of this Uniform.
	@property GLuint location() const { return id_; }

	this(GLuint id) { id_ = id; }

	/++ Calls the correct glUniform function, based on the type T.

	(It calls one of:
	glUniform1f, glUniform1i, glUniform1ui, glUniform1fv, glUniform2fv,
	glUniform3fv, glUniform4fv, glUniform1iv, glUniform2iv, glUniform3iv,
	glUniform4iv, glUniform1uiV, glUniform2uiV, glUniform3uiv, glUniform4uiv,
	glUniformMatrix2fv, glUniformMatrix3fv, glUniformMatrix4fv,
	glUniformMatrix3x2fv, glUniformMatrix2x3fv, glUniformMatrix4x2fv,
	glUniformMatrix2x4fv, glUniformMatrix4x3fv,and glUniformMatrix3x4fv.)

	Works for GLfloat, GLint, GLuint, Matrices/Vectors/HVectors of GLfloat,
	both static and dynamic arrays of GLfloat, GLint and GLuint,
	and both static and dynamic arrays of Matrices/Vectors/Hvectors of GLfloat.
	+/
	void set(in T value) {

		static if (is(T == T2[], T2)) {
			size_t length = value.length;
		} else static if (!is(T == T2[length], T2, size_t length)) {
			alias T T2;
			enum length = 1;
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

