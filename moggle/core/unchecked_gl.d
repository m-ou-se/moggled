module moggle.core.unchecked_gl;

import derelict.opengl3.gl3;

public {
	import derelict.opengl3.types;
	import derelict.opengl3.constants;
	import derelict.opengl3.functions;
	import derelict.opengl3.arb;
	import derelict.opengl3.ext;
}

static this() {
	DerelictGL3.load();
}

/// Call this after creating your OpenGL context.
GLVersion loadOpenGL() {
	return DerelictGL3.reload();
}

pragma(lib, "dl");
pragma(lib, "DerelictGL3");
pragma(lib, "DerelictUtil");

template GL_type(T) {
	     static if (is(T == GLfloat )) alias GL_FLOAT          GL_type;
	else static if (is(T == GLdouble)) alias GL_DOUBLE         GL_type;
	else static if (is(T == GLuint  )) alias GL_UNSIGNED_INT   GL_type;
	else static if (is(T == GLint   )) alias GL_INT            GL_type;
	else static if (is(T == GLubyte )) alias GL_UNSIGNED_BYTE  GL_type;
	else static if (is(T == GLbyte  )) alias GL_BYTE           GL_type;
	else static if (is(T == GLushort)) alias GL_UNSIGNED_SHORT GL_type;
	else static if (is(T == GLshort )) alias GL_SHORT          GL_type;
}
