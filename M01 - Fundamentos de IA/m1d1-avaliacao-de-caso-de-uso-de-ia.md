---
# yaml-language-server: $schema=schemas\deliverable.schema.json
Module:
    - M01 - Fundamentos de IA
Deliverable Type: Microcapstone
Status: In Progress
Export Status: Draft
Tech Stack:
    - Usecase
    - AI
Creation date: "2026-11-07T23:07:47Z"
Created by:
    - Lucas
Links:
    - M01 - Fundamentos de IA
Object type:
    - Deliverable
Cover image or color: bafyreiaf2hbfvohzgxfazsgpkcor3l5ex4eihnvm2vwzkkv6yqggfcfbhe
id: bafyreigsik74nwkfvdvuoal4yfkzezw3g7sndv4byc4go3dodna4lkzzfu
---
# M1D1 - Avaliação de Caso de Uso de IA   
## **Projeto:** Automação da triagem de documentos e chamados logísticos em larga escala   
 --- 
### 1. Definição do Problema   
Uma divisão de logística e correspondências de um grande banco processa milhares de documentos e malotes físicos diariamente.   
- **Situação atual:**   
    - Todo o roteamento inicial (triagem de extravios, atrasos e devoluções) é feito manualmente por analistas de Nível 1.   
    - Volume de chamados cresceu 40% recentemente.   
    - Tempo de resolução está estourando o SLA.   
    - Alto custo operacional (OPEX) com leitura manual.   
- **Objetivo do negócio:**   
    - Reduzir tempo de triagem e custo operacional, direcionando automaticamente os chamados para os departamentos e transportadoras corretos.
   
 --- 
   
## 2. Natureza do Problema (Framework Base)   
Aplicando o framework da disciplina:   
- **Determinístico:** Parcialmente (formulários padronizados).   
- **Previsão (ML):** Parcialmente (prever o departamento destino).   
- **Linguagem / Interpretação:** Sim (textos livres e descrições de extravios).   
- **Autonomia / Agentes:** Não.   
- **Análise e Conclusão:** O problema mescla documentos com IDs padronizados e tickets abertos em texto livre. A categoria predominante é de roteamento, exigindo interpretação semântica para os textos livres.   
 --- 
   
## 3. Comparação Entre Alternativas   
- **Alternativa A** - Sistema Baseado em Regras (Regex)   
    - **Abordagem:** Scripts (ex: Julia/Python) buscando IDs de rastreio ou palavras-chave padronizadas.   
    - **Vantagens:** Altíssima velocidade, custo de computação quase zero.   
    - **Desvantagens:** Quebra facilmente com erros de digitação ou textos não padronizados.   
    - **Custo:** Baixo.
   
- **Alternativa B** - Machine Learning (Classificador)   
    - **Abordagem:** Treinar um modelo NLP com o histórico de tickets passados para prever a "fila" de destino.   
    - **Vantagens:** Bom para roteamento, lida melhor com variações que o Regex.   
    - **Desvantagens:** Precisa de alto volume de dados rotulados e manutenção constante do modelo.   
    - **Custo:** Médio.   
- **Alternativa C** - Assistente Baseado em LLM   
    - **Abordagem:** Usar LLM via API para ler o contexto do manifesto/ticket e extrair entidades (Rastreio, Problema, Destino).   
    - **Vantagens:** Lida perfeitamente com ambiguidades e textos desestruturados.   
    - **Desvantagens:** Latência maior, custo por token elevado, risco de exposição de dados bancários (PII).   
    - **Custo:** Alto.   
 --- 
   
## 4. Matriz Comparativa de Soluções   
|                   **Critério**   <br> |     **Regras**   <br> | **ML**   <br> |   **LLM**   <br> |
|:--------------------------------------|:----------------------|:--------------|:-----------------|
|    Adequação à previsibilidade   <br> |       **Alta**   <br> |  Média   <br> |     Baixa   <br> |
|           Tratamento semântico   <br> |          Baixo   <br> |  Médio   <br> |  **Alto**   <br> |
|          Complexidade adequada   <br> |       **Alta**   <br> |  Média   <br> |     Média   <br> |
| Necessidade de dados rotulados   <br> |      **Baixa**   <br> |   Alta   <br> | **Baixa**   <br> |
|                Explicabilidade   <br> | **Muito alta**   <br> |  Média   <br> |     Baixa   <br> |
|            Eficiência de custo   <br> |       **Alta**   <br> |  Média   <br> |     Baixa   <br> |
|    Tratamento de textos livres   <br> |          Baixo   <br> |  Média   <br> |  **Alto**   <br> |

 --- 
## 5. Aplicação dos 5 Critérios de Decisão   
- **Critério 1 - Previsibilidade:** Há uma parcela dos malotes que segue formulários estritos, favorecendo regras rígidas.   
- **Critério 2 - Necessidade Semântica:** Há forte presença de ambiguidade nas descrições de falhas logísticas feitas pelos usuários, favorecendo o LLM.   
- **Critério 3 - Complexidade Necessária:** Não há necessidade de planejamento multi-etapas ou agentes autônomos. A tarefa é leitura e classificação.   
- **Critério 4 - Volume de Dados:** Há histórico suficiente para ML, mas o LLM acelera o* time-to-market* sem precisar treinar pesos do zero.   
- **Critério 5 - Explicabilidade:** Essencial em ambiente bancário. Roteamentos errados geram atrasos financeiros.   
 --- 
   
## 6. Recomendação Final   
Solução Recomendada: Sistema Híbrido   
A melhor solução para equilibrar o alto volume, custo de processamento e precisão é combinar abordagens.   
- **Camada 1 (Regras/Regex):** Filtra e roteia automaticamente todos os documentos que possuem padrões claros (IDs de correspondência bem formatados).   
- **Camada 2 (LLM Controlado):** Chamados que caem na "malha fina" (texto livre, sem padrão) são enviados para a API do LLM, que extrai o contexto e sugere o roteamento.   
- **Camada 3 (Humano no loop):** Se a confiança da extração do LLM for baixa, o ticket vai para o analista Nível 1.   
 --- 
   
## 7. Justificativa de Negócio   
- **Redução de custo:** Minimiza o uso de tokens caros (LLM) resolvendo grande parte via Regex (Camada 1), enquanto elimina o tempo gasto por humanos lendo tickets complexos (Camada 2).   
- **Aumento de velocidade:** Triagem inicial em segundos.   
- **Escalabilidade:** Permite absorver o aumento de 40% na demanda sem contratar dezenas de novos analistas.   
 --- 
   
## 8. Mapa de Riscos   
|                              **Risco**   <br> | **Impacto**   <br> |                                                                **Mitigação**   <br> |
|:----------------------------------------------|:-------------------|:------------------------------------------------------------------------------------|
|    Exposição de PII (Dados Bancários)    <br> |        Alto   <br> |             Anonimização/Mascaramento de dados antes de enviar à API do LLM.   <br> |
|              Alucinações no roteamento   <br> |      Médio    <br> |       Forçar o LLM a responder em formato JSON estrito (Structured Outputs).   <br> |
|           Crescimento de custo de API    <br> |      Médio    <br> |    Roteamento híbrido (Regras primeiro) e definição de limites (thresholds).   <br> |

 --- 
## 9. Verificação de Anti-Patterns   
- **Uso por hype:** ✅ Evitado. IA Generativa não foi sugerida para tudo, apenas para o texto desestruturado.   
- **Overengineering:** ✅ Evitado. Sem uso de agentes autônomos para uma tarefa simples de classificação.   
- **Ignorar custo:** ✅ Evitado. Arquitetura híbrida foi proposta justamente para proteger a margem operacional.   
- **Ignorar risco:** ✅ Evitado. Risco de vazamento de dados bancários endereçado.   
 --- 
   
## 10. Conclusão Executiva   
O gargalo logístico do banco não precisa de uma solução unilateral. Aplicar uma arquitetura de triagem em funil — combinando a eficiência computacional de regras determinísticas com a flexibilidade semântica de Modelos de Linguagem — entrega o melhor balanço entre redução de OPEX, segurança de dados operacionais e tempo de implementação.   
