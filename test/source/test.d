import std.stdio;
import std.exception;
import std.algorithm;
import moggle.math.matrix;
import moggle.math.normalized;
import moggle.core.gl;
import moggle.core.vbo;
import moggle.core.vao;
import moggle.core.shader;
import moggle.xxx.buffer;
import moggle.xxx.vertices;

// GLFW is used to create a window.
import derelict.glfw3.glfw3;
pragma(lib, "DerelictGLFW3");

void main() {
	DerelictGLFW3.load();
	enforce(glfwInit(), "glfwInit failed.");
	auto window = glfwCreateWindow(640, 480, "Test", null, null);
	enforce(window, "glfwCreateWindow failed.");
	glfwMakeContextCurrent(window);
	loadOpenGL();

	auto vs = Shader.fromSource(ShaderType.vertex, q{
		attribute vec4 position;
		void main() {
			gl_Position = position;
		}
	});

	auto fs = Shader.fromSource(ShaderType.fragment, q{
		void main() {
			gl_FragColor = vec4(1, 0, 0, 1);
		}
	});

	auto sp = ShaderProgram();
	sp.attach(vs);
	sp.attach(fs);
	sp.bindAttribute(0, "position");
	sp.link();
	sp.use();

	auto b = new Buffer!HVector4f([
		HVector4f(0, 0),
		HVector4f(0, 1),
	]);

	b ~= HVector4f(1, 1);

	b.sync();

	auto a = new Vertices();
	a.setAttribute("position", b).enable(0);
	a.bind();

	glClearColor(0.1, 0.3, 0.7, 1);

	while (!glfwWindowShouldClose(window)) {
		glClear(GL_COLOR_BUFFER_BIT);
		glDrawArrays(GL_TRIANGLES, 0, 3);
		glfwSwapBuffers(window);
		glfwPollEvents();
	}

}

