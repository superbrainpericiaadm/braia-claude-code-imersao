# Braia para Claude Code (agente do seu Claude)

A Braia é uma coordenadora de equipe que **vira um agente do seu Claude Code**:
você digita `/braia`, conversa com ela e ela despacha o trabalho para a equipe.
Instala em `~/.claude` (nível de usuário), então funciona em **qualquer pasta**.

| Agente | Função |
|---|---|
| **Braia** (`/braia`) | Coordenadora: recebe o pedido e aciona o especialista certo |
| **Isaura** | Secretária: e-mail, agenda, Google Drive e documentos |
| **Paulo** | Tecnologia: scripts, planilhas, automações e suporte técnico |
| **Juliana** | Operações: quebra demandas grandes em etapas e cria processos |
| **Angélica** | Pessoas (opcional): vagas, entrevistas, onboarding e feedback |

## Requisitos

1. Claude Code instalado ([documentação](https://code.claude.com/docs/en/setup)) e logado na sua conta.
   - macOS/Linux: `curl -fsSL https://claude.ai/install.sh | bash`
   - Windows (PowerShell): `irm https://claude.ai/install.ps1 | iex`

## Instalar (um comando)

macOS / Linux:

```
curl -fsSL https://github.com/superbrainpericiaadm/braia-claude-code-imersao/releases/download/v1.1.0-agente-imersao-19-11/install.sh | bash
```

Windows (PowerShell):

```
irm https://github.com/superbrainpericiaadm/braia-claude-code-imersao/releases/download/v1.1.0-agente-imersao-19-11/install.ps1 | iex
```

O instalador usa a **versão fixada** (`v1.1.0-agente-imersao-19-11`), baixa o pacote e **confere o SHA256
antes de extrair** (se não bater, para e não instala nada). Não usa sudo/administrador,
não mexe no PATH, não envia dados. Reexecutar é seguro: arquivos iguais ficam como
estão; um arquivo seu com o mesmo nome vai para `~/.claude/.braia-backup/` antes de
ser substituído; seus outros agentes e comandos não são tocados.

Instala 6 arquivos: `~/.claude/commands/braia.md` e `~/.claude/agents/{braia,isaura,paulo,juliana,angelica}.md`.
Opções (baixando o `install.sh`): `--sem-angelica`, `--desinstalar`, pasta de destino como argumento.

## Usar

1. Abra o Claude Code em qualquer pasta (`claude`; se já estava aberto, feche e abra).
2. Digite `/braia` e o pedido, ex.: `/braia quem é a sua equipe?`
3. Peça trabalho: `/braia peça ao Paulo uma planilha de controle de despesas`.
4. Google: veja abaixo.
5. A Braia sempre pede o seu "sim" antes de enviar e-mail, criar evento ou mexer no Drive.

## Google (Gmail, Agenda e Drive) para a Isaura

Os conectores Google do Claude **não são instaláveis por script**: só você autoriza,
no navegador. A documentação oficial do Claude Code
([MCP > Use MCP servers from claude.ai](https://code.claude.com/docs/en/mcp#use-mcp-servers-from-claude-ai))
diz que, logado com conta claude.ai, os conectores que você adicionou no claude.ai
aparecem automaticamente no Claude Code, e que Gmail e Google Calendar **não
suportam OAuth local** (`claude mcp add` não serve para eles). Então:

1. Abra https://claude.ai/customize/connectors e conecte **Gmail**, **Google Calendar** e **Google Drive**.
2. No Claude Code, esteja logado com a mesma conta (`/status`; `/login` se preciso). Conta por chave de API não carrega conectores.
3. Digite `/mcp`: os conectores aparecem marcados como do claude.ai. Se faltar algum, reabra o Claude Code.
4. Teste: `/braia peça à Isaura para listar meus compromissos de amanhã`.

A Isaura herda todas as ferramentas da sessão (inclusive as `mcp__...` dos conectores):
a ficha dela não fixa nomes de ferramenta porque o nome depende do conector na sua conta.
A própria Braia dá esse passo a passo se o Google não estiver conectado.

## O que é e o que não é

Só arquivos de texto (Markdown) lidos pelo Claude Code. Não é programa, servidor nem
bot. Não guarda senhas e não acessa nada além do que você conectar.

## Sem internet pelo comando / conferir o pacote

Baixe `install.sh` (ou `install.ps1`) e o pacote da
[release](https://github.com/superbrainpericiaadm/braia-claude-code-imersao/releases/tag/v1.1.0-agente-imersao-19-11),
confira com `SHA256SUMS` e rode. SHA256 desta versão:

```
3ce8b7ad18a88c1eb60caf72aac734681a0e89fe3d001d7de109ccb773fb959e  braia-v1.1.0-agente-imersao-19-11.tar.gz
7cf6cb875b04028d9a977462b4858617db74bdc111deb5e8b33a7664cf685d3f  braia-v1.1.0-agente-imersao-19-11.zip
7403851d676d1de962c1c651e42f4869a12e67eb323541dc4c8314f094631809  install.sh
c1e5461048600fd1d573607184e7df9865763c75302619358953c5a26a1f0e9c  install.ps1
```

## Desinstalar

`bash install.sh --desinstalar` (Windows: `.\install.ps1 -Desinstalar`): os 6 arquivos vão para o backup.
