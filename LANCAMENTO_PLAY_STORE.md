# ONDAKA — Dossier de lançamento Play Store

**App:** ONDAKA · **Package:** `ao.ondaka.ondaka_app` · **Versão:** 1.0.0 (versionCode 1)
**AAB:** `build/app/outputs/bundle/release/app-release.aab` (assinado com upload key `~/ondaka-upload-keystore.jks`)
**Privacidade:** https://ondaka.ao/privacidade · **Termos:** https://ondaka.ao/termos

---

## 0. Pré-requisitos (confirmar antes)
- [ ] **Conta Google Play Developer** ativa (taxa única $25). Sem isto não há submissão.
- [ ] **Política de Privacidade cobre a LOCALIZAÇÃO** (adicionámos GPS no SOS). Confirmar que ondaka.ao/privacidade menciona recolha de localização — senão a Play rejeita o Data Safety.
- [ ] Decidir conta de testes a dar à Google (ver §4).

> ⚠️ **Regra dos testers:** contas Developer **pessoais novas** (criadas depois de Nov/2023) exigem **12 testers em closed testing durante 14 dias** antes de poder publicar em **produção**. Closed testing pode arrancar já segunda; a **produção** pode ficar gated por esses 14 dias. Contas de **organização** não têm esta regra. → confirmar o tipo da tua conta.

---

## 1. Store listing (PT-PT — pronto a colar)

**Nome da app (≤30):** `ONDAKA — Gestão de Condomínios`

**Descrição curta (≤80):**
`Gestão de condomínios: taxas, avisos, assembleias, visitantes e pedidos.`

**Descrição completa (≤4000):**
```
O ONDAKA é a aplicação de gestão de condomínios em Angola, para gestores e condóminos.

PARA O CONDÓMINO
• Consultar e pagar as Taxas de Condomínio (Multicaixa Express / ProxyPay)
• Receber avisos do condomínio com notificações
• Pré-aprovar visitas com código e QR Code para a portaria
• Participar em assembleias e votar nos pontos da ordem do dia
• Abrir Pedidos de Intervenção com fotos e acompanhar o estado
• Alerta SOS de emergência com localização
• Consultar o extracto, acordos de pagamento e o marketplace do condomínio

PARA O GESTOR / PORTARIA
• Gerir assembleias, avisos, pedidos e encomendas
• Validar visitantes por código ou leitura de QR Code
• Ver quem está dentro do condomínio em tempo real

Compatível com a plataforma web ONDAKA (ondaka.ao). Suporte em português (Angola).
```

**Categoria:** Empresarial (Business) · **Tags:** condomínio, gestão, imobiliário
**Email de contacto:** (o teu) · **Website:** https://ondaka.ao
**Política de privacidade:** https://ondaka.ao/privacidade

---

## 2. Recursos gráficos
- **Ícone:** 512×512 PNG (usar o logo ONDAKA — já temos em alta resolução).
- **Feature graphic:** 1024×500 PNG (banner — **falta criar**; posso ajudar com o texto/conceito).
- **Screenshots de telemóvel:** 2 a 8, mín. 320px lado menor. → eu posso capturar do telemóvel/emulador via adb (Dashboard, Taxas, Avisos, Assembleia/voto, SOS, Visitantes+QR).

---

## 3. Data Safety (formulário de segurança de dados)
Responder "Sim, a app recolhe/partilha dados". **Encriptado em trânsito: Sim.** **Permite pedir eliminação: Sim** (a app tem "Apagar conta" no perfil; `DELETE /me/conta`).

| Tipo de dado | Recolhido | Partilhado | Finalidade | Obrigatório? |
|---|---|---|---|---|
| **Localização aproximada e precisa** | Sim | Não | Funcionalidade do app (alerta SOS) | Opcional (só no SOS) |
| **Nome** | Sim | Não | Gestão de conta, funcionalidade | Obrigatório |
| **Email** | Sim | Não | Gestão de conta | Obrigatório |
| **Telefone** | Sim | Não | Gestão de conta, SMS/2FA | Obrigatório |
| **Fotos** | Sim | Não | Funcionalidade (pedidos, SOS, visitas, marketplace) | Opcional |
| **IDs do dispositivo** (token FCM) | Sim | Não | Notificações push | Obrigatório |
| **Atividade na app** | Sim | Não | Funcionalidade | Opcional |

> Não recolhemos dados de pagamento (cartões) — o pagamento é processado externamente (Multicaixa Express/ProxyPay).

---

## 4. App access (acesso para a revisão Google)
A app exige login → fornecer credenciais de teste à Google:
- **Condómino:** `testecondomino@ondaka.ao` / (password)
- **Gestor:** `testegestor@ondaka.ao` / (password)
Instruções: "Iniciar sessão com as credenciais. Condómino vê taxas/avisos/assembleias/visitantes; gestor gere o condomínio."

---

## 5. Classificação de conteúdo (IARC)
Responder ao questionário como **app empresarial/utilitária**: sem violência, sem conteúdo sexual, sem jogo a dinheiro real. Resultado esperado: **Everyone / 3+** (ou PEGI 3). O marketplace é interno e moderado.

---

## 6. Target audience
Faixa etária: **adultos / 18+** (app de gestão, não dirigida a crianças). Não conteúdo para crianças.

---

## 7. Passo-a-passo na Play Console
1. **Criar app** → nome ONDAKA, PT-PT, App, Gratuita.
2. **Closed testing** → criar faixa "Teste fechado" → adicionar lista de **testers** (emails) → fazer **upload do AAB** (`app-release.aab`).
3. Ativar **Play App Signing** (Google guarda a chave; a tua `.jks` é a upload key).
4. Preencher **Store listing** (§1) + **gráficos** (§2).
5. **Data Safety** (§3), **App access** (§4), **Content rating** (§5), **Target audience** (§6), **App content** (anúncios: Não; etc.).
6. Enviar a faixa de closed testing para revisão.
7. (Para produção) cumprir a regra dos 12 testers/14 dias se aplicável, depois promover a produção.
