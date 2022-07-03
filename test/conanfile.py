from conans import ConanFile, CMake


class ImguiOpencvDemo(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    requires = "poco/1.10.1"

    generators = "cmake"

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def imports(self):
        self.copy("*.dll", dst="bin", src="bin")
        self.copy("*.dylib*", dst="bin", src="lib")
        self.copy("imgui_impl_glfw.cpp", dst="../src", src="./res/bindings")
        self.copy("imgui_impl_opengl3.cpp", dst="../src", src="./res/bindings")
        self.copy("imgui_impl_glfw.h*", dst="../include", src="./res/bindings")
        self.copy("imgui_impl_opengl3.h*", dst="../include", src="./res/bindings")