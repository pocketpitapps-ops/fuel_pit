# Fuel Pit – Smoke Test (completo, Notion-ready)

**Objetivo:** Em 10–20 minutos, garantir que as funcionalidades críticas não estão partidas antes de um release.

---

## 0. Pré‑condições do teste

- [s] Build instalada em dispositivo real ou emulador recente (Android/iOS).  
- [s] Ambiente apontado para Supabase de staging/sandbox.  
- [i] Pelo menos:
  - [i] 1 utilizador de teste com dados básicos (perfil, 1 veículo, 1–2 cupões, 2–3 abastecimentos).  
  - [s] 1 utilizador “limpo” (sem veículos, sem abastecimentos).  

---

## 1. Arranque, autenticação e sessão

- [s] A app instala e arranca sem crash.  
- [na] Splash/primeiro ecrã aparece sem “piscadelas” estranhas ou layout quebrado.  
- [i] Ecrã de autenticação mostra:
  - [i] Logo/nome Fuel Pit corretos (sem “PocketFuel”).  
  - [i] Inputs de email e password alinhados e usáveis (teclado adequado, email com “@”, etc.).  
- [s] Login com utilizador de teste válido funciona:
  - [s] Não há loaders “infinitos” nem mensagens de erro fantasma.  
  - [s] Após login, a dashboard inicial aparece sem erros.  
- [s] Login com credenciais inválidas:
  - [s] Mostra mensagem de erro clara e localizada (email/pass errados).  
  - [s] Não faz navegação para área autenticada.  
- [s] Fechar e reabrir a app mantém a sessão do utilizador autenticado (sem piscar AuthPage).  
- [na] Se o token expirar (quando conseguires simular), a app volta para AuthPage de forma limpa, sem crash.  

---

## 2. Signup, confirmação de email e deep link

- [i] No ecrã de autenticação, o botão de criar conta abre o fluxo de registo.  
- [n] Tentar registar com email já existente mostra erro apropriado.  
- [s] Registo com novo email:
  - [s] Mostra mensagem a indicar que é necessário confirmar o email.  
- [s] Email de confirmação recebido (em staging) contém link com redirect configurado para o esquema da app (pocketfuel://auth-callback ou equivalente atualizado).  
- [s] Android:
  - [s] Com a app fechada, tocar no link abre a Fuel Pit.  
  - [s] O utilizador fica autenticado e cai na dashboard, sem pedir login de novo.  
- [na] iOS:
  - [na] Com a app fechada, tocar no link abre a Fuel Pit.  
  - [na] O utilizador fica autenticado e vai para a dashboard.  
- [s] Se o link for usado numa sessão já autenticada, o comportamento é previsível (não duplica utilizador, não faz logout).  

---

## 3. Modo convidado (guest)

- [s] Na AuthPage, a opção “Continuar como convidado” está visível e clara.  
- [ ] Ao entrar como convidado:
  - [s] A dashboard abre em modo read‑only onde fizer sentido (por ex., não gravar dados em Supabase).  
  - [s] Elementos que exigem conta mostram call‑to‑action para criar conta/login em vez de falharem silenciosamente.  
- [i] Fechar e reabrir a app em modo convidado mantém o estado guest (não força login).  
- [ ] A partir do modo convidado, tentar aceder a:
  - [na] Perfil → mostra UI adaptada (sem email real, sem ações de conta irrelevantes).  
  - [s] Criar veículos/abastecimentos → comportamento esperado (ou bloqueado com mensagem clara, ou guardado apenas localmente, consoante o que definiste).  

---

## 4. Perfil, tema e preferências principais

- [s] O ecrã Perfil abre sem erros a partir da navegação principal.  
- [i] O cabeçalho mostra nome e email corretos para o utilizador autenticado.  
- [i] Alterar a moeda (ex.: de EUR para USD) e guardar:
  - [n] Ao voltar imediatamente ao Perfil, a moeda está correta.  
  - [s] Reiniciar a app mantém a moeda escolhida.  
- [s] Alterar o modo de abastecimento padrão (por valor ↔ por litros) e o valor:
  - [s] Guardar mostra snackbar de sucesso.  
  - [s] Ao voltar ao Perfil, o modo e o valor mantêm‑se.  
- [s] Alternar “Tema escuro”:
  - [s] O tema muda imediatamente na app inteira.  
  - [s] Fechar e reabrir a app mantém o tema escolhido.  
- [s] Verificar se nenhum texto/label no Perfil ainda diz “PocketFuel” ou nomes antigos.  

---

## 5. Veículos (CRUD mínimo + principal)

- [s] Abrir o ecrã Veículos não provoca erros (nem loading infinito).  
- [i] Com utilizador “limpo”:
  - [i] Estado “sem veículos” é claro (texto e call‑to‑action).  
- [i] Adicionar um novo veículo:
  - [i] Validações básicas (matrícula obrigatória, etc.) funcionam.  
  - [s] Após gravar, o veículo aparece na lista.  
- [s] Definir esse veículo como principal:
  - [s] O veículo principal aparece no topo da lista de veículos ou com destaque claro.  
  - [s] No Perfil, o “Veículo principal” mostrado corresponde ao selecionado.  
- [s] Editar veículo:
  - [s] Alterar um campo e gravar; a lista reflete as alterações.  
- [s] Apagar um veículo:
  - [s] O veículo desaparece da lista.  
  - [s] Um snackbar/mensagem de confirmação é mostrado.  
  - [s] Se o veículo apagado for o principal, o comportamento é consistente (define outro principal ou mostra “sem veículo principal”).  

---

## 6. Abastecimentos (fluxo base)

- [ ] Ecrã de Abastecimentos abre sem erros.  
- [ ] Com utilizador de teste com dados:
  - [ ] A lista mostra abastecimentos com valores consistentes (data, litros, preço total, cupão aplicado).  
- [s] Criar novo abastecimento:
  - [i] Selecionar veículo, posto, tipo de combustível, modo (valor/litros) e, se existir, cupão.  
  - [s] Guardar não causa erro e mostra snackbar de sucesso.  
  - [s] O abastecimento aparece imediatamente na lista com os dados corretos.  
- [s] Editar abastecimento existente e guardar:
  - [s] As alterações aparecem na listagem.  
- [n] Apagar abastecimento:
  - [n] É removido da lista.  
  - [n] Mensagem de confirmação é exibida.  

---

## 7. Cupões (criação, utilização e retenção)

### 7.1. Ecrã e criação de cupões

- [s] O ecrã de cupões abre sem erros.  
- [n] Criar um cupão simples:
  - [n] Tipo de desconto (cent/l ou %) está correto na lista.  
  - [n] Data de validade (se preenchida) está correta no formato esperado.  
  - [na] Limite de utilizações (se existir) é apresentado corretamente.  

### 7.2. Utilização em abastecimento

- [ ] Ao criar um abastecimento, o cupão aparece na lista de cupões disponíveis.  
- [ ] Ao confirmar o abastecimento, nenhum erro é lançado.  
- [ ] Voltar à lista de cupões:
  - [ ] O cupão reflete o novo número de utilizações ou estado (se atingiu limite).  

### 7.3. Retenção e preferências

- [i] No Perfil, existe a secção “Cupões” com:
  - [i] Dropdown “Cupões expirados” com 3 meses, 6 meses, 1 ano.  
  - [i] Dropdown “Cupões utilizados” com 3 meses, 6 meses, 1 ano.  
- [s] Mudar as duas opções e clicar “Guardar”:
  - [s] Snackbar de “Preferências de cupões guardadas.” aparece.  
  - [s] Ao voltar ao Perfil, as opções mantêm‑se.  
- [na] Se tiveres dados antigos em staging:
  - [na] Abrir o ecrã de cupões não mostra lista vazia “suspeita” por limpeza excessiva.  
  - [i] Não há erros ao listar cupões.  

---

## 8. Notícias de combustível

- [n] O ecrã de notícias abre sem erros (mesmo com rede lenta).  
- [s] Com rede normal:
  - [s] Lista de notícias aparece, sem layouts partidos.  
- [i] Com rede desligada:
  - [n] Mostra mensagem amigável de erro/estado offline.  
  - [s] A app não crasha, nem fica presa em loading infinito.  

---

## 9. Navegação geral e back button

- [s] Navegar: Dashboard → Postos → Cupões → Perfil → Veículos → Perfil → Dashboard sem crashes.  
- [i] Botão back do sistema:
  - [s] Em ecrãs internos volta ao ecrã anterior, não fecha a app abruptamente.  
  - [n] No ecrã raiz (dashboard) o back fecha a app de forma previsível (ou mostra confirmação, consoante o que definiste).  
- [s] Não há “loops” de navegação nem situações em que ficas preso num ecrã sem forma de sair.  

---

## 10. Logout, guest e retorno ao login

- [s] No Perfil, carregar em “Terminar sessão”:
  - [s] Diálogo de confirmação aparece com texto claro.  
  - [s] Ao confirmar, a app volta ao ecrã de autenticação.  
- [s] Depois de logout, o botão back não leva de volta a uma área autenticada.  
- [s] Novo login funciona e carrega a dashboard sem erros.  
- [s] Logout em modo convidado:
  - [s] Comportamento consistente (volta à AuthPage ou fluxo definido).  

---

## 11. Eliminação de conta (frontend + Edge Function)

- [ ] No Perfil, a ação de “Eliminar conta” está visível mas não demasiado “fácil” de clicar por engano (botão, cor, copy).  
- [s] Clicar “Eliminar conta”:
  - [i] Mostra diálogo claro a explicar que dados serão apagados.  
- [i] Ao confirmar:
  - [i] A app mostra um loader enquanto chama a Edge Function.  
  - [s] Não é possível clicar múltiplas vezes (botão desativado).  
- [s] Em sucesso:
  - [s] Dados do utilizador deixam de aparecer (perfil, veículos, abastecimentos, cupões).  
  - [s] A app faz logout local e volta à AuthPage.  
- [na] Em caso de erro na função:
  - [na] Mostra mensagem adequada (“Não foi possível eliminar a conta. Tenta novamente mais tarde.”).  
  - [s] O utilizador não fica num estado “meio apagado”.  

---

## 12. Testes rápidos de robustez e UX

- [s] Inputs:
  - [s] Mensagens de erro aparecem junto ao campo certo (email inválido, campos obrigatórios vazios).  
  - [s] Não é possível submeter formulários com campos obrigatórios vazios.  
- [s] Loaders:
  - [s] Não há spinners que nunca desaparecem (auth, chamadas à Edge Function, carregamento de listas).  
- [i] Textos/branding:
  - [s] Não restam strings “PocketFuel”/nomes antigos na UI principal.  
  - [i] Logo e nomes “Fuel Pit” / “Pocket Pit Apps” aparecem consistentes (splash, AuthPage, Perfil).  
- [i] A app comportamento bem com:
  - [n] Rotação de ecrã (se suportada).  
  - [s] Alteração de tema (claro/escuro) a meio de fluxos importantes.  

---

## 13. Extra (quando tiveres mais tempo)

- [ ] Testar em mais do que um dispositivo/tamanho de ecrã (pelo menos um telefone pequeno e um maior).  
- [ ] Testar deep link de confirmação de email a partir de:
  - [ ] App fechada.  
  - [ ] App em segundo plano.  
  - [ ] Sessão já autenticada.  
- [ ] Simular rede lenta/instável e verificar:
  - [ ] Listas com placeholders ou mensagens adequadas.  
  - [ ] Nenhuma operação crítica (auth, delete account) fica “pendurada” sem feedback.  