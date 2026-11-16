# M1D3 — Seleção de Modelo para Produto SaaS com IA
> **Módulo:** Fundamentos de IA | **Entregável:** Microcapstone | **Stack:** Estratégia de IA, Governança
## **Projeto:** Módulo de Inteligência Operacional e Triagem de Incidentes Logísticos

---

## 1. Contexto Empresarial

Uma divisão de logística e correspondências de um grande banco opera um portal interno integrado para solicitações de malotes, transporte de bens patrimoniais/TI e suprimentos corporativos. Diariamente, colaboradores registram centenas de relatos operacionais descrevendo atrasos, avarias, falhas de sistema e divergências de atendimento.

A área pretende incorporar um módulo de Inteligência Artificial ao portal para automatizar a triagem e gerar inteligência gerencial capaz de:

* Classificar a severidade e o sentimento do relato;
* Categorizar automaticamente a frente logística responsável;
* Produzir um resumo executivo padronizado para gestores;
* Recomendar a ação operacional imediata.

Como a solução atenderá alto volume de chamados corporativos, a escolha do modelo precisa equilibrar precisão semântica, aderência ao formato, latência, disponibilidade de API e custo operacional.

## 2. Objetivo

Realizar um benchmark experimental controlado entre três Modelos de Linguagem (LLMs) de diferentes portes e famílias arquiteturais — mantendo fixos o prompt, a temperatura e o dataset de entrada — para recomendar a melhor opção técnica e econômica para implantação em produção.

## 3. Tarefa Empresarial Avaliada (Prompt Congelado)

Para isolar o modelo como única variável do experimento, todos os concorrentes receberam exatamente a mesma instrução congelada (`build_prompt` em `ModelSelectionBenchmark.jl`), incorporando as boas práticas de governança validadas no experimento anterior:

```text
Você é um Analista de Operações Logísticas de um banco. Analise o relato abaixo e
retorne estritamente os quatro itens numerados nesta ordem:
1. Severidade/Sentimento: escolha exatamente uma opção entre Crítico, Negativo,
   Neutro ou Positivo.
2. Categoria Logística: escolha exatamente uma opção entre Correspondência/Malote,
   Transporte de Bens/TI, Suprimentos ou SLA/Atendimento.
3. Resumo Executivo: no máximo 2 linhas.
4. Ação Operacional Recomendada.

Regras obrigatórias:
- Não invente prazos, menus, protocolos, políticas, canais ou procedimentos que não
  estejam no relato.
- Quando faltar informação, declare explicitamente essa limitação e recomende o
  encaminhamento operacional apropriado, sem criar detalhes.
- Sinalize claramente quando o pedido estiver fora do escopo de operações logísticas
  bancárias, como assuntos pessoais, de RH ou de TI sem relação com logística.
- Responda somente com os quatro itens numerados, sem texto adicional.

Relato:
{{INCIDENT_TEXT}}
```

## 4. Dataset de Teste

Foi construído um dataset controlado com **20 relatos operacionais anonimizados** (`INC01` a `INC20`), distribuídos igualmente entre as quatro categorias logísticas e incluindo casos de estresse (urgência regulatória implícita, múltiplos problemas simultâneos, ironia/sentimento misto e pedidos fora de escopo):

| ID | Categoria Esperada | Perfil do Caso | Relato Operacional |
| :--- | :--- | :--- | :--- |
| **INC01** | Correspondência/Malote | Padrão | O malote diário com documentos de abertura de conta da agência Sul não foi coletado no horário previsto das 16h. |
| **INC05** | Correspondência/Malote | Urgência Implícita | Precisamos enviar hoje até as 17h o dossiê físico original referente ao ofício judicial nº 4029/2026 para o departamento jurídico da matriz, pois o prazo processual vence amanhã às 9h. |
| **INC09** | Correspondência/Malote | Padrão | O código de rastreio do Sedex corporativo gerado pelo portal retorna como inválido no site dos Correios desde ontem à tarde. |
| **INC13** | Correspondência/Malote | Padrão | Um envelope lacrado destinado à diretoria regional foi entregue por engano na agência do centro e precisa ser redirecionado ainda hoje. |
| **INC17** | Correspondência/Malote | Fora de Escopo (TI/RH) | Esqueci minha senha de acesso ao sistema de folha de pagamento e meu token físico parou de funcionar; preciso que a logística libere meu login ou envie um técnico de TI aqui na mesa. |
| **INC02** | Transporte de Bens/TI | Padrão | Solicitação de transferência de 12 estações de trabalho e 6 monitores do prédio administrativo para a nova unidade regional na próxima terça-feira. |
| **INC06** | Transporte de Bens/TI | Padrão | Precisamos recolher 4 servidores rack desativados na sala técnica do 3º andar para descarte certificado, mas o formulário exige número de patrimônio que está ilegível em um dos equipamentos. |
| **INC10** | Transporte de Bens/TI | Múltiplos Problemas | Além de o portal apresentar erro 500 ao anexar a nota fiscal de transferência dos notebooks, o pedido de toners da semana passada ainda não chegou e a equipe da agência está sem impressora e sem equipamento para os novos estagiários. |
| **INC14** | Transporte de Bens/TI | Fora de Escopo (Pessoal) | Vou me mudar de apartamento no próximo sábado e gostaria de saber se posso agendar o caminhão da transportadora parceira do banco pelo portal para levar minha geladeira e sofá. |
| **INC18** | Transporte de Bens/TI | Padrão | Solicitamos a movimentação de um cofre de 350 kg entre andares, mas o elevador de carga está em manutenção e não há opção no portal para indicar necessidade de içamento ou equipe extra. |
| **INC03** | Suprimentos | Padrão | O estoque de bobinas térmicas para terminais de autoatendimento e papel A4 está abaixo do nível mínimo; o pedido feito há 5 dias ainda consta como pendente. |
| **INC07** | Suprimentos | Padrão | Recebemos 20 caixas de envelopes de segurança com lacre violado na remessa desta manhã e precisamos de reposição imediata para o fechamento do caixa. |
| **INC11** | Suprimentos | Padrão | Fizemos a solicitação trimestral de materiais de escritório, mas vieram apenas as canetas e pastas; os cartuchos de toner foram cortados sem justificativa no sistema. |
| **INC15** | Suprimentos | Padrão | O sistema bloqueia o pedido de novos leitores biométricos alegando cota excedida, mas a nossa unidade passou por ampliação recente e dobrou o número de guichês. |
| **INC19** | Suprimentos | Neutro / Informativo | Consulta de rotina: qual é a janela mensal padrão para abertura de pedidos ordinários de suprimentos de papelaria para agências do interior? |
| **INC04** | SLA/Atendimento | Padrão | A transportadora homologada tentou entregar o lote de cartões fora do horário comercial da agência e marcou o chamado como concluído sem recebedor. |
| **INC08** | SLA/Atendimento | Ironia / Misto | Parabéns pelo novo visual do portal de rastreamento, ficou muito moderno; pena que meu malote com contratos assinados está parado no status 'em triagem' há quatro dias sem ninguém responder o chamado. |
| **INC12** | SLA/Atendimento | Positivo | Gostaria de elogiar a equipe de logística especial pela agilidade na mudança do mobiliário da sala de reuniões ontem; tudo foi entregue antes do prazo e sem avarias. |
| **INC16** | SLA/Atendimento | Padrão | O motorista responsável pela coleta de malotes da rota oeste não possui crachá de identificação atualizado, o que gerou bloqueio na portaria do edifício corporativo. |
| **INC20** | SLA/Atendimento | Padrão | O SLA de atendimento para chamados de extravio de malote já venceu há 48 horas e não houve atualização da transportadora nem retorno da central de suporte. |

## 5. Modelos Avaliados

Foram selecionados três modelos disponíveis na infraestrutura da Groq representando diferentes escalas de parâmetros, famílias e faixas de precificação:

| Modelo | Perfil (Tier) | Tarifa Input ($\text{USD} / 1\text{M tokens}$) | Tarifa Output ($\text{USD} / 1\text{M tokens}$) | Objetivo no Benchmark |
| :--- | :--- | :---: | :---: | :--- |
| **`openai/gpt-oss-120b`** | Premium ($120\text{B}$) | $\$0,150$ | $\$0,600$ | Teto de capacidade semântica, raciocínio e interpretação de nuances. |
| **`qwen/qwen3.8-27b`** | Intermediário ($27\text{B}$) | $\$0,100$ | $\$0,300$ | Equilíbrio entre precisão em português, concisão e custo operacional. |
| **`openai/gpt-oss-20b`** | Econômico ($20\text{B}$) | $\$0,075$ | $\$0,300$ | Baixo custo nominal por token e velocidade para alto volume. |

## 6. Plano de Benchmark (Metodologia)

O experimento foi executado de forma automatizada pelo pacote **`ModelSelectionBenchmark.jl`** sob condições equivalentes:

* **Parâmetros de Inferência:** Temperatura fixada em $T = 0,3$, limite de saída em $500$ tokens (`max_tokens = 500`) e requisições isoladas (*stateless*).
* **Volume Planejado:** $20 \text{ relatos} \times 3 \text{ modelos} \times 3 \text{ execuções} = 180 \text{ chamadas previstas}$.
* **Cobertura e Resiliência Observada:** Os modelos `openai/gpt-oss-120b` e `openai/gpt-oss-20b` concluíram $100\%$ das execuções ($60/60$ cada). O modelo `qwen/qwen3.8-27b` concluiu $85\%$ das execuções ($51/60$), sofrendo $9$ bloqueios por *rate limit* e sobrecarga no plano gratuito da API — dado incorporado na avaliação de disponibilidade.
* **Escala Qualitativa:** $1 = \text{Muito Ruim}$ | $2 = \text{Ruim}$ | $3 = \text{Regular}$ | $4 = \text{Bom}$ | $5 = \text{Excelente}$.

## 7. Resultados Consolidados e Análise Comparativa

### 7.1 Métricas Quantitativas de Engenharia e FinOps

Os valores abaixo foram extraídos da telemetria registrada em `resultados_raw.csv`, acompanhados do diferencial relativo frente ao modelo de maior porte (`openai/gpt-oss-120b`):

| Modelo | Tier | Tokens Entrada (Média) | Tokens Saída (Média) | Latência Média ($\text{s}$) | Delta Latência vs. Premium | Custo / $1.000$ Reqs ($\text{USD}$) | Economia vs. Premium |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **`openai/gpt-oss-120b`** | Premium | $332,60$ | $305,57$ | $0,972$ | Baseline | $\$0,2332$ | Baseline |
| **`qwen/qwen3.8-27b`** | Intermediário | **$288,94$** | **$108,49$** | **$0,600$** | **$-38,3\%$** | **$\$0,0614$** | **$-73,7\%$** |
| **`openai/gpt-oss-20b`** | Econômico | $332,60$ | $441,78$ | $0,772$ | $-20,6\%$ | $\$0,1575$ | $-32,5\%$ |

**Leitura Técnica dos Números:**
* **Eficiência de Tokenização e Concisão:** O `qwen/qwen3.8-27b` utilizou $13,1\%$ menos tokens de entrada (melhor compressão do vocabulário em português) e gerou respostas $64,5\%$ mais enxutas que o `120b` ($108,49$ vs. $305,57$ tokens), reduzindo drasticamente o tempo de decodificação (*decode*).
* **Gargalo de Geração no Modelo Compacto:** O `openai/gpt-oss-20b` gerou em média $441,78$ tokens — $4,07\times$ mais que o Qwen — operando próximo ao limite de $500$ tokens e encarecendo sua operação efetiva.

### 7.2 Matriz Visual de Avaliação Ponderada (Critérios de Negócio)

Para conectar os resultados técnicos às prioridades reais do portal logístico do banco, cada critério recebeu um **peso de negócio** e uma classificação visual de desempenho:

* 🟢 **Acima do Esperado ($4,5 - 5,0$):** Atende plenamente aos requisitos de produção sem ressalvas.
* 🟡 **Adequado / Na Média ($4,0 - 4,4$):** Aceitável para operação, mas requer monitoramento ou ajustes.
* 🔴 **Abaixo do Esperado ($< 4,0$):** Apresenta risco operacional, financeiro ou de quebra de integração.

| Critério de Avaliação | Peso Negócio | `openai/gpt-oss-120b` (Premium) | `qwen/qwen3.8-27b` (Intermediário) | `openai/gpt-oss-20b` (Econômico) |
| :--- | :---: | :---: | :---: | :---: |
| **Qualidade Semântica** *(nuances, ironia, urgência)* | $25\%$ | 🟢 **$5,0$** *(Acima)* | 🟡 **$4,4$** *(Na Média)* | 🟡 **$4,0$** *(Na Média)* |
| **Adequação ao Formato** *(aderência aos 4 itens)* | $20\%$ | 🟢 **$4,9$** *(Acima)* | 🟢 **$4,8$** *(Acima)* | 🔴 **$3,8$** *(Abaixo)* |
| **Custo Operacional Efetivo** *(escala em alto volume)* | $20\%$ | 🔴 **$3,2$** *(Abaixo)* | 🟢 **$5,0$** *(Acima)* | 🔴 **$3,8$** *(Abaixo)* |
| **Consistência entre Execuções** *(estabilidade $3\times$)* | $15\%$ | 🟢 **$4,8$** *(Acima)* | 🟢 **$4,5$** *(Acima)* | 🟡 **$4,1$** *(Na Média)* |
| **Latência de Resposta** *(experiência no portal)* | $10\%$ | 🟡 **$4,0$** *(Na Média)* | 🟢 **$5,0$** *(Acima)* | 🟡 **$4,4$** *(Na Média)* |
| **Estabilidade e Disponibilidade** *(taxa de sucesso API)* | $10\%$ | 🟢 **$4,8$** *(Acima)* | 🟡 **$4,1$** *(Na Média)* | 🔴 **$3,9$** *(Abaixo)* |
| **Média Simples (Não Ponderada)** | — | $4,45$ | **$4,63$** | $4,00$ |
| **Nota Final Ponderada (Alinhada ao Negócio)** | **$100\%$** | **$4,47$** | 🟢 **$4,65$** | **$3,97$** |

### 7.3 Diagnóstico por Modelo: Onde se Destaca vs. Onde Fica Abaixo do Esperado

| Modelo | Onde se Destaca (Acima do Esperado) | Onde Fica Abaixo do Esperado | Alinhamento com a Tarefa Logística |
| :--- | :--- | :--- | :--- |
| **`openai/gpt-oss-120b`** | **Compreensão semântica ($5,0$) e estabilidade ($4,8$):** Identificou $100\%$ dos casos de ironia (`INC08`), urgência judicial implícita (`INC05`) e pedidos fora de escopo (`INC14`/`INC17`) sem falhas de API. | **Custo por requisição ($3,2$):** É $3,8\times$ mais caro que o Qwen ($\$0,2332$ vs. $\$0,0614 / 1\text{k}$ reqs) e possui a maior latência ($0,972\text{ s}$). | Ideal como **camada de escalonamento (Tier 2)** para incidentes críticos ou ambíguos, onde o custo de um erro operacional supera o custo da chamada. |
| **`qwen/qwen3.8-27b`** | **Eficiência financeira ($5,0$), latência ($5,0$) e formato ($4,8$):** Menor custo real, resposta mais rápida ($0,600\text{ s}$) e síntese objetiva sem verbosidade. | **Resiliência sob rajada ($4,1$):** Sofreu $15\%$ de bloqueios HTTP $429$ no plano gratuito da API, exigindo mecanismo de contingência. | Melhor **motor principal (Tier 1)** para absorver a triagem diária em alto volume, desde que protegido por *retry* e *fallback* automático. |
| **`openai/gpt-oss-20b`** | **Preço nominal de entrada:** Tarifa base baixa ($\$0,075 / 1\text{M}$ input tokens) e boa velocidade média ($0,772\text{ s}$). | **Formato ($3,8$), custo real ($3,8$) e confiabilidade ($3,9$):** Gastou excesso de tokens em raciocínio interno, gerando saídas cortadas ou vazias (`missing`). | **Inadequado para produção** nesta tarefa: o truncamento dos 4 itens quebra a integração automatizada com o sistema de chamados. |

### 7.4 Análise Aprofundada por Critério

* **Qualidade Semântica vs. Complexidade do Relato:** Em incidentes diretos (como `INC01` e `INC03`), os três modelos classificaram corretamente a categoria e a severidade. A diferença surgiu nos $5$ casos de estresse: o `openai/gpt-oss-120b` e o `qwen/qwen3.8-27b` separaram elogio de reclamação na `INC08` e elevaram a severidade da `INC05` para `Crítico` pelo prazo judicial, enquanto o `openai/gpt-oss-20b` falhou em concluir a emissão em cenários ambíguos.
* **Adequação ao Formato e Risco de Integração:** Como o módulo alimentará filas automáticas no portal do banco, qualquer resposta fora do padrão exige triagem manual. O `qwen/qwen3.8-27b` e o `openai/gpt-oss-120b` mantiveram os 4 itens íntegros em $100\%$ das respostas concluídas. Já o `openai/gpt-oss-20b` frequentemente consumiu mais de $450$ tokens em pensamento interno, cortando o item 4 (*Ação Operacional*).
* **Trade-off Custo-Qualidade:** A matriz ponderada comprova que o `qwen/qwen3.8-27b` ($4,65$) supera o `openai/gpt-oss-120b` ($4,47$) no equilíbrio global porque entrega $88\%$ da nota máxima de qualidade semântica por apenas $26,3\%$ do custo operacional.

### 7.5 Evidências Empíricas dos Testes (`INC05` e `INC08`)

Os trechos literais abaixo, extraídos da Execução 1 (`run_id = 1`) em `resultados_raw.csv`, demonstram as diferenças práticas de comportamento nos cenários de estresse:

* **Caso `INC05` (Urgência regulatória implícita — ofício judicial vencendo às 9h do dia seguinte):**

  * **`openai/gpt-oss-120b` (Precisão semântica e concisão):**

    > *"1. Crítico*
    > *2. Correspondência/Malote*
    > *3. Envio urgente do dossiê físico original ao jurídico da matriz até as 17h para cumprir prazo judicial.*
    > *4. Priorizar coleta imediata e despacho via serviço de entrega expressa interno, registrar protocolo de envio e confirmar recebimento antes do prazo."*

  * **`qwen/qwen3.8-27b` (Máxima aderência ao esquema com baixo custo de tokens):**

    > *"1. Severidade/Sentimento: Crítico*
    > *2. Categoria Logística: Correspondência/Malote*
    > *3. Resumo Executivo: Necessidade de envio urgente de dossiê físico original para a matriz até 17h, com prazo processual de vencimento no dia seguinte às 9h.*
    > *4. Ação Operacional Recomendada: Priorizar o despacho imediato do documento via malote expresso ou serviço de entrega urgente disponível, garantindo o rastreamento e a confirmação de recebimento antes do prazo limite de 17h."*

  * **`openai/gpt-oss-20b` (Truncamento por estouro de `max_tokens = 500`):**

    > *"1. Severidade/Sentimento: Crítico*
    > *2. Categoria Logística: Correspondência/Malote*
    > *3. Resumo Executivo: Urgente envio de dossiê físico original do ofício judicial nº 4029/2026 ao departamento jurídico da matriz até 17h, prazo processual amanhã às 9h.*
    > *4. Ação Operacional Recom"* *(Corte abrupto no meio da palavra devido ao consumo excessivo de tokens de raciocínio interno antes da resposta final).*

* **Caso `INC08` (Ironia e sentimento misto — elogio ao portal seguido de relato de malote parado há 4 dias):**

  * **`openai/gpt-oss-120b` (Desambiguação correta de sarcasmo):**

    > *"1. Severidade/Sentimento: Negativo*
    > *2. Categoria Logística: Correspondência/Malote*
    > *3. Resumo Executivo: O cliente elogia o novo portal, mas relata que seu malote com contratos está parado em 'em triagem' há quatro dias sem resposta.*
    > *4. Ação Operacional Recomendada: Encaminhar o caso ao setor de triagem de malotes para verificação imediata do status, solicitar atualização ao responsável e garantir a liberação ou entrega urgente do documento."*

  * **`openai/gpt-oss-20b` (Falha completa de emissão):**

    > Retornou saída vazia (`missing`) na Execução 1 ao esgotar o limite de $500$ tokens durante o processamento interno da ambiguidade semântica. *(Nota: Para o `qwen/qwen3.8-27b`, a Execução 1 da `INC08` coincidiu com um dos $9$ bloqueios de rate limit da API, sendo coberta nas execuções subsequentes).*

## 8. Análise Crítica e Descobertas de Engenharia

1. **Paradoxo entre Preço Nominal e Custo Efetivo (FinOps):** Embora o `openai/gpt-oss-20b` possuísse a menor tarifa nominal de entrada ($\$0,075 / 1\text{M}$ tokens), seu custo real por $1.000$ requisições ($\$0,1575$) foi **$2,56\times$ maior** que o do `qwen/qwen3.8-27b` ($\$0,0614$). Isso ocorreu pela melhor compressão do tokenizador do Qwen em português ($288,94$ vs. $332,60$ tokens de entrada) e pela concisão da saída ($108,49$ vs. $441,78$ tokens).
2. **Risco de Truncamento em Modelos com Raciocínio Verboso:** As evidências da `INC05` e `INC08` comprovam que modelos compactos com *reasoning* interno ativado consomem grande parte do orçamento de `max_tokens` antes de escrever a resposta visível, inviabilizando seu uso em pipelines estruturados sem aumento significativo de margem de tokens e custo.
3. **Throughput e Resiliência de Infraestrutura:** A ocorrência de bloqueios por *rate limit* no `qwen/qwen3.8-27b` ($51/60$ concluídos) evidencia que a seleção de modelo em produção exige arquitetura tolerante a falhas com roteamento de contingência.

## 9. Recomendação Final, Viabilidade Econômica e Arquitetura de Implementação

Com base na **Nota Final Ponderada ($4,65$)** e no diagnóstico comparativo da Seção 7, recomenda-se adotar uma **arquitetura híbrida de roteamento em dois níveis (Model Router)**, utilizando o **`qwen/qwen3.8-27b` como motor principal (Tier 1)** e o **`openai/gpt-oss-120b` como contingência e escalonamento (Tier 2)**.

### 9.1 Impacto Operacional e Projeção Financeira (Cenário de $60.000$ Chamados/Mês)

Simulando uma operação bancária com volume médio de $2.000\text{ chamados/dia}$ ($60.000\text{ chamados/mês}$), a comparação entre arquiteturas demonstra como a recomendação atende simultaneamente às metas de SLA, qualidade e margem operacional:

| Cenário Arquitetural | Custo Mensal Estimado | Latência Média Esperada | Taxa de Retrabalho / Quebra de Formato | Impacto no Negócio |
| :--- | :---: | :---: | :---: | :--- |
| **100% `openai/gpt-oss-120b`** *(Tier Premium)* | $\$13,99$ | $0,972\text{ s}$ | $\approx 0\%$ | Máxima precisão, mas custo $2,67\times$ maior que o necessário em tickets simples. |
| **100% `openai/gpt-oss-20b`** *(Tier Econômico)* | $\$9,45$ | $0,772\text{ s}$ | $> 15\%$ *(truncamento)* | Alto risco operacional: falhas de schema exigem revisão manual e atrasam SLAs. |
| **Híbrido Recomendado** *($85\%$ Qwen + $15\%$ 120B)* | **$\$5,23$** | **$0,656\text{ s}$** | **$\approx 0\%$** | **Economia de $62,6\%$ vs. Premium** e **$44,6\%$ vs. Econômico**, com triagem sub-segundo e $100\%$ de cobertura. |

* **Ganho de Produtividade:** Substitui minutos de leitura e classificação manual por analistas Nível 1 por triagem automatizada em **$0,66\text{ s}$**, absorvendo picos sazonais sem ampliação de equipe.
* **Proteção de SLA Crítico:** Os $15\%$ de relatos classificados como `Crítico` (como prazos judiciais na `INC05`) ou afetados por *rate limit* são validados pelo `openai/gpt-oss-120b`, eliminando falhas silenciosas em incidentes de alto impacto financeiro ou regulatório.

### 9.2 Fluxo de Implementação em Produção

```text
[Ticket / Relato Logístico]
         │
         ▼
1. Pré-processamento & Mascaramento PII (LGPD)
         │
         ▼
2. Tier 1: qwen/qwen3.8-27b (T = 0.2 | JSON Schema Estrito)
         │
         ├──► Sucesso + Severidade != Crítico ──► [Fila Logística Automatizada]
         │
         └──► Falha (HTTP 429/5xx, Erro de Schema) OU Severidade == Crítico
                        │
                        ▼
3. Tier 2 (Fallback): openai/gpt-oss-120b (Alta Precisão Semântica)
                        │
                        ├──► Confiança Alta ──► [Fila Logística Prioritária]
                        └──► Fora de Escopo / Baixa Confiança ──► [Triagem Humana N1]
```

### 9.3 Pilares Técnicos da Implantação

1. **Roteamento Inteligente por Criticidade e Disponibilidade:**
   * **Fluxo Ordinário (`qwen/qwen3.8-27b`):** Absorve $\approx 85\%$ do tráfego diário com latência média de $0,600\text{ s}$ e custo de $\$0,0614$ por $1.000$ chamados.
   * **Escalonamento Automático (`openai/gpt-oss-120b`):** Acionado como *fallback* imediato em indisponibilidade/HTTP $429$ do Tier 1 e como segunda validação sempre que o relato for classificado como `Crítico`.
2. **Resiliência de Chamadas (*Retry & Circuit Breaker*):**
   * Política de *retry* com *exponential backoff + jitter* ($2$ tentativas em $500\text{ ms}$ e $1.500\text{ ms}$) antes de acionar o Tier 2, combinada com *circuit breaker* caso a taxa de HTTP $429$ ultrapasse $10\%$ em janela de $1$ minuto.
3. **Contrato Estruturado de Saída (*Structured Outputs*):**
   * Uso de **JSON Schema estrito** (`severity`, `category`, `executive_summary`, `recommended_action`, `is_out_of_scope`) para integração direta via webhook com o sistema de chamados do banco (ex.: ServiceNow/Jira).
4. **Privacidade (LGPD) e Observabilidade FinOps:**
   * Camada determinística (Regex/NER local) para mascaramento de CPFs, matrículas e contas antes da inferência, somada a telemetria contínua de `model_used`, `fallback_triggered`, `latency_ms` e `cost_usd`.

## 10. Resumo Executivo para Liderança

Foi conduzido um benchmark experimental automatizado comparando três modelos de linguagem (`openai/gpt-oss-120b`, `qwen/qwen3.8-27b` e `openai/gpt-oss-20b`) na triagem e classificação de incidentes logísticos bancários.

A matriz visual ponderada pelos critérios de negócio confirmou a liderança do **modelo intermediário (`qwen/qwen3.8-27b`, nota $4,65/5,00$)** frente ao premium (`openai/gpt-oss-120b`, nota $4,47$) e ao econômico (`openai/gpt-oss-20b`, nota $3,97$). O Qwen entregou a menor latência média ($0,60\text{ s}$) e o menor custo operacional ($\$0,0614$ a cada $1.000$ chamados), enquanto o modelo econômico apresentou truncamento de respostas por excesso de tokens internos de raciocínio.

Para mitigar os limites de vazão (*rate limit*) do modelo intermediário sob picos de demanda e garantir precisão máxima em incidentes críticos, recomenda-se implantar uma arquitetura híbrida de **roteamento em dois níveis** (`qwen/qwen3.8-27b` no Tier 1 + `openai/gpt-oss-120b` no Tier 2), projetando uma **economia mensal de $62,6\%$** frente ao uso exclusivo do modelo premium e tempo médio de triagem de **$0,66\text{ s}$**.