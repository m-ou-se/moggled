module moggle.xxx.vertices;

import std.string;
import std.format;
import std.conv;

import moggle.core.gl;
import moggle.core.vao;
import moggle.xxx.buffer;

/++ Manages an OpenGL vertex array object (Vao).

Keeps track of attributes of Vertices stored inside Buffers.
+/
final class Vertices {

	private Vao vao_;
	@property auto ref vao() inout { return vao_; }

	/// A vertex attribute.
	final class Attribute {

		/// The name of the attribute.
		immutable string name;

		/// The Buffer in which the data is stored.
		GenericBuffer buffer;

		/// How and where the data is stored in the Buffer. (See moggle.core.vao.)
		AttributeParameters parameters;

		private GLuint index_ = GLuint.max;

		/// The index of the attribute if it is enabled, or GLuint.max if it is not.
		@property GLuint index() const { return index_; }

		/// Check whether the attribute is enabled or not.
		@property bool enabled() const { return index_ != GLuint.max; }

		/++ Enable the attribute.

		Calls vao.setAttribute(index, buffer.vbo, parameters),
		which will call glEnableVertexAttribArray and glVertexAttribPointer.
		+/
		void enable(GLuint index) {
			vao.setAttribute(index, buffer.vbo, parameters);
			if (auto a = index in enabled_attributes_) a.index_ = GLuint.max;
			enabled_attributes_[index] = this;
			index_ = index;
		}

		/++ Disable the attribute.

		If enabled, calls vao.disableAttribute(index),
		which will call glDisableVertexAttribArray.
		+/
		void disable() {
			if (enabled) {
				vao.disableAttribute(index_);
				enabled_attributes_.remove(index_);
				index_ = GLuint.max;
			}
		}

		/// Get a string representation of this attribute (just the name).
		override string toString() const {
			return name;
		}

		private this(string n, GenericBuffer b, AttributeParameters p) {
			name = n; buffer = b; parameters = p;
		}

	}

	private Attribute[string] attributes_;
	private Attribute[GLuint] enabled_attributes_;

	/++ The attributes of the Vertices.
	Returns: A delegate that can be foreach'ed over.
	+/
	@property auto attributes() { return attributes_.byValue(); }

	/++ The attributes that are enabled.
	Returns: A delegate that can be foreach'ed over.
	+/
	@property auto enabledAttributes() { return enabled_attributes_.byValue(); }

	/++ Gives you the vertex Attribute with the given name or index.

	Throws: AttributeError when there is no such attribute.
	The exception message doesn't only tell the name/index of the attribute that doesn't exist,
	but also lists the attributes that do exist.
	+/
	auto attribute(string name, string file = __FILE__, size_t line = __LINE__) inout {
		if (auto a = name in attributes_) return *a;
		throw new AttributeError(format("No such attribute name: %s (Available are: %-(%s, %).)", name, attributes_.byKey()), file, line);
	}

	/// ditto
	auto attribute(GLuint index, string file = __FILE__, size_t line = __LINE__) inout {
		if (auto a = index in enabled_attributes_) return *a;
		throw new AttributeError(format("No such attribute index: %s (Available are: %-(%s, %).)", index, enabled_attributes_.byKey()), file, line);
	}

	/// Gives you a pointer to the Attribute with the given name or index, or null if it doesn't exist.
	auto hasAttribute(string name) inout {
		return name in attributes_;
	}

	/// ditto
	auto hasAttribute(GLuint index) inout {
		return index in enabled_attributes_;
	}

	/++ Add or change an attribute.

	Does not yet call vao.setAttribute(...).
	It only stores the information in the attributes map, such that you can later
	call attribute(name).enable(index), which will call vao.setAttribute.

	The second version automatically deduces the AttributeParameters
	using attributeParametersFor!T. (Defined in moggle.core.vao.)
	+/
	Attribute setAttribute()(in string name, GenericBuffer buffer, in AttributeParameters parameters) {
		return attributes_[name] = new Attribute(name, buffer, parameters);
	}

	/// ditto
	Attribute setAttribute(T)(in string name, Buffer!T buffer) {
		return setAttribute(name, buffer, attributeParametersFor!T);
	}

	/++ Automatically calls setAttribute for each member of the struct T.

	The second version takes a map that maps the names of the members
	of T to the names of the attributes.
	If a name is mapped to null, the member is ignored.

	Example:
	---
	struct Vertex { HVector4f position; Vector3f normal; HVector4 color; }
	auto b = new Buffer!Vertex(...);
	auto v = new Vertices;

	// This:
	v.setAttributes(b);
	// does the same as:
	v.setAttribute("position", b, attributeParametersFor!(Vertex, "position"));
	v.setAttribute("normal", b, attributeParametersFor!(Vertex, "normal"));
	v.setAttribute("color", b, attributeParametersFor!(Vertex, "color"));

	// Also, this:
	v.setAttributes(b, ["position":"pos", "normal":null]);
	// does the same as:
	v.setAttribute("pos", b, attributeParametersFor!(Vertex, "position"));
	v.setAttribute("color", b, attributeParametersFor!(Vertex, "color"));
	---
	+/
	void setAttributes(T)(Buffer!T buffer) if (is(T == struct)) {
		foreach (i, _; T.init.tupleof) {
			enum m = T.tupleof[i].stringof;
			enum member = m[m.lastIndexOf('.') + 1 .. $];
			setAttribute(member, buffer, attributeParametersFor!(T, member));
		}
	}

	/// ditto
	void setAttributes(T)(Buffer!T buffer, string[string] names) if (is(T == struct)) {
		foreach (i, _; T.init.tupleof) {
			enum m = T.tupleof[i].stringof;
			enum member = m[m.lastIndexOf('.') + 1 .. $];
			string name = member;
			if (auto p = name in names) name = *p;
			if (name) setAttribute(name, buffer, attributeParametersFor!(T, member));
		}
	}

	/// Bind the Vao. (Calls vao.bind().)
	void bind() {
		vao_.bind();
	}

}

/// The error that is thrown when Vertices.attribute(name) doesn't find an attribute with that name.
class AttributeError : Exception {
	this(string what, string file = __FILE__, size_t line = __LINE__) {
		super(what, file, line);
	}
};

