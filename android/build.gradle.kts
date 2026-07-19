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

    // Registrado ANTES do evaluationDependsOn abaixo, para que o afterEvaluate
    // possa ser agendado antes de os plugins serem avaliados. Força todos os
    // plugins Android a compilarem contra o compileSdk 36 (exigido por plugins
    // novos como flutter_plugin_android_lifecycle), sobrepondo o valor que o
    // build.gradle de cada plugin define (ex.: file_picker fixa 34).
    afterEvaluate {
        val ext = extensions.findByName("android")
        if (ext is com.android.build.gradle.BaseExtension) {
            ext.compileSdkVersion(36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
