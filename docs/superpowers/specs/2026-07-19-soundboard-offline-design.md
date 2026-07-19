# Soundboard Offline — Documento de Design

- **Data:** 2026-07-19
- **Autor:** Leonardo (com Claude Code)
- **Projeto:** `soundboard` (applicationId `com.leonardo.soundboard`)
- **Status:** aprovado (design), aguardando plano de implementação

## 1. Objetivo

Aplicativo mobile (Android) de **soundboard 100% offline**, inspirado no
myinstants.com. O usuário importa seus próprios arquivos de áudio do
celular; cada áudio vira um botão numa grade; tocar no botão reproduz o
som. Não há dependência de internet nem catálogo remoto — tudo é local.

## 2. Escopo (decisões confirmadas)

| Tema | Decisão |
|------|---------|
| Origem dos sons | Usuário **importa** os próprios arquivos (app começa vazio) |
| Organização | **Grade única** de botões (uma tela) |
| Reprodução | **Um som por vez** — acionar um novo **interrompe** o anterior |
| Ações por botão | Nomear/renomear, excluir, cor personalizada, reordenar (arrastar) |
| Edição | **Ícone visível** de edição em cada botão (não toque longo) |
| Plataforma-alvo | Android (testar em aparelho físico) |

### Fora de escopo (não fazer agora — YAGNI)

- Sons embutidos no app (bundle) — versão futura.
- Categorias/abas/pastas — grade única basta.
- Sobreposição de áudios / botão "parar tudo".
- Sincronização em nuvem, backup, compartilhamento.
- Suporte a iOS/web/desktop (o código Flutter permite depois, mas não é meta).

## 3. Stack técnica

| Peça | Pacote | Papel | Paralelo React/TS |
|------|--------|-------|-------------------|
| Estado | `flutter_riverpod` | store reativo, injeção de dependência | Zustand/Context + actions |
| Banco | `sqflite` (SQL na mão) | metadados dos sons | SQLite/ORM |
| Áudio | `audioplayers` | reproduzir arquivo local | HTMLAudioElement |
| Importar | `file_picker` | escolher arquivo de áudio | `<input type=file>` |
| Pasta do app | `path_provider` | achar diretório privado | — |
| Reordenar | `reorderable_grid_view` | drag & drop na grade | react-dnd |
| IDs | `uuid` | nome único de arquivo | uuid |

## 4. Arquitetura

Três camadas, cada uma com responsabilidade única e testável isoladamente:

```
UI (telas/widgets)  ──lê/dispara──▶  Estado (Riverpod)  ──chama──▶  Dados (SQLite + arquivos)
      ▲                                    │
      └────────── reconstrói ◀─────────────┘
```

- **Dados:** banco SQLite (metadados) + armazenamento de arquivos de áudio.
  A UI nunca fala SQL nem mexe em arquivos diretamente.
- **Estado (Riverpod):** mantém a lista de sons em memória, expõe ações e o
  controlador de áudio.
- **UI:** apenas desenha e dispara ações.

### Estrutura de pastas proposta (`lib/`)

```
lib/
├── main.dart                      # bootstrap + ProviderScope + MaterialApp
├── models/
│   └── sound.dart                 # modelo Sound (imutável) + toMap/fromMap
├── data/
│   ├── database.dart              # abre/gerencia o SQLite (tabela sounds)
│   ├── sound_repository.dart      # CRUD + reorder (usa database + file storage)
│   └── sound_file_storage.dart    # copia/apaga arquivos na pasta do app
├── state/
│   ├── providers.dart             # providers Riverpod (repo, sounds, audio)
│   ├── sounds_notifier.dart       # AsyncNotifier<List<Sound>> + ações
│   └── audio_controller.dart      # wrapper do audioplayers (play/stop)
└── ui/
    ├── soundboard_screen.dart     # tela principal (grade + FAB)
    ├── sound_button.dart          # widget de um botão (play + ícone editar)
    └── add_edit_sound_sheet.dart  # bottom sheet: importar/editar (nome+cor+excluir)
```

## 5. Modelo de dados

### Modelo `Sound` (Dart, imutável)

```
Sound {
  int? id;          // null antes de inserir
  String name;      // rótulo do botão
  String filePath;  // caminho absoluto do arquivo copiado
  int color;        // valor ARGB da cor do botão
  int position;     // ordem na grade (0..n)
}
```

Métodos `toMap()` / `fromMap()` para (de)serializar no SQLite; `copyWith()`
para updates imutáveis.

### Tabela SQLite `sounds`

```sql
CREATE TABLE sounds (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  name      TEXT    NOT NULL,
  file_path TEXT    NOT NULL,
  color     INTEGER NOT NULL,
  position  INTEGER NOT NULL
);
```

Consultas ordenadas por `position ASC`.

### Arquivos de áudio

- Ao importar, o arquivo é **copiado** para
  `<app_documents>/sounds/<uuid>.<ext>` (via `path_provider`).
- O banco guarda apenas `file_path`. Assim o som sobrevive se o original for
  movido/apagado do celular.
- Ao excluir um som, o arquivo copiado também é apagado.

## 6. Estado com Riverpod

- **`soundRepositoryProvider`** — expõe o `SoundRepository` (banco + storage).
  Injeção de dependência: facilita trocar por fake nos testes.
- **`soundsProvider`** (`AsyncNotifier<List<Sound>>`) — carrega os sons do
  banco na inicialização e mantém a lista. Ações:
  - `add(file, name, color)` — copia arquivo, insere no banco, atualiza estado.
  - `rename(id, name)`
  - `changeColor(id, color)`
  - `remove(id)` — apaga do banco e o arquivo.
  - `reorder(oldIndex, newIndex)` — recalcula `position` de todos e persiste.
- **`audioControllerProvider`** — encapsula `audioplayers`. `play(path)` chama
  `stop()` no player antes de tocar o novo (comportamento "interrompe e toca").
  Libera recursos no dispose.

## 7. Interação na UI

- **Tocar:** toque simples no corpo do `SoundButton`.
- **Editar/Excluir:** cada botão exibe um **ícone de edição** (lápis) num canto,
  sempre visível. Toque nele abre o `AddEditSoundSheet` com renomear, trocar cor
  e um botão **Excluir** (com confirmação).
- **Reordenar:** pressionar-e-arrastar o botão na grade (gesto padrão do
  `reorderable_grid_view`).
- **Importar:** FAB `+` abre o `AddEditSoundSheet` em modo "novo".

## 8. Fluxos principais

- **Importar:** FAB `+` → `file_picker` (filtro áudio) → copia arquivo →
  `soundsProvider.add()` → grade reconstrói com o novo botão.
- **Tocar:** toque no `SoundButton` → `audioController.play(sound.filePath)`.
- **Editar:** ícone de edição → sheet → renomear / trocar cor.
- **Excluir:** ícone de edição → sheet → botão Excluir (confirmação) → apaga
  registro e arquivo.
- **Reordenar:** arrastar botão na grade → `soundsProvider.reorder()`.

## 9. Tratamento de erros

| Situação | Comportamento |
|----------|---------------|
| Import cancelado pelo usuário | Nada acontece |
| Arquivo inválido / falha ao copiar | Snackbar "não foi possível importar" |
| Falha ao reproduzir (arquivo corrompido) | Snackbar "não foi possível tocar" |
| Arquivo referenciado não existe mais | Botão marcado como indisponível (visual) e não toca |
| Banco indisponível na inicialização | Estado de erro na tela com opção de tentar de novo |

## 10. Estratégia de testes

- **Unitário — `SoundRepository`:** CRUD + reorder usando SQLite em memória
  (`sqflite_common_ffi`) e um `SoundFileStorage` fake.
- **Unitário — `AudioController`:** com player fake, garantir que `stop()` é
  chamado antes de `play()`.
- **Unitário — `SoundsNotifier`:** ações refletem no estado corretamente.
- **Widget — `SoundboardScreen`:** grade renderiza botões; toque no corpo
  dispara play; toque no ícone de edição abre o sheet; FAB abre o sheet em modo
  novo.

## 11. Critérios de sucesso (MVP)

1. Importar um MP3/WAV do celular cria um botão persistente.
2. Tocar no botão reproduz o áudio; tocar outro interrompe o anterior.
3. Renomear, trocar cor e excluir funcionam e persistem após fechar o app.
4. Reordenar por arrastar persiste a nova ordem.
5. App abre sem internet e mantém todos os sons entre execuções.
6. Roda no aparelho físico Android (Galaxy S23).
