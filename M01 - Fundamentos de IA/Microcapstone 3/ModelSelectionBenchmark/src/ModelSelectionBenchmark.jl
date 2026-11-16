module ModelSelectionBenchmark

# Bibliotecas necessárias
using HTTP
using JSON
using DataFrames
using CSV
using Statistics
using DotEnv

export run_benchmark

# 1. CONFIGURAÇÕES DO EXPERIMENTO
const API_URL = "https://api.groq.com/openai/v1/chat/completions"
const TEMPERATURE = 0.3
const NUM_RUNS = 3
const RATE_LIMIT_INTERVAL_SEC = 4.2
const REQUEST_TIMEOUT_SEC = 90
const MAX_COMPLETION_TOKENS = 500
const MODELS = [
    (id="openai/gpt-oss-120b", tier="Premium", price_in=0.15, price_out=0.60),
    (id="qwen/qwen3.8-27b", tier="Intermediario", price_in=0.10, price_out=0.30),
    (id="openai/gpt-oss-20b", tier="Economico", price_in=0.075, price_out=0.30)
]

const INCIDENTS = [
    # --- Correspondência/Malote ---
    (id="INC01", cat="Correspondência/Malote", text="O malote diário com documentos de abertura de conta da agência Sul não foi coletado no horário previsto das 16h."),
    (id="INC05", cat="Correspondência/Malote", text="Precisamos enviar hoje até as 17h o dossiê físico original referente ao ofício judicial nº 4029/2026 para o departamento jurídico da matriz, pois o prazo processual vence amanhã às 9h."), # Caso difícil 1: urgência regulatória implícita
    (id="INC09", cat="Correspondência/Malote", text="O código de rastreio do Sedex corporativo gerado pelo portal retorna como inválido no site dos Correios desde ontem à tarde."),
    (id="INC13", cat="Correspondência/Malote", text="Um envelope lacrado destinado à diretoria regional foi entregue por engano na agência do centro e precisa ser redirecionado ainda hoje."),
    (id="INC17", cat="Correspondência/Malote", text="Esqueci minha senha de acesso ao sistema de folha de pagamento e meu token físico parou de funcionar; preciso que a logística libere meu login ou envie um técnico de TI aqui na mesa."), # Caso difícil 2: fora de escopo (TI/RH)

    # --- Transporte de Bens/TI ---
    (id="INC02", cat="Transporte de Bens/TI", text="Solicitação de transferência de 12 estações de trabalho e 6 monitores do prédio administrativo para a nova unidade regional na próxima terça-feira."),
    (id="INC06", cat="Transporte de Bens/TI", text="Precisamos recolher 4 servidores rack desativados na sala técnica do 3º andar para descarte certificado, mas o formulário exige número de patrimônio que está ilegível em um dos equipamentos."),
    (id="INC10", cat="Transporte de Bens/TI", text="Além de o portal apresentar erro 500 ao anexar a nota fiscal de transferência dos notebooks, o pedido de toners da semana passada ainda não chegou e a equipe da agência está sem impressora e sem equipamento para os novos estagiários."), # Caso difícil 3: múltiplos problemas simultâneos
    (id="INC14", cat="Transporte de Bens/TI", text="Vou me mudar de apartamento no próximo sábado e gostaria de saber se posso agendar o caminhão da transportadora parceira do banco pelo portal para levar minha geladeira e sofá."), # Caso difícil 4: fora de escopo (uso pessoal)
    (id="INC18", cat="Transporte de Bens/TI", text="Solicitamos a movimentação de um cofre de 350 kg entre andares, mas o elevador de carga está em manutenção e não há opção no portal para indicar necessidade de içamento ou equipe extra."),

    # --- Suprimentos ---
    (id="INC03", cat="Suprimentos", text="O estoque de bobinas térmicas para terminais de autoatendimento e papel A4 está abaixo do nível mínimo; o pedido feito há 5 dias ainda consta como pendente."),
    (id="INC07", cat="Suprimentos", text="Recebemos 20 caixas de envelopes de segurança com lacre violado na remessa desta manhã e precisamos de reposição imediata para o fechamento do caixa."),
    (id="INC11", cat="Suprimentos", text="Fizemos a solicitação trimestral de materiais de escritório, mas vieram apenas as canetas e pastas; os cartuchos de toner foram cortados sem justificativa no sistema."),
    (id="INC15", cat="Suprimentos", text="O sistema bloqueia o pedido de novos leitores biométricos alegando cota excedida, mas a nossa unidade passou por ampliação recente e dobrou o número de guichês."),
    (id="INC19", cat="Suprimentos", text="Consulta de rotina: qual é a janela mensal padrão para abertura de pedidos ordinários de suprimentos de papelaria para agências do interior?"), # Caso neutro informativo

    # --- SLA/Atendimento ---
    (id="INC04", cat="SLA/Atendimento", text="A transportadora homologada tentou entregar o lote de cartões fora do horário comercial da agência e marcou o chamado como concluído sem recebedor."),
    (id="INC08", cat="SLA/Atendimento", text="Parabéns pelo novo visual do portal de rastreamento, ficou muito moderno; pena que meu malote com contratos assinados está parado no status 'em triagem' há quatro dias sem ninguém responder o chamado."), # Caso difícil 5: ironia / sentimento misto
    (id="INC12", cat="SLA/Atendimento", text="Gostaria de elogiar a equipe de logística especial pela agilidade na mudança do mobiliário da sala de reuniões ontem; tudo foi entregue antes do prazo e sem avarias."), # Caso positivo
    (id="INC16", cat="SLA/Atendimento", text="O motorista responsável pela coleta de malotes da rota oeste não possui crachá de identificação atualizado, o que gerou bloqueio na portaria do edifício corporativo."),
    (id="INC20", cat="SLA/Atendimento", text="O SLA de atendimento para chamados de extravio de malote já venceu há 48 horas e não houve atualização da transportadora nem retorno da central de suporte.")
]

# 2. CONSTRUTOR DO PROMPT ÚNICO
function build_prompt(incident_text::String)::String
    return """
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
    $incident_text
    """
end

# 3. CHAMADA À API COM MEDIÇÃO DE LATÊNCIA E TOKENS
function call_llm(
    prompt_text::String,
    api_key::String,
    model_id::String;
    request_timeout_sec::Real = REQUEST_TIMEOUT_SEC,
    max_completion_tokens::Int = MAX_COMPLETION_TOKENS
)
    headers = [
        "Content-Type" => "application/json",
        "Authorization" => "Bearer $api_key"
    ]
    payload = Dict(
        "model" => model_id,
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
        JSON.json(payload);
        status_exception=false,
        request_timeout=request_timeout_sec
    )
    latency_sec = (time_ns() - t_start) / 1e9

    if response.status != 200
        error("Erro HTTP $(response.status): $(String(response.body))")
    end

    data = JSON.parse(String(response.body))
    content = String(data["choices"][1]["message"]["content"])
    prompt_tokens = Int(data["usage"]["prompt_tokens"])
    completion_tokens = Int(data["usage"]["completion_tokens"])

    return (
        content = content,
        prompt_tokens = prompt_tokens,
        completion_tokens = completion_tokens,
        latency_sec = round(latency_sec, digits=3)
    )
end

"""
    run_benchmark(; env_file, output_file, num_runs, models, incidents,
                  rate_limit_interval_sec, request_timeout_sec, resume)

Carrega a `GROQ_API_KEY` do `.env`, executa os modelos sobre os relatos de
incidentes logísticos e salva os resultados incrementalmente em CSV. Por padrão,
retoma resultados já gravados e aguarda 4,2 segundos entre chamadas para
permanecer abaixo do limite de requisições do plano gratuito da Groq.
"""
function run_benchmark(;
    env_file::String = normpath(joinpath(@__DIR__, "..", ".env")),
    output_file::String = normpath(joinpath(@__DIR__, "..", "resultados_raw.csv")),
    num_runs::Int = NUM_RUNS,
    models = MODELS,
    incidents = INCIDENTS,
    rate_limit_interval_sec::Real = RATE_LIMIT_INTERVAL_SEC,
    request_timeout_sec::Real = REQUEST_TIMEOUT_SEC,
    resume::Bool = true
)
    num_runs > 0 || throw(ArgumentError("num_runs deve ser maior que zero"))
    rate_limit_interval_sec >= 0 || throw(ArgumentError("rate_limit_interval_sec não pode ser negativo"))
    request_timeout_sec > 0 || throw(ArgumentError("request_timeout_sec deve ser maior que zero"))

    if isfile(env_file)
        DotEnv.load!(env_file)
    end
    api_key = get(ENV, "GROQ_API_KEY", "")
    isempty(api_key) && error("GROQ_API_KEY não encontrada. Verifique o arquivo .env em: $env_file")

    total_calls = length(incidents) * length(models) * num_runs
    minimum_minutes = total_calls > 1 ? ((total_calls - 1) * rate_limit_interval_sec) / 60 : 0
    println(
        "Iniciando benchmark: $total_calls chamadas previstas " *
        "(espera mínima de aproximadamente $(round(minimum_minutes, digits=1)) min no limite configurado)..."
    )
    flush(stdout)

    mkpath(dirname(output_file))
    if !isfile(output_file)
        empty_df = DataFrame(
            run_id=Int[],
            model=String[],
            tier=String[],
            incident_id=String[],
            expected_category=String[],
            incident_text=String[],
            response=String[],
            prompt_tokens=Int[],
            completion_tokens=Int[],
            latency_sec=Float64[],
            estimated_cost_usd=Float64[]
        )
        CSV.write(output_file, empty_df)
    end

    completed = Set{Tuple{String,String,Int}}()
    if resume
        existing = CSV.read(output_file, DataFrame)
        for row in eachrow(existing)
            push!(completed, (String(row.model), String(row.incident_id), Int(row.run_id)))
        end
    end

    current = 0
    for model in models
        for incident in incidents
            prompt = build_prompt(incident.text)
            for run in 1:num_runs
                current += 1
                key = (model.id, incident.id, run)
                if key in completed
                    println("[$current/$total_calls] $(model.id) | $(incident.id) | Run $run... IGNORADO (já salvo)")
                    continue
                end

                print("[$current/$total_calls] $(model.id) | $(incident.id) | Run $run... ")
                flush(stdout)
                try
                    res = call_llm(
                        prompt,
                        api_key,
                        model.id;
                        request_timeout_sec=request_timeout_sec
                    )
                    estimated_cost_usd = (
                        (res.prompt_tokens * model.price_in) +
                        (res.completion_tokens * model.price_out)
                    ) / 1_000_000
                    row = DataFrame(
                        run_id=[run],
                        model=[model.id],
                        tier=[model.tier],
                        incident_id=[incident.id],
                        expected_category=[incident.cat],
                        incident_text=[incident.text],
                        response=[res.content],
                        prompt_tokens=[res.prompt_tokens],
                        completion_tokens=[res.completion_tokens],
                        latency_sec=[res.latency_sec],
                        estimated_cost_usd=[estimated_cost_usd]
                    )
                    CSV.write(output_file, row; append=true)
                    println("OK ($(res.latency_sec)s | in:$(res.prompt_tokens) out:$(res.completion_tokens))")
                    push!(completed, key)
                catch e
                    println("FALHA: $(sprint(showerror, e))")
                end
                flush(stdout)

                if current < total_calls && rate_limit_interval_sec > 0
                    # Mantém o ritmo abaixo do limite de requisições da Groq.
                    sleep(rate_limit_interval_sec)
                end
            end
        end
    end

    println("\nExecução concluída. Resumo estatístico salvo em $output_file:")
    df = CSV.read(output_file, DataFrame)
    summary = combine(
        groupby(df, [:model, :tier]),
        :prompt_tokens => mean => :avg_input_tokens,
        :completion_tokens => mean => :avg_output_tokens,
        :latency_sec => mean => :avg_latency_sec,
        :estimated_cost_usd => (values -> mean(values) * 1000) => :cost_per_1k_requests_usd
    )
    println(summary)
    return summary
end

end # module ModelSelectionBenchmark
