module moggle.xxx.buffer;

import moggle.core.vbo;

/++ Manages a OpenGL vertex buffer object (Vbo).

Contains a Vbo!T object, and a T[], which it can keep in sync.

Basically, a Vbo!T has data stored in the GPU memory (for OpenGL),
while the T[] has data stored in the CPU memory (for us).
If you modify the T[] and want the changes to be reflected on the GPU,
call markDirty(). Then, the next call to sync() will (re)upload the data to the GPU.
If you don't want to keep a copy of the data in the CPU memory, just empty the T[]
and don't call markDirty().
syncBack() can be used to download the data again from the GPU into the CPU memory.

Note that a Vbo!T is only allocated on the GPU (in OpenGL) the first time it is used.
So until the first time sync() uploads the data, there is nothing allocated in OpenGL,
not even an empty Vbo. (Unless vbo.create() is called explicitly, of course.)
+/
class Buffer(T) : GenericBuffer {

	/// The Vbo!T holding the GPU's (OpenGL's) copy of the data.
	@property auto ref vbo() inout { return cast(inout(Vbo!T))vbo_; }

	/++ The T[] containing the CPU's (our) copy of the data.

	This member is aliassed as 'this', so you can use a Buffer!T object directly
	as if it is a T[]:
	---
	auto b = new Buffer!T([1,2,3]);
	x[1] = 10;
	---
	+/
	T[] data;
	alias data this;

	private bool dirty_ = false;

	/// Check if the Buffer is marked as dirty. (i.e. sync() would do anything.)
	@property bool is_dirty() const { return dirty_; }

	/// Mark the Buffer as dirty, such that the next call to sync() will upload the data to the GPU memory.
	void markDirty() { dirty_ = true; }

	/++ Allocate a new Buffer to hold the given data.

	The Buffer is directly marked as dirty if d is not empty.
	+/
	this(T[] d ...) {
		data = d;
		dirty_ = data.length != 0;
	}

	/// If the Buffer is marked as dirty, uploads the data from the T[] (CPU/us) to the Vbo!T (GPU/OpenGL). Resets is_dirty.
	override void sync() {
		if (dirty_) vbo.data(data);
		dirty_ = false;
	}

	/// Download the data form the Vbo!T (GPU/OpenGL) to the T[] (CPU/us).
	void syncBack() {
		auto m = vbo.mapReadOnly();
		data.length = m.length;
		data[] = m[];
	}

}

/++ The base class of all Buffer!T objects.

Doesn't know what type of objects are stored in the Buffer, but can still sync() it and access the Vbo.
+/
class GenericBuffer {

	protected GenericVbo vbo_;

	/// If the Buffer is marked as dirty, uploads the data from the T[] (CPU/us) to the Vbo!T (GPU/OpenGL). Resets is_dirty.
	abstract void sync();

	/// The GenericVbo holding the GPU's (OpenGL's) copy of the data.
	@property final auto ref vbo() inout { return vbo_; }

}

