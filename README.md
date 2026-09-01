# VoxeBlockS

Sandbox 3D de sobrevivência e criatividade em um mundo voxel, com visual cartoon e base preparada para multiplayer. O projeto usa **Godot 4.7.2 stable** e começa com um vertical slice pequeno, jogável e verificável antes de receber sistemas maiores.

## Estado atual — protótipo 0.3

- Terreno procedural determinístico por `world_seed`.
- Armazenamento compacto por chunk em `PackedByteArray` (16×32×16).
- Chunks carregados, descarregados e ocultados conforme a distância do jogador.
- Fila de streaming com no máximo um carregamento por frame.
- Dirty chunks para agrupar reconstruções e atualizar somente vizinhos em bordas.
- Uma mesh combinada por chunk, faces internas removidas e colisão por chunk.
- IDs numéricos de blocos (`AIR`, `GRASS`, `DIRT`, `STONE`, `WOOD`, `LEAF`).
- Árvores determinísticas que continuam corretas mesmo atravessando fronteiras de chunks.
- Primeira pessoa e terceira pessoa com `SpringArm3D` contra clipping em paredes.
- InputMap para teclado; controles touch responsivos com movimento, olhar, pulo, câmera e ações.
- Modo Sobrevivência/Criativo como estado separado.
- APK Android assinado no CI e validação headless local do projeto.

## Arquitetura

```text
main.gd
├── world_manager.gd
│   ├── chunk_data.gd
│   ├── terrain_generator.gd
│   └── chunk.gd
├── player.gd
├── world_interaction.gd
├── hud.gd
├── game_mode.gd
└── input_actions.gd
```

O `WorldManager` é a autoridade do estado do mundo. `ChunkData` conhece apenas os blocos do próprio chunk; modificações do jogador ficam separadas da geração procedural em `modified_blocks`, permitindo save/load incremental no futuro.

## Rodar localmente

Abra a pasta na Godot **4.7.2 stable** e execute a cena principal. Os controles são:

- `WASD` ou setas: mover
- `Espaço`: pular
- `V`: alternar câmera
- `M`: alternar modo
- `F`: quebrar bloco
- `G`: colocar bloco
- `Esc`: liberar o mouse; clique para capturá-lo novamente

## Testes locais

```bash
godot --headless --path . --script tests/world_coords_test.gd
godot --headless --path . --quit-after 8
```

O teste de coordenadas cobre fronteiras positivas e negativas, incluindo `-1`, `-8`, `-9`, `15` e `16`.

## APK automático

Cada push na branch `main` executa `.github/workflows/build-android.yml`. O APK assinado aparece no artefato `VoxeBlockS-Android-debug`. O workflow também valida que o arquivo foi exportado antes de anexá-lo.

A assinatura atual é de desenvolvimento gerada no CI. Antes de uma distribuição pública, será configurada uma keystore de release persistente nos Secrets do GitHub para que atualizações possam ser instaladas sem desinstalar a versão anterior.

## Próximos marcos

1. Persistência de `world_seed` e `modified_blocks`.
2. Atlas de texturas e catálogo de blocos orientado a dados.
3. Inventário, crafting, ferramentas e drops.
4. Criaturas, combate e progressão de sobrevivência.
5. Abstração de sessão multiplayer e sincronização de chunks.
6. APK release assinado com keystore persistente e testes em dispositivo.

## Referências

- [Exportação Android na documentação da Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [Geometria procedural com ArrayMesh](https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/arraymesh.html)
- [Otimização de desempenho 3D](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
