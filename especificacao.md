# Especificação da API - Memento: Testes Cognitivos Digitais

## 1. Tecnologias e Autenticação

* **Backend as a Service (BaaS):** Supabase (PostgreSQL + Supabase Auth + Row Level Security).
* **Autenticação:** JSON Web Tokens (JWT) via Supabase Auth. O JWT deve ser enviado no header `Authorization: Bearer {token}` para todos os endpoints protegidos.
* **Deep Links:** Utiliza o esquema `io.supabase.memento://` para:
  - Confirmação de acesso médico-paciente
  - Recuperação de senha
* **Email Service:** SMTP via Gmail (`smtp.gmail.com:587`) para envio de emails de confirmação, boas-vindas e recuperação de senha.
* **Deep Link Redirect:** Cloudflare Worker (`memento-deeplink-redirect.victoralc887.workers.dev`) converte links web em deep links mobile.

---

## 2. Estrutura do Banco de Dados

### 2.1. Tabelas Principais

| Tabela | PK | Tipo PK | FKs | Descrição |
| :--- | :--- | :--- | :--- | :--- |
| **`users`** | `id` | UUID | `auth.users(id)` | Dados básicos de usuários (nome, email, data de nascimento). Complementa a tabela de Auth do Supabase. |
| **`patients`** | `id` | SERIAL (INT) | `user_id` → `users(id)` | Registro de pacientes. Cada paciente tem um `id` numérico interno e uma referência ao `user_id` UUID. |
| **`doctors`** | `id` | SERIAL (INT) | `user_id` → `users(id)` | Registro de médicos com CRM. Cada médico tem um `id` numérico interno e uma referência ao `user_id` UUID. |
| **`tests`** | `id` | SERIAL (INT) | N/A | Tipos de testes cognitivos disponíveis (Stroop, TMT A, TMT B, Memória Verbal). |
| **`patient_tests`** | `id` | SERIAL (INT) | `patient_id` → `patients(id)`,<br>`test_id` → `tests(id)`,<br>`doctor_id` → `auth.users(id)` | Resultados de testes realizados. Armazena pontuação, tempos e qual médico aplicou (se houver).|
| **`doctor_access`** | `id` | SERIAL (INT) | `doctor_id` → `doctors(id)`,<br>`patient_id` → `patients(id)` | Controla a vinculação e confirmação de acesso entre médico e paciente. |

### 2.2. Detalhamento das Tabelas

**Para a estrutura SQL completa das tabelas (DDL, triggers, RLS policies), consulte o arquivo [`supabase.md`](./supabase.md).**

**Resumo das Regras de Negócio:**

- **`users`**: Complementa `auth.users` com nome e data de nascimento
- **`patients`**: ID numérico (SERIAL) + referência ao `user_id` (UUID)
- **`doctors`**: ID numérico (SERIAL) + referência ao `user_id` (UUID) + CRM
- **`tests`**: Tipos de testes disponíveis
  - `id = 1`: **Stroop Test** (50 itens)
  - `id = 2`: **Trail Making Test** (TMT A/B)
  - `id = 3`: **Teste de Memória Verbal** (20 palavras)
- **`patient_tests`**: Armazena resultados (`score`, `time_spent`, `average_time`)
  - `doctor_id` (UUID) é `NULL` quando paciente faz sozinho
  - `doctor_id` preenchido com UUID do médico (`auth.users.id`) quando médico aplica o teste
- **`doctor_access`**: Controla vinculação médico-paciente
  - `confirmed = false` até confirmação via link
  - Token expira em 7 dias

---

## 3. Funções RPC (Remote Procedure Calls)

O sistema utiliza 4 funções PostgreSQL customizadas chamadas via RPC:

### 3.1. `search_user_by_email`
Busca um usuário existente pelo email para vinculação médico-paciente.

**Parâmetros:**
```json
{
  "user_email": "paciente@email.com"
}
```

**Retorno:**
```json
[{
  "id": "uuid-do-usuario",
  "name": "Nome do Paciente",
  "email": "paciente@email.com",
  "birth_date": "1990-05-15"
}]
```

### 3.2. `get_doctor_patients`
Retorna todos os pacientes vinculados a um médico (confirmados ou pendentes).

**Parâmetros:**
```json
{
  "doctor_user_id": "uuid-do-medico"
}
```

**Retorno:**
```json
[{
  "patient_id": 42,
  "user_id": "uuid-do-paciente",
  "name": "João Silva",
  "email": "joao@email.com",
  "birth_date": "1945-10-25",
  "confirmed": true,
  "confirmation_token": "a1b2c3...",
  "token_expires_at": "2025-12-01T23:59:59Z"
}]
```

### 3.3. `confirm_patient_access`
Confirma que o paciente autoriza o médico a acessar seus dados.

**Parâmetros:**
```json
{
  "token": "confirmation-token-here"
}
```

**Retorno:**
```json
true  // ou false se o token for inválido/expirado
```

**Efeitos:**
- Define `confirmed = true` na tabela `doctor_access`
- Define `confirmed_at = NOW()`
- Libera o acesso do médico aos dados do paciente

### 3.4. `delete_user_account`
Remove completamente a conta do usuário e todos os dados relacionados.

**Parâmetros:** Nenhum (usa o usuário autenticado do JWT)

**Retorno:**
```json
{
  "success": true
}
```

**Efeitos Cascata:**
- Remove registro de `users`
- Remove registro de `patients` ou `doctors`
- Remove resultados em `patient_tests`
- Remove vínculos em `doctor_access`
- Remove conta do Supabase Auth

---

## 4. Endpoints da API

### 4.1. Autenticação (Supabase Auth)

#### **POST** `/auth/v1/signup` - Registro de Novo Usuário
**Acesso:** Público

**Body:**
```json
{
  "email": "novo@email.com",
  "password": "senha_segura",
  "data": {
    "name": "Nome Completo",
    "birth_date": "1990-01-15"
  }
}
```

**Resposta (201 Created):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "email": "novo@email.com",
    "user_metadata": {
      "name": "Nome Completo",
      "birth_date": "1990-01-15"
    }
  }
}
```

**Nota:** O sistema cria automaticamente um registro em `users` e `patients` via trigger do banco.

---

#### **POST** `/auth/v1/token?grant_type=password` - Login
**Acesso:** Público

**Body:**
```json
{
  "email": "usuario@email.com",
  "password": "senha123"
}
```

**Nota:** No SDK Flutter, use `supabase.auth.signInWithPassword(email: email, password: password)`

**Resposta (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "email": "usuario@email.com",
    "user_metadata": { ... }
  }
}
```

---

#### **POST** `/auth/v1/recover` - Recuperar Senha
**Acesso:** Público

**Body:**
```json
{
  "email": "usuario@email.com"
}
```

**Nota:** No SDK Flutter, use `supabase.auth.resetPasswordForEmail(email, redirectTo: 'io.supabase.memento://reset-password')`

**Resposta (200 OK):**
```json
{}
```

**Efeito:** Envia email com deep link `io.supabase.memento://reset-password#access_token={token}` para redefinir senha.

---

#### **PUT** `/auth/v1/user` - Atualizar Email ou Senha
**Acesso:** Usuário Autenticado  
**Header:** `Authorization: Bearer {token}`

**Body (alterar email):**
```json
{
  "email": "novo@email.com"
}
```

**Body (alterar senha):**
```json
{
  "password": "nova_senha_123"
}
```

**Resposta (200 OK):**
```json
{
  "user": { ... }
}
```

---

#### **POST** `/auth/v1/logout` - Logout
**Acesso:** Usuário Autenticado  
**Header:** `Authorization: Bearer {token}`

**Resposta (204 No Content)**

---

### 4.2. Gerenciamento de Usuários

#### **GET** `/rest/v1/users?id=eq.{user_id}` - Obter Dados do Usuário
**Acesso:** Usuário Autenticado  
**Header:** `Authorization: Bearer {token}`

**Resposta (200 OK):**
```json
{
  "id": "uuid",
  "name": "Nome do Usuário",
  "birth_date": "1990-01-15",
  "created_at": "2025-01-01T00:00:00Z"
}
```

---

#### **PATCH** `/rest/v1/users?id=eq.{user_id}` - Atualizar Dados do Usuário
**Acesso:** Usuário Autenticado  
**Header:** `Authorization: Bearer {token}`

**Body:**
```json
{
  "name": "Nome Atualizado",
  "birth_date": "1990-01-15"
}
```

**Resposta (200 OK):**
```json
{
  "id": "uuid",
  "name": "Nome Atualizado",
  "birth_date": "1990-01-15"
}
```

---

#### **POST** `/rest/v1/rpc/delete_user_account` - Deletar Conta
**Acesso:** Usuário Autenticado  
**Header:** `Authorization: Bearer {token}`

**Resposta (200 OK):**
```json
{
  "success": true
}
```

---

### 4.3. Gerenciamento de Pacientes (Médico)

#### **POST** `/rest/v1/rpc/search_user_by_email` - Buscar Paciente por Email
**Acesso:** Médico Autenticado  
**Header:** `Authorization: Bearer {token}`

**Body:**
```json
{
  "user_email": "paciente@email.com"
}
```

**Resposta (200 OK):**
```json
[{
  "id": "uuid",
  "name": "Nome do Paciente",
  "email": "paciente@email.com",
  "birth_date": "1945-10-25"
}]
```

**Retorna array vazio `[]` se não encontrar.**

---

#### **POST** `/auth/v1/signup` + `/rest/v1/doctor_access` - Criar Novo Paciente
**Acesso:** Médico Autenticado  
**Header:** `Authorization: Bearer {token}`

**Fluxo:**
1. Médico cria o paciente via `signUp` com senha = CPF (ou padrão)
2. Sistema envia email de boas-vindas com senha temporária
3. Sistema cria registro em `doctor_access` com token de confirmação
4. Sistema envia email de confirmação com deep link

**Body (SignUp):**
```json
{
  "email": "novo.paciente@email.com",
  "password": "12345678", // CPF sem formatação ou senha padrão
  "data": {
    "name": "José Silva",
    "birth_date": "1940-03-20"
  }
}
```

---

#### **POST** `/rest/v1/rpc/get_doctor_patients` - Listar Pacientes do Médico
**Acesso:** Médico Autenticado  
**Header:** `Authorization: Bearer {token}`

**Body:**
```json
{
  "doctor_user_id": "uuid-do-medico"
}
```

**Resposta (200 OK):**
```json
[
  {
    "patient_id": 42,
    "user_id": "uuid",
    "name": "João Silva",
    "email": "joao@email.com",
    "birth_date": "1945-10-25",
    "confirmed": true,
    "confirmation_token": null,
    "token_expires_at": null
  },
  {
    "patient_id": 43,
    "user_id": "uuid2",
    "name": "Maria Santos",
    "email": "maria@email.com",
    "birth_date": "1950-05-15",
    "confirmed": false,
    "confirmation_token": "a1b2c3...",
    "token_expires_at": "2025-12-01T23:59:59Z"
  }
]
```

---

### 4.4. Vinculação Médico-Paciente

#### **POST** `/rest/v1/doctor_access` - Solicitar Acesso a Paciente
**Acesso:** Médico Autenticado  
**Header:** `Authorization: Bearer {token}`

**Body:**
```json
{
  "doctor_id": 5,
  "patient_id": 42,
  "confirmed": false,
  "confirmation_token": "abc123def456...",
  "token_expires_at": "2025-12-01T23:59:59Z"
}
```

**Resposta (201 Created):**
```json
{
  "id": 10,
  "doctor_id": 5,
  "patient_id": 42,
  "confirmed": false,
  "confirmation_token": "abc123def456..."
}
```

**Efeito:** Sistema envia email para paciente com link via Cloudflare Worker:  
`https://memento-deeplink-redirect.victoralc887.workers.dev/?token=abc123def456...`

O worker redireciona para: `io.supabase.memento://confirm?token=abc123def456...`

---

#### **POST** `/rest/v1/rpc/confirm_patient_access` - Confirmar Acesso
**Acesso:** Público (via token no deep link)

**Body:**
```json
{
  "token": "abc123def456..."
}
```

**Resposta (200 OK):**
```json
true
```

**Efeito:** Define `confirmed = true` e `confirmed_at = NOW()` em `doctor_access`.

---

### 4.5. Resultados de Testes

#### **POST** `/rest/v1/patient_tests` - Salvar Resultado de Teste
**Acesso:** Paciente ou Médico Autenticado  
**Header:** `Authorization: Bearer {token}`

**Body (Paciente fazendo sozinho):**
```json
{
  "patient_id": 42,
  "test_id": 1,
  "score": 45,
  "time_spent": 55200,
  "average_time": 1104,
  "test_date": "2025-11-24T14:30:00Z",
  "doctor_id": null
}
```

**Body (Médico aplicando para paciente):**
```json
{
  "patient_id": 42,
  "doctor_id": "uuid-do-medico",
  "test_id": 3,
  "score": 18,
  "time_spent": 120000,
  "average_time": 6000,
  "test_date": "2025-11-24T14:30:00Z"
}
```

**Nota:** `doctor_id` deve ser o UUID do usuário (`auth.users.id`), obtido via `supabase.auth.currentUser.id`.

**Resposta (201 Created):**
```json
{
  "id": 1001,
  "patient_id": 42,
  "doctor_id": "uuid-do-medico",
  "test_id": 3,
  "score": 18,
  "time_spent": 120000,
  "test_date": "2025-11-24T14:30:00Z"
}
```

---

#### **GET** `/rest/v1/patient_tests?patient_id=eq.{id}&select=id,patient_id,test_id,score,time_spent,test_date,average_time,tests!inner(name)` - Listar Resultados
**Acesso:** Paciente ou Médico Autorizado  
**Header:** `Authorization: Bearer {token}`

**Query Parameters:**
- `patient_id=eq.42` (obrigatório)
- `test_id=eq.1` (opcional - filtrar por tipo de teste)
- `test_date=gte.2025-01-01` (opcional - data início)
- `test_date=lt.2025-12-31` (opcional - data fim)
- `order=test_date.desc` (opcional - ordenação)

**Nota:** O `!inner` força um INNER JOIN, garantindo que apenas testes com dados válidos sejam retornados.

**Resposta (200 OK):**
```json
[
  {
    "id": 1001,
    "patient_id": 42,
    "doctor_id": "uuid-do-medico",
    "test_id": 1,
    "score": 45,
    "time_spent": 55200,
    "average_time": 1104,
    "test_date": "2025-11-24T14:30:00Z",
    "tests": {
      "name": "Stroop Test"
    }
  },
  {
    "id": 1002,
    "patient_id": 42,
    "doctor_id": null,
    "test_id": 3,
    "score": 18,
    "time_spent": 120000,
    "average_time": 6000,
    "test_date": "2025-11-23T10:15:00Z",
    "tests": {
      "name": "Teste de Memória Verbal"
    }
  }
]
```

---

#### **GET** `/rest/v1/tests` - Listar Tipos de Testes
**Acesso:** Usuário Autenticado  
**Header:** `Authorization: Bearer {token}`

**Resposta (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Stroop Test",
    "description": "Teste de interferência cores-palavras"
  },
  {
    "id": 2,
    "name": "Trail Making Test",
    "description": "Teste de trilhas numéricas e alfanuméricas"
  },
  {
    "id": 3,
    "name": "Teste de Memória Verbal",
    "description": "Recordação de lista de palavras"
  }
]
```

---

## 5. Regras de Negócio

### 5.1. Criação e Vinculação de Pacientes

**Cenário 1: Paciente Novo (criado pelo médico)**
1. Médico preenche: nome, email, data nascimento, CPF (opcional)
2. Sistema gera senha = CPF sem formatação (ou "123456" se não informado)
3. Sistema cria conta via `auth.signUp`
4. Sistema envia **email de boas-vindas** com senha temporária
5. Sistema cria vínculo em `doctor_access` com `confirmed=false`
6. Sistema gera token de 32 caracteres (expira em 7 dias)
7. Sistema envia **email de confirmação** com deep link
8. Paciente clica no link e confirma acesso
9. Sistema define `confirmed=true` liberando o médico

**Cenário 2: Paciente Existente**
1. Médico busca paciente por email via RPC `search_user_by_email`
2. Sistema retorna dados básicos se encontrar
3. Médico solicita vinculação
4. Sistema cria registro em `doctor_access` com `confirmed=false`
5. Sistema envia email de confirmação com deep link
6. Paciente confirma clicando no link
7. Sistema define `confirmed=true`

### 5.2. Realização de Testes

**Teste pelo Paciente (sozinho)**
- Paciente faz login no app
- Escolhe teste na tela inicial
- Realiza o teste
- Sistema salva com `doctor_id = null`
- Sistema navega para tela de resultado

**Teste pelo Médico (para paciente)**
- Médico faz login no app
- Acessa lista de pacientes confirmados
- Clica no paciente → escolhe "Realizar Teste"
- Seleciona tipo de teste
- Paciente realiza teste no celular do médico
- Sistema salva com `patient_id` E `doctor_id` preenchidos
- Sistema navega para tela de resultado
- Botão "Voltar" leva à lista de pacientes (não à home do paciente)

### 5.3. Tipos de Testes e Pontuação

| Test ID | Nome | Itens | Métrica Principal | Tempo |
|---------|------|-------|-------------------|-------|
| 1 | Stroop Test | 50 | Acertos (score) | Tempo médio por item (ms) |
| 2 | Trail Making Test | 25 números | Tempo total (score = tempo) | Erros contados |
| 3 | Memória Verbal | 20 palavras | Acertos (score) | Tempo médio por resposta (ms) |

**Armazenamento:**
- `score`: Pontuação/resultado principal (acertos ou tempo)
- `time_spent`: Tempo total do teste em milissegundos
- `average_time`: Tempo médio por item (quando aplicável)

### 5.4. Permissões de Acesso

**Paciente pode:**
- ✅ Visualizar seus próprios dados e histórico de testes
- ✅ Realizar testes
- ✅ Confirmar acesso de médicos
- ✅ Alterar seus dados cadastrais
- ❌ Não pode ver dados de outros pacientes
- ❌ Não pode acessar funcionalidades de médico

**Médico pode:**
- ✅ Criar novos pacientes
- ✅ Buscar pacientes existentes por email
- ✅ Solicitar acesso a pacientes existentes
- ✅ Visualizar lista de seus pacientes (confirmados e pendentes)
- ✅ Visualizar dados e histórico APENAS de pacientes confirmados (`confirmed=true`)
- ✅ Realizar testes em nome de pacientes confirmados
- ❌ Não pode ver dados de pacientes não confirmados
- ❌ Não pode ver pacientes de outros médicos

**Row Level Security (RLS):**
O Supabase deve ter políticas RLS configuradas para garantir:
- Users só acessam próprio registro
- Patients só acessam próprios testes
- Doctors só acessam testes de pacientes confirmados
- doctor_access protege vínculo entre médico e paciente

### 5.5. Tokens e Expiração

**Confirmation Token:**
- Tamanho: 32 caracteres alfanuméricos
- Validade: 7 dias
- Deep Link: `io.supabase.memento://confirm?token={token}`
- Após confirmação: token é mantido no banco mas não pode ser reusado

**JWT Token:**
- Validade: 1 hora (padrão Supabase)
- Refresh: Automático via `refresh_token`
- Renovação: Cliente deve implementar lógica de refresh

**Reset Password Token:**
- Validade: Configurado no Supabase (geralmente 1 hora)
- Deep Link: `io.supabase.memento://reset-password#access_token={token}`
- One-time use: Token expira após uso

### 5.6. Emails Automáticos

O sistema envia 3 tipos de emails via **SMTP Gmail** (`tadssmtp@gmail.com`):

**Configuração SMTP:**
- Host: `smtp.gmail.com`
- Porta: `587` (STARTTLS)
- Autenticação: Gmail App Password
- Templates: HTML responsivo com estilos inline

**1. Email de Boas-Vindas (Novo Paciente)**
- Enviado quando: Médico cria novo paciente
- Conteúdo: Nome, email, senha temporária
- Ação esperada: Paciente faz login e troca senha

**2. Email de Confirmação de Acesso**
- Enviado quando: Médico solicita acesso a paciente
- Conteúdo: Nome do médico, link de confirmação
- Ação esperada: Paciente clica no link para confirmar

**3. Email de Recuperação de Senha**
- Enviado quando: Usuário clica em "Esqueci minha senha"
- Conteúdo: Link com token para redefinir senha
- Ação esperada: Usuário define nova senha

---

## 6. Códigos de Status HTTP

| Status | Uso |
|--------|-----|
| `200 OK` | Requisição bem-sucedida com retorno de dados |
| `201 Created` | Recurso criado com sucesso (signup, new test, etc) |
| `204 No Content` | Ação bem-sucedida sem retorno (logout, delete) |
| `400 Bad Request` | Dados inválidos ou faltando campos obrigatórios |
| `401 Unauthorized` | Token inválido, expirado ou ausente |
| `403 Forbidden` | Usuário autenticado mas sem permissão para o recurso |
| `404 Not Found` | Recurso não existe (paciente, teste, token, etc) |
| `409 Conflict` | Conflito (ex: email já cadastrado) |
| `500 Internal Server Error` | Erro no servidor |

---

## 7. Exemplos de Fluxos Completos

### 7.1. Médico Adiciona Paciente Novo

```
1. POST /auth/v1/signup
   Body: { email, password: "CPF", data: { name, birth_date } }
   → Cria paciente com senha = CPF

2. Sistema envia Email de Boas-Vindas automaticamente

3. POST /rest/v1/doctor_access
   Body: { doctor_id, patient_id, token, expires_at }
   → Cria vínculo pendente

4. Sistema envia Email de Confirmação automaticamente

5. Paciente abre email → clica no link
   Deep Link: io.supabase.memento://confirm?token=abc123

6. POST /rest/v1/rpc/confirm_patient_access
   Body: { token: "abc123" }
   → Define confirmed=true

7. Médico pode agora ver dados e aplicar testes
```

### 7.2. Paciente Realiza Teste Sozinho

```
1. POST /auth/v1/token?grant_type=password
   Body: { email, password }
   → Login do paciente

2. Paciente navega para "Teste de Memória Verbal"

3. Paciente completa o teste
   - 20 palavras apresentadas
   - Paciente responde sim/não
   - App calcula score e tempos

4. POST /rest/v1/patient_tests
   Body: {
     patient_id: 42,
     test_id: 3,
     score: 18,
     time_spent: 120000,
     average_time: 6000,
     test_date: NOW(),
     doctor_id: null
   }

5. App navega para tela de resultado

6. Paciente clica "Voltar" → vai para home do paciente
```

### 7.3. Médico Aplica Teste para Paciente

```
1. POST /auth/v1/token?grant_type=password
   Body: { email (médico), password }
   → Login do médico

2. POST /rest/v1/rpc/get_doctor_patients
   Body: { doctor_user_id: "uuid-medico" }
   → Lista pacientes

3. Médico clica em paciente → abre dialog
   Opções: [Ver Histórico, Teste Memória, TMT A, Stroop]

4. Médico escolhe "Teste de Memória Verbal"
   → App navega com parâmetros patientId e doctorId

5. Paciente realiza teste no celular do médico

6. POST /rest/v1/patient_tests
   Body: {
     patient_id: 42,
     doctor_id: "uuid-do-medico",
     test_id: 3,
     score: 18,
     time_spent: 120000,
     average_time: 6000,
     test_date: NOW()
   }

7. App navega para tela de resultado

8. Médico clica "Voltar" → vai para lista de pacientes
```

### 7.4. Visualizar Histórico de Paciente

```
1. GET /rest/v1/patient_tests?patient_id=eq.42&select=id,patient_id,test_id,score,time_spent,test_date,average_time,tests!inner(name)&order=test_date.desc
   → Retorna todos os testes do paciente

2. App exibe resultados em cards clicáveis com:
   - Ícone e cor por tipo de teste
   - Nome do teste e data formatada
   - Pontuação e tempo gasto
   - Navegação para detalhes ao clicar

3. Filtros implementados:
   ✅ Por tipo de teste (dropdown: Todos, Stroop, TMT, Memória)
   ✅ Por período (calendário com seleção de range)
   
4. Funcionalidades disponíveis:
   - Paciente: Acessa via "Histórico e Gráficos" na home
   - Médico: Acessa via "Ver Histórico" no dialog do paciente
   - Service tem método getTestResultsByType() para agrupamento
   - Service tem calculateStatistics() para estatísticas (não usado na UI)

5. Roadmap (não implementado):
   - Gráficos de evolução temporal
   - Filtro por testes supervisionados (doctor_id NOT NULL)
   - Visualização de estatísticas (média, melhor, pior)
```

---

## 8. Considerações de Segurança

1. **Senhas Temporárias**: Pacientes criados por médicos recebem senha = CPF.

2. **Tokens de Confirmação**: 
   - Expiram em 7 dias
   - Não podem ser reusados após confirmação
   - São únicos e não previsíveis (32 chars aleatórios)
   - Pode-se criar um novo token de confirmação

3. **Row Level Security**: 
   - Pacientes nunca veem dados de outros pacientes
   - Médicos só veem pacientes onde `confirmed=true` em `doctor_access`
   - Médicos não veem histórico de pacientes não confirmados

4. **JWT Validation**: 
   - Todos endpoints (exceto auth e confirm) exigem token válido
   - Token expira em 1 hora
   - Refresh automático via `refresh_token`

5. **Deep Links**: 
   - Devem validar token antes de processar ação
   - Token expirado retorna erro claro ao usuário
   - App deve tratar cenário de token inválido

---

## 9. Notas de Implementação

### IDs Numéricos vs UUIDs
- `users.id`, `auth.users.id`: **UUID** (gerado pelo Supabase Auth)
- `patients.id`, `doctors.id`, `tests.id`, `patient_tests.id`: **SERIAL (INTEGER)** 
- Motivo: Queries JOIN são mais eficientes com INTs; UUIDs apenas para referência de auth

### Conversão Patient User ID → Patient ID
Ao salvar teste, o app precisa converter:
```sql
SELECT id FROM patients WHERE user_id = '{uuid-from-auth}' LIMIT 1;
```
Resultado é o `patient_id` (INT) usado em `patient_tests`.

### Doctor ID em Patient Tests
**Importante:** Ao salvar resultado de teste aplicado por médico, use diretamente o UUID do auth:
```dart
final doctorUserId = supabase.auth.currentUser!.id; // UUID
```
NÃO é necessário buscar o `doctors.id` (INTEGER). Use o UUID diretamente em `patient_tests.doctor_id`.

**Motivo técnico:** A implementação usa UUID porque ao tentar usar `doctors.id` (INTEGER) ocorriam erros de permissão/RLS ao salvar testes em nome do paciente. Usar o UUID do auth (`auth.users.id`) resolveu o problema, permitindo que médicos salvem resultados corretamente com a referência ao usuário autenticado.

### Detecção de Tipo de Usuário
Após login, verificar se existe registro em `doctors`:
```sql
SELECT crm FROM doctors WHERE user_id = '{user_id}' LIMIT 1;
```
- Se retornar: usuário é médico
- Se vazio: usuário é paciente

---

## 10. Documentação de Referência

- **Supabase Auth Docs**: https://supabase.com/docs/guides/auth
- **Supabase Database Docs**: https://supabase.com/docs/guides/database
- **PostgreSQL RPC**: https://supabase.com/docs/guides/database/functions
- **Row Level Security**: https://supabase.com/docs/guides/auth/row-level-security

---

**Versão da Especificação**: 2.0  
**Data**: 24 de Novembro de 2025  
**Projeto**: Memento - Testes Cognitivos Digitais