# Simulador Eleitoral Escolar

Sistema para escolas organizarem eleições próprias e simularem regras eleitorais brasileiras. Cada escola mantém sua instalação e seus dados. Os cargos, a ordem de votação e a forma de apuração são configurados em cada eleição.

> **Estado do projeto:** a branch `main` contém apenas a estrutura inicial de uma aplicação Rails. O fluxo de votação, a apuração, os perfis de acesso e a auditoria descritos abaixo **ainda não estão implementados**. O sistema não está pronto para receber uma eleição real, mesmo escolar.

## Como a simulação deve funcionar

1. A pessoa responsável pela escola cria a eleição, cadastra partidos, federações opcionais, candidaturas e cargos, e define a ordem dos cargos na cédula.
2. Para cada cargo, escolhe a forma de apuração: **maioria simples**, **maioria absoluta** ou **proporcional**. O nome do cargo não determina automaticamente a regra.
3. A escola confere a identidade de quem vai votar e marca a participação em uma **lista física**. O aplicativo não terá cadastro de eleitores.
4. O mesário libera a interface de votação no tablet por um botão próprio. O tablet recebe a atualização por WebSocket, enquanto a autorização da sessão fica registrada no servidor.
5. O eleitor vota em todos os cargos daquela eleição, na ordem configurada. Cada escolha é gravada ao tocar em **Confirmar**. Após a gravação confirmada pelo servidor, o tablet reproduz o som da urna uma vez. Ao terminar, o tablet bloqueia até a próxima liberação.
6. O público acompanha a participação e os **percentuais parciais por candidatura em tempo real**. Os vencedores só são declarados após o fechamento e a apuração completa.

Uma instalação escolar pode organizar várias eleições ao longo do tempo. A quantidade de tablets simultâneos por escola será definida no piloto.

## Regras de negócio acordadas

| Tema | Regra prevista |
| --- | --- |
| Participação | Uma pessoa vota uma vez por turno. A conferência e o controle de identidade são feitos pela escola em lista física; a liberação do tablet controla uma sessão por vez, sem identificar digitalmente o eleitor. |
| Cargos e ordem | O criador configura os cargos, a quantidade de vagas, a forma de apuração e a ordem antes da abertura. Esses dados ficam congelados quando a votação começa. |
| Partidos e federações | Cada candidatura tem filiação partidária. Federações são opcionais; na apuração proporcional, somam-se os votos dos partidos que as compõem. |
| Vice | Cargos configurados com vice usam uma chapa. Titular e vice podem pertencer a partidos diferentes. Suplentes e coligações não fazem parte da primeira versão. |
| Maioria simples | Vence quem obtém mais votos válidos, respeitado o número de vagas. Em disputa de duas vagas, como Senado em 2026, o eleitor faz duas escolhas distintas. |
| Maioria absoluta | Uma candidatura precisa superar metade dos votos válidos para vencer no primeiro turno. Caso contrário, as duas mais votadas disputam o segundo turno em outro dia. |
| Proporcional | O eleitor escolhe **um candidato ou uma legenda**, mesmo que haja várias vagas. A distribuição usa quociente eleitoral, quociente partidário e regras de sobras do perfil brasileiro de 2026. |
| Branco e nulo | São tipos distintos de voto, contabilizados separadamente e excluídos do cálculo dos votos válidos. Em duas escolhas para senador, repetir o mesmo candidato torna nula a segunda escolha, com aviso antes da confirmação. |
| Interrupção | Votos já confirmados continuam válidos. Em abandono voluntário, o mesário orienta o eleitor a concluir; persistindo a desistência, as etapas restantes são computadas como nulas e a ocorrência é registrada. Uma queda de conexão exige tentativa de recuperação da sessão. |
| Encerramento | Não se iniciam novas sessões após o horário de fechamento. Uma sessão iniciada antes desse horário tem até **10 minutos** de tolerância para terminar. |
| Divulgação | Percentuais ao vivo são identificados como **resultados parciais**. O relatório final mostra votos, método de cálculo, vagas e ocorrências, sem relacionar pessoas a escolhas. |

As regras brasileiras de **2026** são a referência inicial. Cargos personalizados usam o método escolhido pelo criador. Se uma situação excepcional não tiver regra implementada e verificável — por exemplo, empate sem dado de desempate ou nenhum voto válido —, o sistema deverá marcar o resultado como **pendente**, sem inventar um vencedor.

**Limite de sigilo:** percentuais atualizados após cada voto podem permitir deduzir a escolha de uma pessoa em grupos pequenos. A interface pública não deverá expor sessões, horários ou votos individuais, mas isso não elimina o risco criado pela divulgação parcial ao vivo.

## Entidades previstas

O modelo de domínio planejado separa:

- **Configuração:** instalação escolar, usuário e papel, eleição, turno, disputa, partido, federação, pessoa candidata e candidatura ou chapa.
- **Votação:** tablet, sessão anônima, etapa, recibo de confirmação, voto e ocorrência.
- **Apuração:** cálculo por disputa e turno, resultados por candidatura e agremiação, eventos de auditoria e relatório final.

Um voto em branco ou nulo não aponta para uma candidatura fictícia. A sessão operacional não deve guardar a identidade do eleitor nem criar uma associação pública ou duradoura com suas escolhas.

## Estado técnico atual da `main`

- Aplicação Rails 7.1 com Ruby 3.2.0 e SQLite configurado no `Gemfile` e em `config/database.yml`.
- Rota de verificação de saúde `/up` disponível.
- Ainda não há modelos de eleição, rotas de votação, autenticação de mesário, apuração ou relatórios implementados nesta branch.
- Liberação por WebSocket, publicação em tempo real, segurança operacional e implantação escolar são **requisitos futuros**, não funções já prontas na `main`. A escolha de banco de produção e de eventual cache ainda depende do projeto de implementação; PostgreSQL e Redis não são pré-requisitos do código atual.

O README anterior descrevia funcionalidades planejadas como se já existissem, além de instruções de clone e banco que não correspondiam ao código de `main`. Esta versão distingue o comportamento desejado do que já funciona.

### Executar a estrutura atual para desenvolvimento

Pré-requisitos: Ruby **3.2.0**, Bundler e bibliotecas necessárias à gem `sqlite3` no ambiente local.

```bash
git clone https://github.com/danilo-gazzoli/election-rb.git
cd election-rb
bundle install
bin/rails db:prepare
bin/rails server
```

A aplicação padrão fica em `http://localhost:3000`; `/up` informa se o processo Rails iniciou. Esses passos **não** disponibilizam uma eleição funcional.

## Referências das regras

- [Resolução TSE nº 23.751/2026](https://www.tse.jus.br/legislacao/compilada/res/2026/resolucao-no-23-751-de-26-de-fevereiro-de-2026): ordem de votação, votos por cargo, abandono e voto repetido para senador.
- [Resolução TSE nº 23.677/2021, compilada com alterações de 2026](https://www.tse.jus.br/legislacao/compilada/res/2021/resolucao-no-23-677-de-16-de-dezembro-de-2021): quociente eleitoral, quociente partidário e distribuição de sobras.
- [Resolução TSE nº 23.748/2026](https://www.tse.jus.br/legislacao/compilada/res/2026/resolucao-no-23-748-de-26-de-fevereiro-de-2026): regras atualizadas de segundo turno e apuração proporcional.
- [TSE: coligações e federações](https://www.tse.jus.br/comunicacao/noticias/2025/Dezembro/saiba-a-diferenca-entre-coligacoes-e-federacoes-partidarias): diferença entre os mecanismos e soma dos votos dos partidos federados.

Este projeto é uma **simulação escolar**, não uma urna oficial nem um serviço da Justiça Eleitoral. As fontes devem ser conferidas novamente antes de implementar ou alterar o algoritmo de apuração.

## Contribuição

Abra uma branch a partir da base pretendida, faça mudanças pequenas e envie um pull request com escopo e verificação descritos. Use mensagens de commit no padrão Conventional Commits, por exemplo `docs(readme): document school election requirements`.

## Licença

[MIT](LICENSE).
