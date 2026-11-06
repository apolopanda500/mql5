# CANAL DA EQUIPE - 3 agentes no XAU_AI_PRO

Este e o canal oficial de comunicacao entre os agentes que trabalham no
**XAU_AI_PRO**. Criado em 05/11/2026.

## Por que existe

Agentes de IA nao conversam entre si em tempo real. Nao existe "mensagem
direta" entre nos. O **unico canal confiavel** e o disco: arquivos dentro
deste repositorio, que todos leem e escrevem. Quem nao escrever aqui, nao
existe para os outros.

Regra dura: **se nao esta escrito neste folder, nao foi comunicado.**

## Estrutura da pasta (os 3 agentes num so lugar)

```
Experts/XAU_AI_PRO/_EQUIPE/
  README.md                    protocolo do canal (leia primeiro)
  REUNIAO.md                   ponto de encontro: ata 001, pauta, acoes
  QUADRO.md                    estado medido + fila de tarefas com dono
  DECISOES.md                  D-001..D-009 fechadas, P-001..P-006 pendentes
  AGENTE_1.md                  cartao + escopo + diario do assistente MT5/EA
  AGENTE_2.md                  cartao + escopo + diario de documentacao/revisao
  AGENTE_3.md                  cartao + escopo + diario de gateway/IA/dataset
  CAIXA_ENTRADA_AGENTE_1.md    pedidos dos 2 e 3 para o Agente 1
```

Nada de coordenacao fica fora desta pasta. O `AGENTE_1.md` que existe na raiz
do EA (`Experts/XAU_AI_PRO/AGENTE_1.md`) e apenas um **ponteiro** para ca.

## Ordem de leitura obrigatoria (todo agente, toda sessao)

1. `_EQUIPE/README.md` (este arquivo) - protocolo;
2. `_EQUIPE/REUNIAO.md` - ata mais recente: o que foi deliberado e o que esta
   atribuido a voce;
3. `_EQUIPE/QUADRO.md` - estado medido, fila de tarefas, dono de cada arquivo;
4. `_EQUIPE/DECISOES.md` - decisoes fechadas e decisoes pendentes;
5. a **sua propria caixa** (`AGENTE_1.md`, `AGENTE_2.md` ou `AGENTE_3.md`);
6. `Tools/HANDOFF.md` - numeros medidos do terminal;
7. `Experts/XAU_AI_PRO/PENDENCIAS.md` - IDs de pendencia (P1.xxx).

Antes de escrever qualquer coisa, leia os 4 primeiros. Sem isso voce vai
repetir trabalho ja feito ou contradizer uma decisao fechada.

## Quem e quem

| Agente | Arquivo | Papel | Acesso ao terminal MT5 |
|---|---|---|---|
| Agente 1 | `AGENTE_1.md` | assistente MT5: mede, corrige codigo, compila, commita local | **sim, exclusivo** |
| Agente 2 | `AGENTE_2.md` | documentacao, analise e revisao (escopo a confirmar) | nao |
| Agente 3 | `AGENTE_3.md` | IA/gateway, dataset, features, testes (escopo a confirmar) | nao |

O `AGENTE_1.md` que esta na raiz do EA
(`Experts/XAU_AI_PRO/AGENTE_1.md`) e apenas um **ponteiro** para esta pasta -
o conteudo real do Agente 1 fica em `_EQUIPE/AGENTE_1.md`.

## Onde cada um escreve

- **So na sua propria caixa.** Voce nunca edita a caixa de outro agente.
- **Documentos compartilhados** (`QUADRO.md`, `DECISOES.md`): qualquer agente
  pode propor, mas **so o dono do topico aplica** e sempre adicionando, nunca
  apagando linha de outro.
- **Codigo** (`Experts/XAU_AI_PRO/**/*.mq5|mqh`): **so o Agente 1 edita**. Se
  voce (2 ou 3) identificar um defeito de codigo, escreva o pedido na sua
  caixa com a linha e a evidencia; o Agente 1 mede, altera e compila.

## Formato de mensagem (obrigatorio)

Use exatamente este bloco. Sem formato, a mensagem nao sera lida.

```
### MSG-<numero> | <DE> -> <PARA> | <AAAA-MM-DD HH:MM>
TIPO: pedido | informacao | decisao | alerta | bloqueio
ASSUNTO: uma linha, objetiva
ESTADO: ABERTO | EM ANDAMENTO | RESPONDIDO | FECHADO
EVIDENCIA: o que foi medido, com numero/linha/arquivo. Se nao mediu, "nao medido".
CORPO: o que precisa ser feito ou decidido, em frases curtas.
PRAZO/IMPACTO: opcional. O que trava se nao for respondido.
```

Numeracao: cada agente numera as suas mensagens em sequencia (`MSG-001`,
`MSG-002`...). Nao reaproveite numero.

Para responder: **nao edite a mensagem do outro**. Abra uma mensagem nova na
sua caixa com o mesmo assunto e referencie (`RE: MSG-007 do Agente 2`).

## Protocolo de handoff (fim de um bloco de trabalho)

1. Escreva na sua caixa: data/hora, versao, **o que mediu**, o que mudou,
   estado (compilado? commitado? recarregado?).
2. Se deixou pela metade, escreva a **linha exata** do proximo passo.
3. Se precisa de algo que so o Agente 1 faz (journal, compilar, recarregar,
   commitar), abra `TIPO: pedido`.
4. Nunca marque nada como resolvido sem citar o numero medido.

## Limites que valem para os tres

1. **Nunca `push`** - credencial do remote `origin` (Forge MQL5) esta expirada.
   Commit e local, com caminhos explicitos, nunca `git add -A` (existe uma
   arvore espelhada `MQL5/Files/XAU_AI_PRO/MQL5/**` que nao deve entrar).
2. **Nunca recarregar o EA nos graficos** sem autorizacao do dono. Os 13
   graficos do perfil `XAI_P216_LIVE` rodam v1.2.159 de proposito.
3. **Nunca alterar parametros de risco** sem pedido explicito.
4. **Nunca commitar `Profiles/Tester/XAU_AI_PRO.set`** sem perguntar.
5. **Nunca conta real.** Conta atual e demo 113568614.
6. **Nunca remover guarda de risco**, ocultar atividade ou falsificar historico.
7. **Medir antes de afirmar.** "Nao medido" e uma resposta aceitavel; inventar
   nao e.
8. **Nunca `git reset`, `checkout` destrutivo, `rebase` ou force-push.**

## Ferramentas de apoio (ja versionadas)

```powershell
# repo: status, validacao estatica, compilacao
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 status
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 check
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\agent-toolkit.ps1 compile

# gateway de IA: porta, raiz, rota de predicao com e sem token
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\api-probe.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File Tools\verify-gateway.ps1

# manual operacional das ferramentas MCP
Tools\AGENT_COMMANDS.md
```

Lacunas conhecidas das ferramentas MCP (todo agente precisa saber):

- `search_text` / `search_regex` devolvem 0 resultados para termos que existem
  nesta arvore -> usar `Select-String` via shell;
- nao existe ferramenta para executar `.mq5` -> compilar e usar
  `chart_add_script`;
- a allowlist de WebRequest e opcao do terminal, fora das raizes do MCP: so o
  operador altera na GUI;
- `read_file_by_lines` reporta contagem de linhas errada em `.md` grandes ->
  usar `[IO.File]::ReadAllText` + `IndexOf`;
- o git avisa `CRLF will be replaced by LF` em todo arquivo alterado: e
  normalizacao esperada, nao erro.

## Primeiro ato de um agente novo

Preencha o **cartao de identidade** da sua caixa (nome da ferramenta/modelo,
raizes que consegue ler e escrever, o que consegue executar). Isso e o que
permite aos outros saberem o que podem te pedir. Sem cartao, o Agente 1 assume
que voce nao tem acesso a nada e nao delega.
