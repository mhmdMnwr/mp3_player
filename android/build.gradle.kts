import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
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
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            if (project.name == "flutter_media_metadata") {
                namespace = "com.alexmercerind.flutter_media_metadata"
                compileSdk = 34

                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    manifestFile.writeText(
                        """
                        <manifest xmlns:android="http://schemas.android.com/apk/res/android" />
                        """.trimIndent(),
                    )
                }
            } else if (namespace == null) {
                namespace = "fix.namespace.${project.name.replace('-', '_')}"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
