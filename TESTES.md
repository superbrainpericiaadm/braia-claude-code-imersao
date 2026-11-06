# Testes pós-instalação

> **Status: PROPOSTA** — aprovação didática final pendente.
> Nenhum dos cenários abaixo foi executado com conta autenticada.

Abra o Claude Code na pasta da Braia (`cd ~/Braia` e depois `claude`).

## Cenário 1 — A equipe está instalada (PROPOSTA)

**Passo:** digite

> Braia, quem é a sua equipe?

**Resultado esperado:** a Braia se apresenta e lista Isaura, Paulo, Juliana e
Angélica (ou só as três primeiras pessoas, se instalou com `--sem-angelica`).
Conferência extra: o comando `/agents` mostra `braia`, `isaura`, `paulo`,
`juliana` (e `angelica`) como agentes do projeto.

Execução autenticada: NÃO REALIZADA

## Cenário 2 — A Braia delega uma tarefa (PROPOSTA)

**Passo:** digite

> Braia, peça ao Paulo para criar um arquivo `teste-paulo.md` nesta pasta com
> uma checklist de 3 itens para organizar meus arquivos do computador.

**Resultado esperado:** a Braia aciona o subagente `paulo` (o Claude Code mostra
a chamada do agente), o arquivo `teste-paulo.md` aparece na pasta e a Braia
resume o que foi feito. O Claude Code pode pedir permissão para criar o
arquivo: aceite.

Execução autenticada: NÃO REALIZADA

---

**Nota (fora dos dois cenários) — conferência opcional do Google (Isaura):**
com os conectores Google ligados na conta Claude, peça "Braia, peça à Isaura
para listar meus compromissos de amanhã". A Isaura deve consultar a agenda pelo
conector ou, se ele não estiver ligado, explicar como conectar, sem inventar
compromissos. Não faz parte da validação dos dois cenários.
