# F10b — Sobras proporcionais 2026

Branch: `feature/proportional-remainders-2026`, criada de `origin/develop` (`f9b1339`).

## Escopo

- Reutilizar QE/QP da F10a; distribuir sobras com médias exatas, primeiro com limites 80%/20%, depois sem esses limites.
- Contar vagas obtidas, inclusive QP não preenchido, no denominador. Preservar filiação e agregação das federações.
- Registrar cada vaga, candidatos elegíveis, frações, unidade selecionada e desempate. Empates sem idade verificada, QE zero e falta de candidatos ficam pendentes.
- Integrar ao encerramento e resultado já existentes; habilitar abertura proporcional apenas para `proporcional_br_2026_v1`.
- Atualizar OpenAPI e verificar uma votação completa e a regressão existente. Sem migrações ou novas camadas de segurança.

## Fontes e validação

SDD §7.3; ERS RF31–RF35; issue #27. Resolução TSE 23.677/2021 compilada para 2026, arts. 8–12-A, verificada em 2026-10-03:
https://www.tse.jus.br/legislacao/compilada/res/2021/resolucao-no-23-677-de-16-de-dezembro-de-2021

Os exemplos pequenos das sobras são casos didáticos derivados das regras; o exemplo histórico oficial QE/QP da F10a permanece identificado como histórico.

O usuário autorizou executar os testes diretamente em 2026-10-03. TDD focal para cálculo, integração e contrato; uma regressão completa ao concluir.

## Implementação e resultado — 2026-10-03

Concluído:

- `ProportionalRemainders` reutiliza `ProportionalCore`, compara frações por multiplicação cruzada e aplica as duas fases. Vagas obtidas e ocupadas permanecem separadas.
- Memória de cada sobra registra fase, unidades/candidatos aptos à próxima vaga, numerador/denominador, seleção, desempate e pendência. Candidatos mantêm a filiação na unidade federada.
- Empates dependentes de idade não cadastrada ficam pendentes; resultados pendentes expõem somente posições já verificadas (`allocated_ids`), sem `elected_ids` finais.
- O leitor da F10a aceita a calculadora completa no encerramento. A votação proporcional é habilitada para a versão conhecida, reutilizando autenticação, confirmação, conciliação, snapshot e persistência existentes.
- OpenAPI descreve `ProportionalResult`, unidades e memória. O resultado continua no endpoint já existente, reservado ao criador; publicação do relatório público é F11.

Evidência executada pelo agente no WSL, `RAILS_ENV=test CI=true`, banco existente `election_f3_f6_final_20261002`:

- RED do cálculo: classe ainda inexistente. GREEN QE/QP + sobras: 27 exemplos/0 falhas.
- RED da integração: abertura e encerramento ainda sem cálculo completo. GREEN: 25 exemplos/0 falhas, incluindo votação real por serviços com votos nominais/legenda, snapshot, encerramento e leitura do resultado gravado.
- RED do contrato: 3 falhas. GREEN contratos selecionados: 22 exemplos/0 falhas.
- Regressão completa, incluindo limites inteiros grandes e QP não preenchido: **1020 exemplos, 0 falhas, 32 pending legados**, 3 min 1,8 s; cobertura 99,34% (10507/10577).
- `git diff --check` sem erros. Sem migrações ou novas rotas.

Mudanças permanecem nesta branch para commits e PR posteriores. Não houve push, merge ou alteração de issue nesta implementação.
