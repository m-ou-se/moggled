module moggle.core.gl;

import std.traits;

import derelict.opengl3.gl3;
public import derelict.opengl3.types;
public import derelict.opengl3.constants;

pragma(lib, "dl");
pragma(lib, "DerelictGL3");
pragma(lib, "DerelictUtil");

static this() {
	DerelictGL3.load();
}

/// Call this after creating your OpenGL context.
GLVersion loadOpenGL() {
	return DerelictGL3.reload();
}

class GlError : Exception {
	this(string func, string what, string file = __FILE__, size_t line = __LINE__) {
		super(func ~ ": " ~ what, file, line);
	}
}

debug {
	// In debug mode, all glFunctions are aliasses for wrap!glFunction, which will throw an
	// exception in case glGetError() indicates an error before or after the function call.

	immutable string[uint] constant_names;

	static this() {
		foreach (x; __traits(allMembers, derelict.opengl3.constants)) {
			static if (x[0..3] == "GL_") {
				if (mixin(x) !in constant_names) constant_names[mixin(x)] = x;
			}
		}
	}

	void check_error(string file, size_t line, string func) {
		auto e = glGetError();
		if (e != GL_NO_ERROR) throw new GlError(func, constant_names[e], file, line);
	}

	auto wrap(alias glSomething)(ParameterTypeTuple!glSomething parameters, string file = __FILE__, size_t line = __LINE__)
	in { check_error(file, line, "Before " ~ __traits(identifier, glSomething)); }
	out { check_error(file, line, __traits(identifier, glSomething)); }
	body { return glSomething(parameters); }

	mixin((){
		string code;
		foreach (part, members; [
			"functions": [__traits(allMembers, derelict.opengl3.functions)],
			"arb": [__traits(allMembers, derelict.opengl3.arb)],
			"ext": [__traits(allMembers, derelict.opengl3.ext)]
		]) {
			foreach (x; members) {
				if (x[0..2] == "gl" && x != "glGetError") {
					code ~= "alias wrap!(derelict.opengl3." ~ part ~ "." ~ x ~ ") " ~ x ~ ";\n";
				} else if (x[0..2] == "GL" || x == "glGetError") {
					code ~= "alias derelict.opengl3." ~ part ~ "." ~ x ~ " " ~ x ~ ";\n";
				}
			}
		}
		return code;
	}());

} else {

	public import derelict.opengl3.functions;
	public import derelict.opengl3.arb;
	public import derelict.opengl3.ext;

}

template GL_type(T) {
	     static if (is(T == GLfloat )) alias GL_FLOAT          GL_type;
	else static if (is(T == GLdouble)) alias GL_DOUBLE         GL_type;
	else static if (is(T == GLubyte )) alias GL_UNSIGNED_BYTE  GL_type;
	else static if (is(T == GLbyte  )) alias GL_BYTE           GL_type;
	else static if (is(T == GLushort)) alias GL_UNSIGNED_SHORT GL_type;
	else static if (is(T == GLshort )) alias GL_SHORT          GL_type;
	else static if (is(T == GLuint  )) alias GL_UNSIGNED_INT   GL_type;
	else static if (is(T == GLint   )) alias GL_INT            GL_type;
}
