# Retro Board — Rebranding e Publicação na Play Store — Documento de Design

- **Data:** 2026-07-23
- **Autor:** Leonardo (com Claude Code)
- **Projeto:** `soundboard` (novo nome exibido: **Retro Board**)
- **Status:** aprovado (design), aguardando plano de implementação

## 1. Objetivo

Preparar o app soundboard (já funcional, ver
[2026-07-19-soundboard-offline-design.md](2026-07-19-soundboard-offline-design.md))
para publicação na Google Play Store sob o nome **Retro Board**, cobrindo
rebranding, assinatura de release, política de privacidade e checklist de
submissão.

## 2. Escopo (decisões confirmadas)

| Tema | Decisão |
|------|---------|
| Nome exibido | **Retro Board** (nome interno do pacote Dart continua `soundboard`) |
| Application ID / namespace | `com.leonardo.soundboard` → **`com.retroboard.leo`** |
| Ícone | Mantém o atual (`assets/icon/legacy.png` + `foreground.png`) — sem retrabalho de arte agora |
| Conta Play Console | Já existe (Leonardo já é desenvolvedor registrado) |
| Keystore de release | Gerar agora, localmente, via `keytool` |
| Política de privacidade | Página estática, hospedada via **GitHub Pages** no repo `github.com/leonardoksn/soundboard` |
| Coleta de dados | Nenhuma — áudio gravado (permissão `RECORD_AUDIO`) fica só no dispositivo, não sai pra nenhum servidor |

### Fora de escopo (não fazer agora — YAGNI)

- Redesenho de ícone/arte para a marca Retro Board.
- iOS/App Store (só Android/Play Store por enquanto).
- CI/CD automatizado de release (build e assinatura feitos manualmente por ora).
- Localização da ficha da loja em múltiplos idiomas (só PT-BR/EN conforme o app já suporta).

## 3. Plano técnico por frente

### 3.1 Rebranding (package ID + nome exibido)

- `android/app/build.gradle.kts`: `namespace` e `applicationId` de
  `com.leonardo.soundboard` → `com.retroboard.leo`.
- Mover `android/app/src/main/kotlin/com/leonardo/soundboard/MainActivity.kt`
  → `android/app/src/main/kotlin/com/retroboard/leo/MainActivity.kt`,
  atualizando a linha `package` dentro do arquivo.
- `android/app/src/main/AndroidManifest.xml`: `android:label="soundboard"` →
  `android:label="Retro Board"`.
- `pubspec.yaml` (`name: soundboard`) permanece inalterado — é o nome do
  pacote Dart/repositório, não aparece pro usuário final.

### 3.2 Assinatura de release (keystore)

- Gerar keystore `.jks` local com `keytool` (validade longa, ex. 27+ anos).
- Criar `android/key.properties` (adicionado ao `.gitignore`, nunca commitado)
  com `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
- Configurar `signingConfigs.release` em `android/app/build.gradle.kts` para
  ler esse arquivo e assinar o `release` com a keystore real, em vez da
  debug key atual (`signingConfig = signingConfigs.getByName("debug")`).
- **Backup:** a keystore e as senhas precisam ser guardadas em local seguro
  fora do disco local (gerenciador de senhas ou storage cifrado). Perda =
  impossível publicar atualizações futuras do mesmo app.

### 3.3 Política de privacidade

- HTML estático simples, em português, cobrindo:
  - O app grava áudio localmente via microfone, só quando o usuário aciona
    a função de gravação.
  - Nenhum áudio ou dado é enviado a servidores externos — tudo fica no
    armazenamento do próprio dispositivo.
  - Sem coleta, venda ou compartilhamento de dados com terceiros.
- Publicado via GitHub Pages (branch `gh-pages` ou pasta `/docs` do repo
  `leonardoksn/soundboard`), gerando uma URL pública para preencher no
  Play Console.

### 3.4 Play Console — ficha e Data Safety

- **Data safety form:** declarar que o app não coleta nem compartilha
  dados; justificar o uso de `RECORD_AUDIO` (gravação de sons feita pelo
  próprio usuário, sem envio externo).
- Descrição curta e longa do app, categoria (candidatas: "Música e áudio"
  ou "Ferramentas").
- Classificação de conteúdo (questionário padrão do Play Console).
- Screenshots do app rodando (a serem capturados por Leonardo antes da
  submissão).

### 3.5 Build e submissão final

- `flutter build appbundle --release` gerando o `.aab` assinado com a
  keystore real.
- Instalar e testar o release build (`flutter install --release` ou
  `.apk` gerado localmente) num device físico antes de subir.
- Criar a release no Play Console (recomendado começar por **teste
  interno** ou **fechado**), subir o `.aab`, revisar avisos e enviar para
  revisão do Google.

## 4. Riscos

| Risco | Mitigação |
|-------|-----------|
| Perda da keystore de release | Backup imediato em gerenciador de senhas/storage cifrado, fora do repo e fora do disco local |
| Mudança de `applicationId` após a primeira publicação | Não é possível — por isso a troca é feita **agora**, antes do primeiro upload |
| Permissão de microfone sem política de privacidade | Página publicada via GitHub Pages antes da submissão, linkada no Play Console |
| Rejeição na revisão por dados incompletos na ficha | Preencher Data Safety e classificação de conteúdo com atenção antes de enviar |
