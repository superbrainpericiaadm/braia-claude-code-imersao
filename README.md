# Braia para Claude Code (local)

A Braia é uma equipe de agentes que roda dentro do **Claude Code**, no seu
computador. Ela coordena quatro especialistas:

| Agente | Função |
|---|---|
| **Braia** | Coordenadora: recebe o pedido, aciona o especialista certo e entrega o resultado |
| **Isaura** | Secretária: e-mail, agenda, Google Drive e documentos |
| **Paulo** | Tecnologia: scripts, planilhas, automações e suporte técnico |
| **Juliana** | Operações: quebra demandas grandes em etapas e cria processos |
| **Angélica** | Pessoas (opcional): vagas, entrevistas, onboarding e feedback |

## O que é e o que não é

- **É** um conjunto de arquivos de texto (`.claude/agents/*.md` e
  `.claude/settings.json`) que o Claude Code lê numa pasta.
- **Não é** um programa, servidor, bot de WhatsApp/Telegram nem serviço na
  nuvem. Não roda sozinha: funciona enquanto o Claude Code estiver aberto na
  pasta. Desligou o computador, ela para.
- **Não** guarda senhas, **não** acessa nada sem o seu login e **não** envia
  e-mail ou cria evento sem a sua confirmação.

## Requisitos

1. **Conta Claude paga com Claude Code** (Pro, Max, Team ou Enterprise). O
   plano gratuito não inclui o Claude Code.
2. **Claude Code instalado** pelo instalador oficial
   ([documentação](https://code.claude.com/docs/en/setup)):
   - macOS/Linux: `curl -fsSL https://claude.ai/install.sh | bash`
   - Windows (PowerShell): `irm https://claude.ai/install.ps1 | iex`
   - Node.js só é necessário se você preferir instalar pelo npm.
3. **Google (opcional, para a Isaura):** conecte Gmail, Google Calendar e
   Google Drive nos **conectores da sua conta Claude**
   (claude.ai > Configurações > Conectores). Com o Claude Code logado na mesma
   conta, eles aparecem no comando `/mcp`. Não há chave nem configuração extra
   neste pacote.

## Instalar

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/superbrainpericiaadm/braia-claude-code-imersao/main/install.sh | bash
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/superbrainpericiaadm/braia-claude-code-imersao/main/install.ps1 | iex
```

O instalador cria a pasta `Braia` na sua pasta pessoal e copia os agentes.
Pode rodar de novo sem problema: arquivos iguais não são tocados e, se algum
mudou, a versão anterior vai para `Braia/.braia-backup/<data>`.

Opções (a partir de um clone ou download do repositório):

```bash
bash install.sh ~/OutraPasta     # outra pasta
bash install.sh --sem-angelica   # sem a Angélica
```

```powershell
.\install.ps1 -Destino C:\OutraPasta
.\install.ps1 -SemAngelica
```

## Usar

```bash
cd ~/Braia
claude
```

Na primeira vez, o Claude Code pergunta se você confia na pasta: responda que
sim (é isso que permite carregar a configuração da Braia). Depois escreva:

> Braia, quem é a sua equipe?

Veja os testes de conferência em [TESTES.md](TESTES.md).

## Desinstalar

```bash
bash install.sh --desinstalar      # macOS/Linux
```

```powershell
.\install.ps1 -Desinstalar         # Windows
```

Isso move apenas os arquivos da Braia para `Braia/.braia-backup/<data>`.
Seus documentos na pasta ficam intactos. Para remover tudo, apague a pasta
`Braia` manualmente.

## Estrutura

```
install.sh / install.ps1     instaladores (só copiam arquivos)
braia/.claude/settings.json  faz a sessão começar como Braia ("agent": "braia")
braia/.claude/agents/        braia, isaura, paulo, juliana, angelica
```
