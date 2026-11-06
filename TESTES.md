# Testes pós-instalação

> **Status: PROPOSTO** — aguardando validação interna antes da imersão.

Abra o Claude Code na pasta da Braia (`cd ~/Braia` e depois `claude`).

## Teste 1 — A equipe está instalada

Digite:

> Braia, quem é a sua equipe?

**Esperado:** a Braia se apresenta e lista Isaura, Paulo, Juliana e Angélica
(ou só os três primeiros, se instalou com `--sem-angelica`).

Conferência extra: o comando `/agents` mostra `braia`, `isaura`, `paulo`,
`juliana` (e `angelica`) como agentes do projeto.

## Teste 2 — A Braia delega uma tarefa

Digite:

> Braia, peça ao Paulo para criar um arquivo `teste-paulo.md` nesta pasta com
> uma checklist de 3 itens para organizar meus arquivos do computador.

**Esperado:** a Braia aciona o subagente `paulo` (o Claude Code mostra a
chamada do agente), o arquivo `teste-paulo.md` aparece na pasta e a Braia
resume o que foi feito. O Claude Code pode pedir permissão para criar o
arquivo: aceite.

## Opcional — Google (Isaura)

Com os conectores Google ligados na conta Claude:

> Braia, peça à Isaura para listar meus compromissos de amanhã.

**Esperado:** a Isaura consulta a agenda pelo conector. Se o conector não
estiver ligado, ela explica como conectar, sem inventar compromissos.
