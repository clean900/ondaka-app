# ONDAKA — Passo-a-passo Play Console (closed testing → revisão)

App: **ONDAKA — Gestão de Condomínios** · package `ao.ondaka.ondaka_app`
AAB: `build/app/outputs/bundle/release/app-release.aab` (já carregado ✅)
URLs úteis (substitui o id da app se mudar): app id atual = `4973514794159538155`

> Regra geral: cada ecrã tem um botão **Save** no fundo. Guarda sempre antes de sair.

---

## PARTE A — App content (resolve os 5 erros)
Abre: **App content** (menu "Policy" ou URL `.../app/4973514794159538155/app-content`).
Vais ver uma lista de declarações. Faz por esta ordem:

### A1. Privacy policy
1. Clica **Privacy policy** → **Manage**.
2. Cola: `https://ondaka.ao/privacidade`
3. **Save**.

### A2. App access
1. Clica **App access**.
2. Escolhe **"All or some functionality is restricted"**.
3. **Add new instructions** (botão) — cria **2**:
   - **Condómino** · username `testecondomino@ondaka.ao` · password `(a tua)` · instruções: *"Login com email+password. Acesso a taxas, avisos, assembleias, visitantes (QR) e pedidos."*
   - **Gestor** · username `testegestor@ondaka.ao` · password `(a tua)` · instruções: *"Perfil de gestão: assembleias, avisos, pedidos, encomendas e portaria."*
4. **Save**.

### A3. Ads
1. Clica **Ads**.
2. **"No, my app does not contain ads"**.
3. **Save**.

### A4. Content ratings
1. Clica **Content ratings** → **Start questionnaire**.
2. **Email**: o teu email · **Category**: escolhe **"Utility, Productivity, Communication, or Other"**.
3. Responde **No / Não** a TUDO (violência, sexo, linguagem, drogas, jogo a dinheiro, medo, etc.).
4. Pergunta sobre partilha de localização / interação entre utilizadores: responde conforme — a app **partilha localização do utilizador com outros?** Não (a localização vai para o gestor/portaria, não é partilha pública). Interação entre utilizadores: **Sim** (marketplace/comunidade moderada) — se perguntar.
5. **Save** → submete → obténs a classificação (esperado: PEGI 3 / Everyone).

### A5. Target audience and content
1. Clica **Target audience and content**.
2. Faixas etárias: marca **apenas 18 e mais** (não dirigida a menores).
3. **"Appealing to children?"** → **No**.
4. **Save**.

### A6. Data safety  ← a mais demorada (detalhe na PARTE D)
Segue a PARTE D abaixo.

### A7. As declarações "Não" (rápidas)
- **News apps** → No.
- **COVID-19 apps** → No.
- **Government apps** → No.
- **Financial features** → **No** (pagamentos são via Multicaixa/ProxyPay externo; a app não processa instrumentos financeiros).
- **Health apps** → No.
Cada uma: seleciona "No" → **Save**.

---

## PARTE B — Store listing (página da loja)
Abre: **Grow → Store presence → Main store listing** (ou Dashboard → "Set up your app").

1. **App name:** `ONDAKA — Gestão de Condomínios`
2. **Short description:** `Gestão de condomínios: taxas, avisos, assembleias, visitantes e pedidos.`
3. **Full description:** (copia do `LANCAMENTO_PLAY_STORE.md`, secção 1)
4. **App icon:** PNG 512×512 (logo ONDAKA).
5. **Feature graphic:** PNG 1024×500 (banner — falta criar).
6. **Phone screenshots:** carrega os 8 de `play-store-screenshots/`.
7. **Save**.

E em **Store settings**:
- **App category:** `Business` (e confirma **App or game = App**).
- **Email de contacto** + telefone (opcional).
- **Save**.

---

## PARTE C — Closed testing (testers + rollout)
Abre: **Test and release → Testing → Closed testing → Manage track** (Alpha).

1. Separador **Testers** → **Create email list** → nome "Testers ONDAKA" → cola os **emails Gmail** dos testers → **Save**.
2. Marca essa lista como ativa na track.
3. (Opcional) Separador **Countries/regions** → adiciona **Angola** (e outros que queiras).
4. Volta a **Releases** → o teu release "1 (1.0.0)" → **Edit/Review** → quando os 5 erros estiverem resolvidos, o botão **Save** desbloqueia → **Save** → **Review release** → **Start rollout to Closed testing** → **Confirm**.

A app entra em **revisão da Google** (1–3 dias na 1ª vez). Os testers recebem o link de opt-in depois de aprovada.

---

## PARTE D — Data safety (detalhe)
Abre: **App content → Data safety** → **Next**.

**Ecrã "Data collection and security":**
- Does your app collect or share any of the required user data types? → **Yes**.
- Is all of the user data encrypted in transit? → **Yes**.
- Do you provide a way for users to request that their data is deleted? → **Yes** (a app tem "Apagar conta").
→ **Next**.

**Ecrã "Data types":** marca estes e nada mais:
- **Location:** Approximate location, Precise location
- **Personal info:** Name, Email address, Phone number, User IDs
- **Photos and videos:** Photos
- **App activity:** App interactions
- **Device or other IDs:** Device or other IDs
→ **Next**.

**Para CADA tipo marcado**, responde:
- Collected? **Yes** · Shared? **No**
- Processed ephemerally? **No** (é guardado no servidor)
- Required or optional?
  - Location, Photos, App interactions → **Optional** ("Users can choose…")
  - Name, Email, Phone, User IDs, Device IDs → **Required**
- Purpose (marca conforme):
  - Location → **App functionality**
  - Name/Email/Phone/User IDs → **App functionality, Account management**
  - Photos → **App functionality**
  - App interactions → **App functionality, Analytics**
  - Device IDs → **App functionality** (notificações push)
→ **Save** cada um → no fim **Next** → **Save** o formulário.

---

## Resumo do que falta (humano)
- [ ] A1–A7 (App content) — respostas todas acima
- [ ] B (Store listing) — textos prontos; **feature graphic falta criar**
- [ ] C (testers Gmail + rollout)
- [ ] Passwords das contas `testecondomino@` / `testegestor@` (tu)
</content>
