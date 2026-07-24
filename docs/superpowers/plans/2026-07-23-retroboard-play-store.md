# Retro Board — Rebranding e Publicação na Play Store — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Renomear o app soundboard para "Retro Board" (package `com.retroboard.leo`), configurar assinatura de release, publicar política de privacidade e submeter o `.aab` à Google Play Store.

**Architecture:** Mudanças concentradas na pasta `android/` (package ID, namespace, label, signing) e em `lib/l10n/` (título exibido). Política de privacidade servida por GitHub Pages num branch órfão `gh-pages`. As etapas de Play Console são manuais (checklist), pois dependem do console web.

**Tech Stack:** Flutter (Dart package name `soundboard` mantido), Gradle Kotlin DSL, `keytool` (JBR do Android Studio), GitHub Pages.

## Global Constraints

- Application ID / namespace final: **`com.retroboard.leo`** (imutável após 1º upload).
- Nome interno do pacote Dart (`pubspec.yaml` `name:`) permanece **`soundboard`** — imports `package:soundboard/` não mudam.
- Nome exibido ao usuário: **"Retro Board"**.
- `keytool`/`java` via JBR: `/opt/android-studio/jbr/bin/keytool`.
- `flutter`: `/usr/bin/flutter`.
- Segredos (`key.properties`, `*.jks`) NUNCA commitados — já cobertos por `android/.gitignore`.
- Keystore gerada = **upload key** (Google Play App Signing guarda a chave final).
- Repositório GitHub: `github.com/leonardoksn/soundboard`.
- Versão inicial: `1.0.0+1` (do `pubspec.yaml`).

---

## Mapa de arquivos

| Arquivo | Ação | Responsabilidade |
|---------|------|------------------|
| `android/app/build.gradle.kts` | Modificar | namespace, applicationId, signingConfigs.release |
| `android/app/src/main/kotlin/com/leonardo/soundboard/MainActivity.kt` | Mover + editar | novo package `com.retroboard.leo` |
| `android/app/src/main/AndroidManifest.xml` | Modificar | `android:label="Retro Board"` |
| `lib/l10n/app_pt.arb` + `app_en.arb` | Modificar | `appTitle` → "Retro Board" |
| `lib/l10n/app_localizations*.dart` | Regenerar | saída de `flutter gen-l10n` (commitada) |
| `pubspec.yaml` | Modificar | `description` real |
| `~/keystores/retroboard-upload.jks` | Criar (fora do repo) | upload key |
| `android/key.properties` | Criar (gitignored) | credenciais da keystore |
| `gh-pages:index.html` | Criar (branch órfão) | política de privacidade |

---

### Task 1: Rebranding — package ID, namespace, labels e título

**Files:**
- Modify: `android/app/build.gradle.kts:8` (namespace), `:19` (applicationId)
- Move: `android/app/src/main/kotlin/com/leonardo/soundboard/MainActivity.kt` → `android/app/src/main/kotlin/com/retroboard/leo/MainActivity.kt`
- Modify: `android/app/src/main/AndroidManifest.xml:5`
- Modify: `lib/l10n/app_pt.arb:3`, `lib/l10n/app_en.arb:3`
- Modify: `pubspec.yaml:2`
- Test: suíte existente em `test/`

**Interfaces:**
- Consumes: nada (primeira task)
- Produces: package `com.retroboard.leo` e nome "Retro Board" — a Task 2 assina esse applicationId; a Task 4 publica sob esse ID.

- [ ] **Step 1: Mover o diretório do MainActivity e ajustar o package**

```bash
cd /home/leo/projects/soundboard
mkdir -p android/app/src/main/kotlin/com/retroboard/leo
git mv android/app/src/main/kotlin/com/leonardo/soundboard/MainActivity.kt \
       android/app/src/main/kotlin/com/retroboard/leo/MainActivity.kt
# remover diretórios antigos agora vazios
rmdir android/app/src/main/kotlin/com/leonardo/soundboard \
      android/app/src/main/kotlin/com/leonardo 2>/dev/null || true
```

- [ ] **Step 2: Editar a linha `package` do MainActivity.kt**

Arquivo `android/app/src/main/kotlin/com/retroboard/leo/MainActivity.kt` deve ficar:

```kotlin
package com.retroboard.leo

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

- [ ] **Step 3: Editar namespace e applicationId no build.gradle.kts**

Em `android/app/build.gradle.kts`, linha 8:
```kotlin
    namespace = "com.retroboard.leo"
```
Linha 19 (remover também o comentário TODO da linha 18):
```kotlin
        applicationId = "com.retroboard.leo"
```

- [ ] **Step 4: Editar o label no AndroidManifest.xml**

Em `android/app/src/main/AndroidManifest.xml`, linha 5:
```xml
        android:label="Retro Board"
```

- [ ] **Step 5: Editar `appTitle` nos dois arquivos .arb**

`lib/l10n/app_pt.arb` linha 3 e `lib/l10n/app_en.arb` linha 3:
```json
  "appTitle": "Retro Board",
```

- [ ] **Step 6: Atualizar a description do pubspec.yaml**

`pubspec.yaml` linha 2:
```yaml
description: "Soundboard offline: importe áudios e toque com um toque."
```

- [ ] **Step 7: Regenerar as localizações**

```bash
cd /home/leo/projects/soundboard
flutter gen-l10n
```
Expected: gera/atualiza `lib/l10n/app_localizations_pt.dart` e `_en.dart` com `String get appTitle => 'Retro Board';`. Confirmar:
```bash
grep -n "appTitle =>" lib/l10n/app_localizations_pt.dart lib/l10n/app_localizations_en.dart
```
Expected: ambos mostram `'Retro Board'`.

- [ ] **Step 8: Limpar build antigo (package trocou) e rodar análise + testes**

```bash
cd /home/leo/projects/soundboard
flutter clean
flutter pub get
flutter analyze
flutter test
```
Expected: `analyze` sem erros; todos os testes PASSAM (nenhum depende da string "Soundboard").

- [ ] **Step 9: Build debug para confirmar que o package novo compila**

```bash
flutter build apk --debug
grep -n 'applicationId' android/app/build.gradle.kts
```
Expected: build conclui sem erro (package Kotlin errado faria falhar); grep mostra `com.retroboard.leo`.

- [ ] **Step 10: Commit**

```bash
git add android/app/build.gradle.kts \
        android/app/src/main/kotlin \
        android/app/src/main/AndroidManifest.xml \
        lib/l10n/app_pt.arb lib/l10n/app_en.arb \
        lib/l10n/app_localizations_pt.dart lib/l10n/app_localizations_en.dart \
        pubspec.yaml
git commit -m "feat: rebrand para Retro Board (com.retroboard.leo)"
```

---

### Task 2: Keystore de release e signing config

**Files:**
- Create: `~/keystores/retroboard-upload.jks` (fora do repo)
- Create: `android/key.properties` (gitignored)
- Modify: `android/app/build.gradle.kts` (bloco de signing)
- Test: `flutter build appbundle --release`

**Interfaces:**
- Consumes: applicationId `com.retroboard.leo` da Task 1
- Produces: `.aab` assinado em `build/app/outputs/bundle/release/app-release.aab` — consumido pela Task 4.

- [ ] **Step 1: Gerar a upload key**

```bash
mkdir -p ~/keystores
/opt/android-studio/jbr/bin/keytool -genkey -v \
  -keystore ~/keystores/retroboard-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias retroboard
```
Expected: `keytool` pede senha do keystore, senha da key e dados do dname (nome, organização, país BR). Guardar as senhas — serão usadas no Step 2 e no backup.

- [ ] **Step 2: Criar android/key.properties**

Criar `android/key.properties` (substituir `SENHA_...` pelas senhas do Step 1):
```properties
storePassword=SENHA_DO_KEYSTORE
keyPassword=SENHA_DA_KEY
keyAlias=retroboard
storeFile=/home/leo/keystores/retroboard-upload.jks
```

- [ ] **Step 3: Confirmar que key.properties NÃO será commitado**

```bash
cd /home/leo/projects/soundboard
git status --porcelain android/key.properties
git check-ignore android/key.properties
```
Expected: `git status` não lista o arquivo; `git check-ignore` imprime `android/key.properties` (confirmando que está ignorado).

- [ ] **Step 4: Adicionar carregamento da keystore no topo do build.gradle.kts**

Em `android/app/build.gradle.kts`, logo após o bloco `plugins { ... }` (antes de `android {`), inserir:
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```
Nota: `rootProject.file("key.properties")` resolve para `android/key.properties`.

- [ ] **Step 5: Adicionar signingConfigs e usar no release**

Em `android/app/build.gradle.kts`, dentro do bloco `android { ... }`, adicionar o bloco `signingConfigs` **antes** de `buildTypes` e trocar o `release`:
```kotlin
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
```
(Remover o `buildTypes { release { ... debug ... } }` antigo e o comentário TODO.)

- [ ] **Step 6: Build do app bundle assinado**

```bash
cd /home/leo/projects/soundboard
flutter build appbundle --release
```
Expected: conclui gerando `build/app/outputs/bundle/release/app-release.aab` (sem o aviso de "signing with debug keys").

- [ ] **Step 7: Verificar a assinatura**

```bash
/opt/android-studio/jbr/bin/keytool -list -v \
  -keystore ~/keystores/retroboard-upload.jks -alias retroboard | head -5
ls -lh build/app/outputs/bundle/release/app-release.aab
```
Expected: keytool lista o certificado do alias `retroboard`; o `.aab` existe.

- [ ] **Step 8: Commit (só o build.gradle.kts — segredos ficam de fora)**

```bash
git add android/app/build.gradle.kts
git status --porcelain   # confirmar que key.properties e .jks NÃO aparecem
git commit -m "config: assinar release com upload key (Play App Signing)"
```

- [ ] **Step 9: Backup da keystore (recomendado)**

Copiar `~/keystores/retroboard-upload.jks` e as senhas para um gerenciador de senhas ou storage cifrado. Sob Play App Signing a perda da upload key é recuperável via reset com o Google, mas o backup evita esse transtorno.

---

### Task 3: Política de privacidade via GitHub Pages

**Files:**
- Create: `index.html` no branch órfão `gh-pages`

**Interfaces:**
- Consumes: nada
- Produces: URL pública `https://leonardoksn.github.io/soundboard/` — usada na ficha do Play Console (Task 4).

Nota: usamos um branch órfão `gh-pages` (não a pasta `/docs`) para não publicar os specs/plans internos.

- [ ] **Step 1: Criar branch órfão gh-pages com a página**

```bash
cd /home/leo/projects/soundboard
git checkout --orphan gh-pages
git rm -rf . >/dev/null 2>&1 || true
```

- [ ] **Step 2: Escrever index.html**

Criar `index.html`:
```html
<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Política de Privacidade — Retro Board</title>
</head>
<body>
  <h1>Política de Privacidade — Retro Board</h1>
  <p>Última atualização: 23 de julho de 2026.</p>

  <h2>Coleta de dados</h2>
  <p>O Retro Board <strong>não coleta, não armazena em servidores e não
  compartilha</strong> nenhum dado pessoal. O aplicativo funciona totalmente
  offline.</p>

  <h2>Microfone</h2>
  <p>O app solicita permissão de microfone apenas para a função de gravar
  sons, acionada explicitamente por você. As gravações ficam salvas somente
  no armazenamento do seu próprio dispositivo e nunca são enviadas para fora
  dele.</p>

  <h2>Terceiros</h2>
  <p>O app não usa serviços de análise, publicidade ou rastreamento de
  terceiros.</p>

  <h2>Contato</h2>
  <p>Dúvidas sobre esta política: leodev.ksn@gmail.com</p>
</body>
</html>
```

- [ ] **Step 3: Commit e push do branch gh-pages**

```bash
git add index.html
git commit -m "docs: página de política de privacidade (GitHub Pages)"
git push -u origin gh-pages
```

- [ ] **Step 4: Habilitar GitHub Pages e voltar para main**

Ações manuais/CLI:
```bash
# habilitar Pages servindo do branch gh-pages (raiz) via API do gh:
gh api -X POST repos/leonardoksn/soundboard/pages \
  -f "source[branch]=gh-pages" -f "source[path]=/" 2>/dev/null || \
  echo "Se falhar, habilitar manualmente em Settings > Pages > Branch: gh-pages / root"
git checkout main
```

- [ ] **Step 5: Verificar a URL no ar**

Aguardar ~1 min e testar:
```bash
curl -s -o /dev/null -w "%{http_code}\n" https://leonardoksn.github.io/soundboard/
```
Expected: `200`. Anotar a URL para a Task 4.

---

### Task 4 (MANUAL): Ficha da Play Store, Data Safety e submissão

Esta task é executada no **Google Play Console** (web) — não há build/test automatizável. Cada item é um checkbox de verificação.

**Consumes:** `.aab` da Task 2, URL de privacidade da Task 3.

- [ ] **Step 1: Criar o app no Play Console**
  - Play Console → "Criar app" → nome **Retro Board**, idioma padrão PT-BR, tipo "App", gratuito.

- [ ] **Step 2: Capturar screenshots**
  - Rodar `flutter run --release` num device/emulador, capturar ≥2 screenshots de celular (mín. exigido pela loja). Adicionar sons de exemplo antes para a tela não ficar vazia.

- [ ] **Step 3: Preencher a ficha da loja (Store listing)**
  - Descrição curta (≤80 chars): ex. "Soundboard offline: seus áudios, um toque para tocar."
  - Descrição completa: funcionalidades (importar áudios, grade de botões, gravar pelo microfone, cores, reordenar, offline).
  - Ícone 512×512 e feature graphic 1024×500 (gerar a partir do ícone atual).
  - Categoria: "Música e áudio" (ou "Ferramentas").

- [ ] **Step 4: Política de privacidade**
  - Colar a URL `https://leonardoksn.github.io/soundboard/` no campo de política de privacidade.

- [ ] **Step 5: Data Safety**
  - Declarar: **não coleta nem compartilha dados**.
  - Justificar `RECORD_AUDIO`: gravação de sons feita pelo próprio usuário, armazenada só no dispositivo.

- [ ] **Step 6: Classificação de conteúdo**
  - Responder o questionário (app utilitário, sem conteúdo sensível) → deve resultar em classificação livre.

- [ ] **Step 7: Criar release de teste interno e enrollar no Play App Signing**
  - Testing → Internal testing → Create release.
  - Aceitar o enrollment no **Play App Signing** quando solicitado (a upload key da Task 2 vira a chave de upload).
  - Fazer upload de `build/app/outputs/bundle/release/app-release.aab`.

- [ ] **Step 8: Revisar e enviar**
  - Resolver todos os avisos do painel "Dashboard".
  - Enviar a release de teste interno para revisão do Google.
  - Após aprovação e validação em teste interno, promover para produção quando quiser.

---

## Notas de execução

- Tasks 1–3 são automatizáveis (código/arquivos/git). Task 4 é manual (console web).
- Ordem obrigatória: Task 1 → Task 2 (assina o ID renomeado) → Task 3 (URL) → Task 4 (consome `.aab` + URL).
- A troca de `applicationId` é definitiva após o 1º upload — por isso ocorre antes de qualquer submissão.
