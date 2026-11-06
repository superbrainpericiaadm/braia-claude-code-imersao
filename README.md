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

1. **Acesso ao Claude Code compatível — a confirmar na documentação oficial**
   (assinatura ou API são modalidades possíveis; não decidido em reunião).
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

> **RASCUNHO BLOQUEADO — não divulgar aos alunos.** O repositório
> `superbrainpericiaadm/braia-claude-code-imersao` é **privado**: os comandos
> abaixo retornam **404** fora da conta dona. Não há liberação aos alunos
> (gate G8). Os comandos ficam aqui só como rascunho do formato final.

macOS / Linux (RASCUNHO BLOQUEADO):

```bash
curl -fsSL https://raw.githubusercontent.com/superbrainpericiaadm/braia-claude-code-imersao/main/install.sh | bash
```

Windows (PowerShell) (RASCUNHO BLOQUEADO):

```powershell
irm https://raw.githubusercontent.com/superbrainpericiaadm/braia-claude-code-imersao/main/install.ps1 | iex
```

O instalador cria a pasta `Braia` na sua pasta pessoal e copia os agentes.
Pode rodar de novo sem problema: arquivos iguais não são tocados e, se algum
mudou, a versão anterior vai para `Braia/.braia-backup/<data>-<pid>`.

Opções (a partir de um clone ou download do repositório):

```bash
bash install.sh ~/OutraPasta     # outra pasta
bash install.sh --sem-angelica   # sem a Angélica
```

```powershell
.\install.ps1 -Destino C:\OutraPasta
.\install.ps1 -SemAngelica
```

No Windows, rodar o arquivo `.\install.ps1` baixado pode ser bloqueado pela
política de execução (ExecutionPolicy). Nesse caso, libere só para esta
execução, sem mudar a configuração do computador:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
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

Isso move apenas os arquivos da Braia para `Braia/.braia-backup/<data>-<pid>`.
Seus documentos na pasta ficam intactos. Para remover tudo, apague a pasta
`Braia` manualmente.

## Recuperação / restaurar backup

O instalador nunca apaga: todo arquivo da Braia que ele substitui ou remove vai
para uma pasta de backup dentro da própria pasta da Braia.

1. **Onde fica:** `Braia/.braia-backup/<data>-<pid>/`, por exemplo
   `~/Braia/.braia-backup/20261106-191500-12345/.claude/agents/paulo.md`.
   `<data>` é ano-mês-dia-hora-minuto-segundo e `<pid>` é o número do processo
   do instalador; cada execução cria a sua pasta. A mais recente é a última da
   lista:

   ```bash
   ls ~/Braia/.braia-backup/
   ```

   ```powershell
   Get-ChildItem $HOME\Braia\.braia-backup | Sort-Object Name
   ```

2. **Restaurar um arquivo** (ex.: a sua versão antiga do `paulo.md`):

   ```bash
   cd ~/Braia
   cp .braia-backup/<data>-<pid>/.claude/agents/paulo.md .claude/agents/paulo.md
   ```

   ```powershell
   cd $HOME\Braia
   Copy-Item .braia-backup\<data>-<pid>\.claude\agents\paulo.md .claude\agents\paulo.md
   ```

3. **Restaurar tudo de um backup** (copia por cima todos os arquivos daquele
   backup, mantendo a estrutura de pastas):

   ```bash
   cd ~/Braia
   cp -R .braia-backup/<data>-<pid>/.claude/. .claude/
   ```

   ```powershell
   cd $HOME\Braia
   Copy-Item -Recurse -Force .braia-backup\<data>-<pid>\.claude\* .claude\
   ```

4. **Reinstalar a versão original da Braia:** rode o instalador de novo
   (`bash install.sh` ou `.\install.ps1`, a partir da pasta do pacote). Os
   arquivos alterados voltam ao original e a versão alterada vai para um
   backup novo.

Os backups não são apagados automaticamente. Depois de conferir, você pode
apagar a pasta `.braia-backup` manualmente.

## Estrutura

```
install.sh / install.ps1     instaladores (só copiam arquivos)
braia/.claude/settings.json  faz a sessão começar como Braia ("agent": "braia")
braia/.claude/agents/        braia, isaura, paulo, juliana, angelica
```
