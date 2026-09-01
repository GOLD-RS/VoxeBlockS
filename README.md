# VoxeBlockS

Sandbox 3D de sobrevivência e criatividade em um mundo de blocos, com visual cartoon. O projeto começa com um vertical slice jogável e uma base preparada para multiplayer no futuro.

## Estado atual — protótipo 0.1

- Mundo procedural local com terreno, grama, terra, pedra, árvores e folhas.
- Movimento em primeira pessoa e câmera em terceira pessoa.
- Controles de teclado e controles touch para Android.
- Quebrar e colocar blocos.
- Modos sobrevivência/criativo como base de design.
- Exportação automática de APK pelo GitHub Actions.

## Rodar localmente

Abra a pasta na Godot **4.7.2 stable** e execute a cena principal. O preset de exportação `Android` está em `export_presets.cfg`.

## APK automático

Cada push na branch `main` executa o workflow `.github/workflows/build-android.yml`. O APK de teste aparece como artefato da execução. Antes da publicação final, será configurada uma assinatura de release protegida por segredo do GitHub.

## Próximos marcos

1. Chunks e mesh combinada para escalar o mundo sem criar um nó por bloco.
2. Inventário, crafting e persistência do mundo.
3. Criaturas, combate, fome/vida e progressão.
4. Abstração de sessão multiplayer sem quebrar o single-player.
5. APK release assinado, testado e validado em dispositivo.

## Referências técnicas

- [Exportação Android na documentação da Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [Exportação por linha de comando](https://docs.godotengine.org/en/latest/tutorials/export/exporting_projects.html)
