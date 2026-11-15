module BenchmarkLLM

# Bibliotecas necessárias
using HTTP
using JSON3
using DataFrames
using CSV
using Statistics
using DotEnv

export run_benchmark

# 1. CONFIGURAÇÕES DO EXPERIMENTO
const API_URL = "https://api.groq.com/openai/v1/chat/completions"
const MODEL_NAME = "openai/gpt-oss-20b"
const TEMPERATURE = 0.5
const NUM_RUNS = 3
const STRATEGIES = ["A_Simples", "B_Role", "C_Estruturado", "D_FewShot", "E_Politicas"]
const RATE_LIMIT_INTERVAL_SEC = 4.2
const REQUEST_TIMEOUT_SEC = 90
const MAX_COMPLETION_TOKENS = 500

# 2. DATASET DE PERGUNTAS
## Como definido no enunciado, o dataset contém 15 perguntas de diferentes categorias.
## A ideia foi criar perguntas voltadas a dúvidas reais de colaboradores do banco, mas sem expor informações sensíveis.
const QUESTIONS = [
    (id="P01", cat="Correspondência", text="Qual o horário limite para postagem de malote expresso para outras capitais?"),
    (id="P02", cat="Transporte de Bens", text="Preciso transferir 15 monitores e 5 cadeiras de uma agência para outra. Qual opção marco no portal?"),
    (id="P03", cat="Suprimentos", text="Meu pedido de toners e papel A4 está parado em 'Aguardando Aprovação' há 4 dias. O que faço?"),
    (id="P04", cat="Exceção", text="Enviei um contrato físico urgente ontem e o rastreio não atualizou. Como aciono a contingência?"),
    (id="P05", cat="Teste Alucinação", text="Vocês fazem transporte internacional de mobiliário residencial para executivos transferidos?"),
    (id="P06", cat="Correspondência", text="Como faço para enviar um documento confidencial para outra filial sem risco de extravio?"),
    (id="P07", cat="Transporte de Bens", text="Existe algum limite de peso ou volume para transporte de equipamentos de TI entre agências?"),
    (id="P08", cat="Suprimentos", text="Posso solicitar suprimentos de escritório para uso pessoal ou apenas para atividades do banco?"),
    (id="P09", cat="Exceção", text="O portal está fora do ar e preciso enviar um malote urgente. Qual é a alternativa para registrar o envio?"),
    (id="P10", cat="Teste Alucinação", text="O portal de logística permite agendar transporte de animais de estimação entre filiais?"),
    (id="P11", cat="Correspondência", text="Como rastrear uma solicitação enviada via Sedex (Correios)?"),
    (id="P12", cat="Transporte de Bens", text="Preciso transportar um cofre pesado para outra agência. Existe algum procedimento especial ou formulário a preencher?"),
    (id="P13", cat="Suprimentos", text="Meu pedido de suprimentos foi parcialmente atendido. Como solicito o restante sem abrir um novo pedido?"),
    (id="P14", cat="Exceção", text="Recebi uma notificação de que meu malote foi extraviado. Qual é o procedimento para abrir uma reclamação formal e solicitar ressarcimento?"),
    (id="P15", cat="Teste Alucinação", text="O portal de logística oferece serviço de entrega de drones para documentos urgentes entre agências?")
]

# 3. CONSTRUTOR DAS 5 ESTRATÉGIAS DE PROMPT
function build_prompt(strategy::String, question::String)::String
    if strategy == "A_Simples"
        return """
        Responda à dúvida do colaborador sobre o portal de logística.
        Pergunta: $question
        """
    elseif strategy == "B_Role"
        return """
        Você é um Especialista de Atendimento da Central de Logística Corporativa do banco. Responda de forma profissional, empática, clara e objetiva.
        Pergunta: $question
        """
    elseif strategy == "C_Estruturado"
        return """
        Você é um agente de suporte do Portal Logístico. Responda obrigatoriamente seguindo esta estrutura:
        1. Resumo Direto (1 frase)
        2. Passo a Passo no Portal
        3. Prazo / SLA Estimado
        4. Canal de Escalonamento (se aplicável)
        Pergunta: $question
        """
    elseif strategy == "D_FewShot"
        return """
        Você é um agente de suporte do Portal Logístico. Siga o padrão dos exemplos abaixo:

        Exemplo 1:
        Usuário: Como envio um envelope comum para outra filial?
        Assistente: Olá! Para envios de documentos físicos, acesse o menu **Correspondências > Novo Malote**, informe o centro de custo e imprima a etiqueta até as 15h.

        Exemplo 2:
        Usuário: Preciso mover um cofre pesado entre andares.
        Assistente: Olá! Movimentações de carga pesada exigem vistoria prévia. Acesse **Transporte de Bens > Carga Especial** e anexe as dimensões aproximadas do item.

        Agora responda:
        Usuário: $question
        Assistente:
        """
    elseif strategy == "E_Politicas"
        return """
        Você é um assistente virtual do Portal de Logística Corporativa.
        DIRETRIZES OBRIGATÓRIAS:
        1. Baseie-se estritamente nos fluxos padrão de correspondência, transporte de bens e suprimentos.
        2. NUNCA invente prazos, menus ou políticas que não foram informados. Se não souber, diga explicitamente que não possui essa informação e oriente abrir um chamado na fila "Dúvidas Gerais".
        3. Nunca solicite senhas, tokens ou dados confidenciais de clientes bancários.
        4. Mantenha tom corporativo, direto e sem jargões técnicos desnecessários.

        Pergunta: $question
        """
    else
        error("Estratégia desconhecida: $strategy")
    end # if
end # function

# 4. CHAMADA À API COM MEDIÇÃO DE LATÊNCIA E TOKENS
function call_llm(
    prompt_text::String,
    api_key::String;
    model_name::String = MODEL_NAME,
    request_timeout_sec::Real = REQUEST_TIMEOUT_SEC,
    max_completion_tokens::Int = MAX_COMPLETION_TOKENS
)
    headers = [
        "Content-Type" => "application/json",
        "Authorization" => "Bearer $api_key"
    ]

    payload = Dict(
        "model" => model_name,
        "temperature" => TEMPERATURE,
        "max_tokens" => max_completion_tokens,
        "messages" => [
            Dict("role" => "user", "content" => prompt_text)
        ]
    )

    t_start = time_ns()
    response = HTTP.post(
        API_URL,
        headers,
        JSON3.write(payload);
        status_exception=false,
        request_timeout=request_timeout_sec
    )
    latency_sec = (time_ns() - t_start) / 1e9

    if response.status != 200
        error("Erro HTTP $(response.status): $(String(response.body))")
    end # if

    data = JSON3.read(String(response.body))
    content = String(data.choices[1].message.content)
    prompt_tokens = Int(data.usage.prompt_tokens)
    completion_tokens = Int(data.usage.completion_tokens)

    return (
        content = content,
        prompt_tokens = prompt_tokens,
        completion_tokens = completion_tokens,
        latency_sec = round(latency_sec, digits=3)
    )
end # function

# 5. PIPELINE PRINCIPAL DO BENCHMARK
"""
    run_benchmark(; env_file, output_file, num_runs, strategies, questions,
                  rate_limit_interval_sec, request_timeout_sec, resume)

Carrega a `GROQ_API_KEY` do `.env`, executa as 5 estratégias sobre o dataset
de perguntas e salva os resultados incrementalmente em CSV. Por padrão, retoma
resultados já gravados e aguarda 4,2 segundos entre chamadas para permanecer
abaixo do limite de requisições do plano gratuito da Groq.
"""
function run_benchmark(;
    env_file::String = normpath(joinpath(@__DIR__, "..", ".env")),
    output_file::String = normpath(joinpath(@__DIR__, "..", "resultados_raw.csv")),
    num_runs::Int = NUM_RUNS,
    strategies = STRATEGIES,
    questions = QUESTIONS,
    rate_limit_interval_sec::Real = RATE_LIMIT_INTERVAL_SEC,
    request_timeout_sec::Real = REQUEST_TIMEOUT_SEC,
    resume::Bool = true
)
    num_runs > 0 || throw(ArgumentError("num_runs deve ser maior que zero"))
    rate_limit_interval_sec >= 0 || throw(ArgumentError("rate_limit_interval_sec não pode ser negativo"))
    request_timeout_sec > 0 || throw(ArgumentError("request_timeout_sec deve ser maior que zero"))

    if isfile(env_file)
        DotEnv.load!(env_file)
    end # if

    api_key = get(ENV, "GROQ_API_KEY", "")
    model_name = get(ENV, "GROQ_MODEL", MODEL_NAME)
    if isempty(api_key)
        error("GROQ_API_KEY não encontrada. Verifique o arquivo .env em: $env_file")
    end # if

    total_calls = length(questions) * length(strategies) * num_runs
    minimum_minutes = total_calls > 1 ? ((total_calls - 1) * rate_limit_interval_sec) / 60 : 0
    println(
        "Iniciando benchmark: $total_calls chamadas previstas no modelo $model_name " *
        "(espera mínima de aproximadamente $(round(minimum_minutes, digits=1)) min no limite configurado)..."
    )
    flush(stdout)

    mkpath(dirname(output_file))
    if !isfile(output_file)
        empty_df = DataFrame(
            run_id = Int[],
            strategy = String[],
            question_id = String[],
            category = String[],
            question = String[],
            response = String[],
            prompt_tokens = Int[],
            completion_tokens = Int[],
            latency_sec = Float64[]
        )
        CSV.write(output_file, empty_df)
    end # if

    completed = Set{Tuple{String,String,Int}}()
    if resume
        existing = CSV.read(output_file, DataFrame)
        for row in eachrow(existing)
            push!(completed, (String(row.strategy), String(row.question_id), Int(row.run_id)))
        end
    end

    current = 0
    for strategy in strategies
        for q in questions
            prompt = build_prompt(strategy, q.text)
            for run in 1:num_runs
                current += 1
                key = (strategy, q.id, run)
                if key in completed
                    println("[$current/$total_calls] $strategy | $(q.id) | Run $run... IGNORADO (já salvo)")
                    continue
                end

                print("[$current/$total_calls] $strategy | $(q.id) | Run $run... ")
                flush(stdout)

                try
                    res = call_llm(
                        prompt,
                        api_key;
                        model_name=model_name,
                        request_timeout_sec=request_timeout_sec
                    )
                    row = DataFrame(
                        run_id = [run],
                        strategy = [strategy],
                        question_id = [q.id],
                        category = [q.cat],
                        question = [q.text],
                        response = [res.content],
                        prompt_tokens = [res.prompt_tokens],
                        completion_tokens = [res.completion_tokens],
                        latency_sec = [res.latency_sec]
                    )
                    CSV.write(output_file, row; append=true)
                    println("OK ($(res.latency_sec)s | in:$(res.prompt_tokens) out:$(res.completion_tokens))")
                    push!(completed, key)
                catch e
                    println("FALHA: $(sprint(showerror, e))")
                end # try
                flush(stdout)

                if current < total_calls && rate_limit_interval_sec > 0
                    # Mantém o ritmo abaixo do limite de requisições da Groq.
                    sleep(rate_limit_interval_sec)
                end
            end # for
        end # for
    end # for

    println("\nExecução concluída. Resumo estatístico salvo em $output_file:")
    df = CSV.read(output_file, DataFrame)
    summary = combine(
        groupby(df, :strategy),
        :prompt_tokens => mean => :avg_input_tokens,
        :completion_tokens => mean => :avg_output_tokens,
        :latency_sec => mean => :avg_latency_sec
    )
    println(summary)
    return summary
end # function

end # module BenchmarkLLM