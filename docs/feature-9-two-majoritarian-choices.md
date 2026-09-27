# Feature 9 — duas escolhas majoritárias

## Estado e dependências

Este documento mapeia a [issue #25](https://github.com/danilo-gazzoli/election-rb/issues/25), conforme ERS RF-06, RF-19, RF-24, RF-28 e CA-06 e SDD §§3.2, 5.3 e 7.2. A regra pura `MajoritarianSecondChoice` já calcula a impressão HMAC, pede aviso para repetição e classifica a segunda escolha confirmada como nula. Ainda não existe fluxo de sessão e confirmação que a utilize. O PR desta branch permanece em rascunho até que os critérios da issue sejam atendidos.

| Ordem | Dependência | Necessário para F9 |
| --- | --- | --- |
| 1 | #15 e #16 — usuários, papéis e autenticação | Criador configura; mesário libera; dispositivo de votação se autentica sem expor a escolha. |
| 2 | #20 — eleição, disputa, turno e snapshot | `maioria_simples`, duas vagas, duas escolhas e duas etapas consecutivas; impedir abertura de combinações inválidas. |
| 3 | #10 e #14 — sessão anônima e liberação | Uma sessão ativa por dispositivo; posição autoritativa no servidor; conclusão e abandono controlados. |
| 4 | #9 e #13 — voto, recibo e confirmação | Voto imutável sem FK para sessão; recibo idempotente; transação que grava voto, avança etapa e atualiza progresso transitório. |
| 5 | #22 — parcial e apuração | Somar votos nominais das duas etapas na mesma disputa; separar branco/nulo; declarar vencedores somente após fechar. |
| 6 | #25 — integração das duas escolhas | Conectar a regra pura ao fluxo real, ao aviso e à limpeza do progresso transitório. |

## Implementações de F9

1. **Configuração:** validar o perfil de maioria simples com exatamente duas vagas e duas escolhas. Gerar `voting_stages` com índices 1 e 2 em sequência na mesma disputa e no mesmo turno. Não abrir o perfil enquanto confirmação, abandono e apuração não estiverem integrados e testados.
2. **Progresso sigiloso:** após confirmar a primeira escolha nominal, guardar na sessão apenas HMAC da candidatura vinculado à sessão e à disputa. Branco/nulo na primeira etapa não gera impressão. Chave HMAC fica fora do banco; o servidor nunca aceita uma impressão enviada pelo cliente. O mesário, a API pública, logs e recibos não recebem a impressão nem a escolha.
3. **Confirmação:** bloquear a sessão em transação; conferir etapa esperada, candidatura apta e idempotência antes de aplicar `MajoritarianSecondChoice`. Repetição sem aviso aceito retorna estado de aviso e **não** grava voto, recibo ou avanço. Repetição aceita grava nulo somente na segunda etapa. Escolha distinta grava nominal. O primeiro voto permanece intocado.
4. **Limpeza e recuperação:** apagar a impressão no mesmo commit que conclui a segunda etapa ou o abandono. Reenvio de etapa já confirmada devolve recibo sem reavaliar nem duplicar voto. Desconexão apenas suspende novas confirmações; após reconectar, o dispositivo consulta estado sem receber a primeira escolha.
5. **API e interface:** usar `voting-device` para celular, tablet ou computador provisionado. Exibir aviso explícito antes de confirmar repetição; permitir confirmar o nulo ou voltar e escolher outra candidatura. Som e avanço só após confirmação durável. Não persistir a opção no navegador.
6. **Apuração e auditoria:** contabilizar as duas etapas na disputa, com nulo por repetição separado do nominal; não expor ordem dos votos ou escolha anterior. Relatório final só após encerramento e reconciliação. Auditar operação e incidentes sem conteúdo do voto.

## Testes de aceite antes de concluir a issue

- Unidade: perfis válidos/inválidos; HMAC isolado por sessão e disputa; primeira escolha nominal, branca ou nula; segunda igual/diferente; aviso aceito/recusado.
- Banco e requisição: primeira escolha preservada; repetição gera nulo apenas na segunda; reenvio com a mesma ou outra chave não duplica; duas confirmações concorrentes produzem um voto/recibo/avanço; rollback não avança.
- Sessão: abandono após a primeira gera nulo administrativo só na etapa restante e limpa a impressão; conclusão também limpa; mesário e API pública não conseguem ler a impressão ou a escolha.
- Ponta a ponta: ordem das etapas, aviso, correção da segunda escolha, reconexão, dispositivos de tela pequena e grande, som uma vez após confirmação observada.
- Regressão: suíte RSpec e CI em PostgreSQL novo; contrato OpenAPI atualizado somente quando as rotas forem implementadas. A issue #25 só fecha com esses testes e o perfil efetivamente habilitado.
