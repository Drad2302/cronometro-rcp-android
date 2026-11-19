#!/usr/bin/env bash
set -e

ARQUIVO_ORIGINAL="cronometro-rcp-android-kotlin-compose.txt"

if [ ! -f "$ARQUIVO_ORIGINAL" ]; then
  echo "Arquivo original não encontrado: $ARQUIVO_ORIGINAL"
  exit 1
fi

mkdir -p app/src/main/java/br/com/cronometrorcp
mkdir -p app/src/main/java/br/com/cronometrorcp/service
mkdir -p app/src/main/java/br/com/cronometrorcp/audio
mkdir -p app/src/main/java/br/com/cronometrorcp/data
mkdir -p app/src/main/java/br/com/cronometrorcp/model
mkdir -p app/src/main/java/br/com/cronometrorcp/ui
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/mipmap-anydpi-v26
mkdir -p gradle/wrapper
mkdir -p .github/scripts

python3 <<'PY'
from pathlib import Path
import re

source = Path("cronometro-rcp-android-kotlin-compose.txt").read_text(encoding="utf-8")
pattern = re.compile(r"={80}\s*\nFILE:\s*(.+?)\s*\n={80}\s*\n", re.IGNORECASE)
matches = list(pattern.finditer(source))

if not matches:
    raise SystemExit("Nenhum marcador de arquivo foi encontrado no arquivo original.")

for i, match in enumerate(matches):
    relative_path = match.group(1).strip()
    start = match.end()
    end = matches[i + 1].start() if i + 1 < len(matches) else len(source)
    content = source[start:end].strip() + "\n"
    path = Path(relative_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"Criado: {relative_path}")
PY

if [ ! -f "settings.gradle.kts" ]; then
cat > settings.gradle.kts <<'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "CronometroRCP"
include(":app")
EOF
fi

if [ ! -f "build.gradle.kts" ]; then
cat > build.gradle.kts <<'EOF'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.20" apply false
}
EOF
fi

if [ ! -f "gradle.properties" ]; then
cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
EOF
fi

if [ ! -f "gradle/wrapper/gradle-wrapper.properties" ]; then
cat > gradle/wrapper/gradle-wrapper.properties <<'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
fi

if [ ! -f "gradlew" ]; then
cat > gradlew <<'EOF'
#!/bin/sh
exec gradle "$@"
EOF
chmod +x gradlew
fi

if [ ! -f "app/build.gradle.kts" ]; then
cat > app/build.gradle.kts <<'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "br.com.cronometrorcp"
    compileSdk = 34

    defaultConfig {
        applicationId = "br.com.cronometrorcp"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
    }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.09.00"))
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.6")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.6")
    implementation("androidx.media:media:1.7.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
}
EOF
fi

if [ ! -f "app/src/main/res/values/strings.xml" ]; then
cat > app/src/main/res/values/strings.xml <<'EOF'
<resources>
    <string name="app_name">Cronômetro RCP com Áudio</string>
</resources>
EOF
fi

if [ ! -f "app/src/main/res/values/themes.xml" ]; then
cat > app/src/main/res/values/themes.xml <<'EOF'
<resources>
    <style name="Theme.CronometroRCP" parent="android:Theme.Material.Light.NoActionBar">
        <item name="android:statusBarColor">#101418</item>
        <item name="android:windowLightStatusBar">false</item>
    </style>
</resources>
EOF
fi

if [ ! -f "app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml" ]; then
cat > app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@color/ic_launcher_foreground" />
</adaptive-icon>
EOF
fi

if [ ! -f "app/src/main/res/values/colors.xml" ]; then
cat > app/src/main/res/values/colors.xml <<'EOF'
<resources>
    <color name="ic_launcher_background">#101418</color>
    <color name="ic_launcher_foreground">#FFFFFF</color>
</resources>
EOF
fi

if [ -f "app/src/main/AndroidManifest.xml" ]; then
  sed -i 's/@android:style\/Theme.Material.NoActionBar/@style\/Theme.CronometroRCP/g' app/src/main/AndroidManifest.xml
fi
python3 <<'PY'
from pathlib import Path

arquivo = Path("app/src/main/java/br/com/cronometrorcp/service/RcpForegroundService.kt")
texto = arquivo.read_text(encoding="utf-8")

antigo = "override fun onStop() = stopAndSaveSession()"
novo = """override fun onStop() {
        stopAndSaveSession()
    }"""

if antigo in texto:
    texto = texto.replace(antigo, novo)
    arquivo.write_text(texto, encoding="utf-8")
    print("Correção do onStop aplicada.")
else:
    print("Aviso: padrão do onStop não encontrado.")
PY
echo "Projeto preparado com sucesso."
