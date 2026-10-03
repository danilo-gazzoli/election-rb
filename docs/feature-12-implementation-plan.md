# F12 — Operação e recuperação do piloto

Branch feature/pilot-operations, a partir de develop 6203b51 (F11 integrada). Issue29; ERS RNF01–08 e §12; SDD §§8–10.

Implementação focada no MVP: comandos de backup PostgreSQL/restauração em destino vazio com checksum, reconciliação e conferência da apuração após recuperação, exportação JSON do relatório público, provisionamento local, implantação Rails/PostgreSQL/proxy HTTPS de mesma origem e roteiro operacional com rollback.

TDD essencial e ensaio real de restauração em banco separado. Não alterar votos nem transformar falha técnica em abandono. Backup integral é privado; relatório exportado usa exclusivamente a projeção pública. Segredos, armazenamento e frontend não entram no repositório.

Aceite operacional completo depende da F5, dois tablets/rede reais e das decisões da escola (capacidade, áudio, retenção, desempate e metas de recuperação). Essas decisões não serão inventadas. Docker Desktop está desligado nesta execução; registrar separadamente configuração validada e implantação realmente ensaiada.

## Evidência verificada em 03/10/2026

- TDD das operações, prontidão e contrato: 16 novos exemplos incluídos na regressão. Sem migração nova.
- Regressão completa com CI=true, PostgreSQL real: 1058 exemplos, 0 falhas, 32 pending antigos; 3 min 41,5 s, carregamento 7,81 s. Cobertura 99,32% (indicador de execução, não garantia de aceite).
- Backup custom restaurado em banco temporário separado: votos, recibos, snapshot, apuração e publicação preservados; relatório público igual e ops:verify reconciliado. Os destinos do ensaio foram removidos pelo próprio teste; nenhum banco de origem foi apagado.
- Arquivo corrompido e destino ocupado recusados. Falha de conexão não gera cópia marcada como concluída. Exportação usa somente a projeção publicada; arquivo existente é preservado.
- Criador inicial inativo recebe credencial aleatória, consumida localmente uma única vez para escolher senha definitiva e ativar a conta. A credencial vai diretamente ao terminal, fora dos logs Rails/stdout; não é uma senha permanente sugerida.
- Sintaxe Bash/Ruby e tarefas Rake verificadas. Docker Compose validado com config --quiet; CI ajustada para instalar clientes PostgreSQL.
- HTTP real com servidor Rails test temporário em 127.0.0.1:4012: 20 consultas de prontidão, dois clientes, zero falhas; 0,431 s total, p50 6,07 ms e p95 367,63 ms (inclui partida fria). Servidor temporário encerrado. Esses valores não são metas de escola nem medição de latência WebSocket.
- Diff sem erros. Guia e comandos: deployment/pilot/README.md; ficha das decisões: decisions.example.md.

## Limites do aceite

Docker Desktop estava desligado: imagem/contêineres, Caddy/HTTPS e implantação real não foram ensaiados. A F5, dois tablets, áudio/acessibilidade, carga de escola e cinco decisões da ERS continuam necessários para aceitar o piloto. Runtime Ruby do protótipo precisa da atualização mantida indicada pelo SDD antes de produção. Backup recupera o ponto da cópia, sem promessa de recuperar votos posteriores à perda do disco.

Entrega do suporte de backend na feature/pilot-operations, preparada em commits por responsabilidade para PR à develop. O aceite integral do piloto permanece separado: a publicação do código não certifica ensaio escolar, implantação HTTPS ou frontend definitivo.
