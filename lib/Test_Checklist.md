# FuelPit – Smoke Test (rápido)

legenda:
    s - funcional
    n - não funcional
    i - incompleto

## 1. Arranque e login
- [s] A app abre sem crash.
- [i] Login funciona.
- [s] Dashboard aparece sem erros.

    1. resolver criar conta, erro ao clicar criar

    2. resolver entrar sem conta
        -entrar sem ver certas abas como perfil, cupoes historico, e dar informação para ter essas informaçoes precisa registar

## 2. Perfil
- [s] Perfil abre sem erros.
- [s] Tema escuro alterna e mantém-se após fechar/reabrir.

    1.  ver o que fazer na página privacidade e segurança

## 3. Veículos
- [s] Adicionar um veículo funciona.
- [s] Definir veículo principal funciona.

## 4. Cupões
- [s] Criar um cupão funciona.
- [i] Usar um cupão num abastecimento funciona.
- [s] Cupões expirados aparecem como expirados.

    1. melhorar a introdução do cupão no abastecimento pois so devem aparecer no dropdown os compativeis com o posto e caso não tenha cupoes disponiveis dizer sem cupões aplicáveis

    2. melhorar formulário de novo abastecimento
        -posto dropdown de postos existentes com possibilidade de inserir manualmente caso não exista e o dropdown deve conter favoritos primeiro, e depois ordenados por alfabeto ou marca do posto e alfabeto

## 5. Retenção de cupões
- [s] Preferências de retenção aparecem no Perfil.
- [s] Guardar preferências de retenção funciona.

## 6. Navegação
- [s] Dashboard → Postos → Cupões → Perfil → Veículos funciona.
- [s] Logout funciona e vai para login.