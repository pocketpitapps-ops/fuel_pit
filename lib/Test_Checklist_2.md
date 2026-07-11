# FuelPit – Smoke Test (completo)

Objetivo: Em 10–20 minutos, garantir que as funcionalidades críticas não estão partidas antes de um release.

---

## 1. Arranque, autenticação e sessão

- [ ] A app instala e arranca sem crash.
- [ ] O ecrã de autenticação aparece corretamente.
- [ ] Login com utilizador de teste funciona.
- [ ] Após login, a dashboard inicial aparece sem erros.
- [ ] Fechar e reabrir a app mantém a sessão do utilizador (continua autenticado).

---

## 2. Perfil, tema e preferências principais

- [ ] O ecrã Perfil abre sem erros a partir da navegação principal.
- [ ] O cabeçalho mostra nome e email corretos.
- [ ] Alterar a moeda (por exemplo de EUR para USD) e guardar:
  - [ ] Ao voltar imediatamente ao Perfil, a moeda está correta.
  - [ ] Reiniciar a app mantém a moeda escolhida.
- [ ] Alterar o modo de abastecimento padrão (por valor ↔ por litros) e o valor:
  - [ ] Guardar mostra snackbar de sucesso.
  - [ ] Ao voltar ao Perfil, o modo e o valor mantêm-se.
- [ ] Alternar “Tema escuro”:
  - [ ] O tema muda imediatamente.
  - [ ] Fechar e reabrir a app mantém o tema escolhido.

---

## 3. Veículos (fluxo mínimo)

- [ ] Abrir o ecrã Veículos não provoca erros.
- [ ] Adicionar um novo veículo:
  - [ ] O veículo aparece na lista após gravar.
- [ ] Definir esse veículo como principal:
  - [ ] O veículo principal aparece no topo da lista de veículos.
  - [ ] No Perfil, o “Veículo principal” mostrado corresponde ao que definiste.
- [ ] Apagar um veículo:
  - [ ] O veículo desaparece da lista.
  - [ ] Um snackbar de confirmação é mostrado.

---

## 4. Cupões (criação e utilização)

- [ ] O ecrã de cupões abre sem erros.
- [ ] Criar um cupão simples:
  - [ ] Tipo de desconto (ex.: cent/l ou %) está correto na lista.
  - [ ] Data de validade (se preenchida) está correta.
- [ ] Usar esse cupão num abastecimento:
  - [ ] O cupão aparece na lista de cupões disponíveis na criação de abastecimento.
  - [ ] Ao confirmar o abastecimento, não há erro.
  - [ ] Voltar à lista de cupões:
    - [ ] O cupão reflete o novo número de utilizações ou estado (se atingiu limite).

---

## 5. Retenção de cupões (verificação rápida)

- [ ] No Perfil, existe a secção “Cupões” com:
  - [ ] Dropdown “Cupões expirados” com 3 meses, 6 meses, 1 ano.
  - [ ] Dropdown “Cupões utilizados” com 3 meses, 6 meses, 1 ano.
- [ ] Mudar as duas opções e clicar “Guardar”:
  - [ ] Snackbar de “Preferências de cupões guardadas.” aparece.
  - [ ] Ao voltar ao Perfil, as opções mantêm-se.
- [ ] (Se tiveres dados antigos em staging) Abrir o ecrã de cupões:
  - [ ] A lista não está vazia de forma suspeita (nenhuma limpeza exagerada).
  - [ ] Não há erros ao listar cupões.

---

## 6. Navegação geral

- [ ] Navegar: Dashboard → Postos → Cupões → Perfil → Veículos → Perfil → Dashboard sem crashes.
- [ ] Botão back do sistema funciona de forma previsível (não fecha a app inesperadamente em ecrãs internos).
- [ ] A app não fica “presa” em nenhum ecrã (tens sempre forma de voltar).

---

## 7. Logout e retorno ao login

- [ ] No Perfil, carregar em “Terminar sessão”:
  - [ ] O diálogo de confirmação aparece.
  - [ ] Ao confirmar, a app volta ao ecrã de autenticação.
- [ ] Depois de logout, o botão back não leva de volta a uma área autenticada.
- [ ] Novo login funciona novamente e carrega a dashboard sem erros.

---