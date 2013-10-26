module moggle.core.gl;

import std.traits;

import moggle.core.unchecked_gl;

public import moggle.core.unchecked_gl : loadOpenGL;

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
		foreach (x; [
			__traits(allMembers, derelict.opengl3.functions),
			__traits(allMembers, derelict.opengl3.constants),
			__traits(allMembers, derelict.opengl3.types),
			__traits(allMembers, derelict.opengl3.arb),
			__traits(allMembers, derelict.opengl3.ext),
			__traits(allMembers, moggle.core.unchecked_gl)
		]) {
			if (x[0..2] == "gl" && x != "glGetError") {
				code ~= "alias wrap!(moggle.core.unchecked_gl." ~ x ~ ") " ~ x ~ ";\n";
			} else if (x[0..2] == "GL" || x == "glGetError") {
				code ~= "alias moggle.core.unchecked_gl." ~ x ~ " " ~ x ~ ";\n";
			}
		}
		return code;
	}());

} else {

	public import moggle.core.unchecked_gl;

}

