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

// Registered before the evaluationDependsOn(":app") block below, which evaluates :app
// eagerly — afterEvaluate cannot be attached to an already-evaluated project.

// Some plugins pin an old compileSdk (country_detector 1.0.2+1 uses 33), which trips AGP's
// AAR metadata check once their own AndroidX dependencies require 34+. Raise any plugin
// module that sits below the app's compileSdk instead of patching them one at a time.
subprojects {
    afterEvaluate {
        val library = extensions.findByType<com.android.build.gradle.LibraryExtension>()
        if (library != null && (library.compileSdk ?: 0) < 36) {
            library.compileSdk = 36
        }
    }
}

// sentry_flutter 8.14.2 hardcodes `languageVersion = "1.6"` in its android/build.gradle,
// which Kotlin 2.2+ rejects outright ("Language version 1.6 is no longer supported").
// It is the only plugin in the dependency set doing this, so raise just that module.
subprojects {
    if (name == "sentry_flutter") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
                apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_8)
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
