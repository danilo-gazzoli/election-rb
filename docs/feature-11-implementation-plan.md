# F11 — Relatório final versionado e publicação

Branch `feature/final-report-publication`, derivada de `develop` 516a275 após integração de F10b. Issue #28; ERS RF16, RF34–35, RF41–42; SDD §§7.1, 7.4 e 8.

## Escopo essencial do MVP

Publicação explícita pelo criador, depois de todos os turnos encerrados e conciliados. Reproduzir e comparar as apurações gravadas antes de publicar. Preservar ambos os turnos e os vencedores decididos no primeiro. Configuração congelada, participação, contagens/percentuais por candidatura e legenda, memória de cálculo e ocorrências agregadas; sem sessão, recibo, terminal, credencial, motivo livre de ocorrência ou horário individual.

Guardar versões imutáveis do relatório com digest e referência à anterior. Repetir publicação sem mudanças recupera a mesma versão. Alterações nos agregados geram outra versão. Consulta pública recupera última versão ou versão escolhida; pendência/anulação nunca apresenta vencedor final. Anulação preserva o histórico armazenado.

TDD de serviço, API e contrato; testes executados pelo agente conforme autorização atual. Uma migration de armazenamento do relatório e verificação essencial de imutabilidade; sem testes adicionais de segurança avançada. Uma regressão completa final.

## Implementação e evidências — 2026-10-03

- Migration 20261003010000: report_versions, versão/digest/conteúdo JSON, referência anterior e proteção essencial de imutabilidade. Aplicada ao banco de testes existente.
- Voting::FinalReport reproduz as apurações já implementadas e compara digest, regra, estado e resultado gravados. Publicação bloqueia turno aberto, conciliação divergente, resultado pendente e eleição anulada. Divergências registram ocorrência atribuída ao criador.
- Voting::PublishReport guarda versão e auditoria na mesma transação; conteúdo igual reutiliza a versão. Notificação ocorre após commit, usando o digest do relatório. Histórico anterior permanece íntegro.
- POST /api/v1/admin/elections/:id/publish: criador, CSRF e limite de comandos existentes; 201 para nova versão, 200 para repetição, 409 para pendência. GET /api/v1/public/elections/:id/report?version=N: leitura anônima da versão atual ou histórica; pendência/anulação sem vencedores.
- Relatório preserva configuração congelada, agendas, ambos os turnos, participação, contagens e percentuais por candidatura, legendas, memória de cálculo proporcional e ocorrências por tipo. Resultado de segundo turno não soma os votos do primeiro. Não expõe sessão, recibo, terminal, credenciais, motivo livre ou horário de voto individual.
- TDD executado pelo agente: serviço RED por classe ausente e GREEN 9/0; API RED por rotas ausentes; integração de publicação/segundo turno/proporcional GREEN 23/0; contrato/notificação RED 13 exemplos e 4 falhas; GREEN 21/0. O caso de divergência foi ampliado para exigir ocorrência, RED confirmado e corrigido.
- Regressão completa: **1042 exemplos, 1 falha documental, 32 pending legados**, em 3 min 24,1 s. A única falha exigia as referências padronizadas RateLimited e AuthenticationUnavailable; corrigidas no OpenAPI. Verificação final de todos os contratos e dos serviços/rotas F11: **100 exemplos, zero falhas**, em 16,56 s. Não se repetiu a suíte completa após essa correção restrita à documentação.
- git diff --check sem erros. Banco usado: election_f3_f6_final_20261002, PostgreSQL real, CI=true. Sem commits, push ou PR nesta etapa; próximo vínculo de entrega é a issue #28.

O relatório final entregue é JSON para o frontend desacoplado. Exportação/backup e restauração continuam na F12; nenhuma interface definitiva foi acrescentada.
