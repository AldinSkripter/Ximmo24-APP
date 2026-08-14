allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt != null) {
                // Force compileSdk=36 on plugin subprojects that don't set one (fixes android:attr/lStar).
                try {
                    val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    setCompileSdk.invoke(androidExt, 36)
                } catch (_: NoSuchMethodException) {
                    try {
                        val setCompileSdk = androidExt.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                        setCompileSdk.invoke(androidExt, "android-36")
                    } catch (_: NoSuchMethodException) {
                        // ignore
                    }
                }

                // Inject a namespace for plugins that haven't migrated to AGP 8's namespace requirement.
                try {
                    val namespaceMethod = androidExt.javaClass.getMethod("getNamespace")
                    val currentNamespace = namespaceMethod.invoke(androidExt) as String?
                    if (currentNamespace == null) {
                        val setter = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                        setter.invoke(androidExt, project.group.toString())
                    }
                } catch (_: NoSuchMethodException) {
                    // android extension does not expose namespace getters/setters; ignore
                }

                // Force Java 17 on plugin subprojects to silence "source/target value 8
                // is obsolete" warnings emitted by plugins that still compile at Java 8.
                try {
                    val compileOptions =
                        androidExt.javaClass.getMethod("getCompileOptions").invoke(androidExt)
                    compileOptions.javaClass
                        .getMethod("setSourceCompatibility", Any::class.java)
                        .invoke(compileOptions, JavaVersion.VERSION_17)
                    compileOptions.javaClass
                        .getMethod("setTargetCompatibility", Any::class.java)
                        .invoke(compileOptions, JavaVersion.VERSION_17)
                } catch (_: Exception) {
                    // compileOptions not available on this extension; ignore
                }
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
