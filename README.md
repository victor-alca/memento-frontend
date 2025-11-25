# Memento - Testes Cognitivos Digitais 🧠

Aplicativo mobile para aplicação e acompanhamento de testes cognitivos (Stroop Test, Trail Making Test e Teste de Memória Verbal), desenvolvido com Flutter e Supabase.

---

## 📋 Índice

1. [Início Rápido](#-início-rápido)
2. [Instalação e Configuração](#-instalação-e-configuração)
   - [Frontend (Flutter)](#1-frontend-flutter)
   - [Backend (Supabase)](#2-backend-supabase)
3. [Build do APK](#-build-do-apk)
4. [Configuração de Email SMTP](#-configuração-de-email-smtp)
5. [Estrutura do Projeto](#-estrutura-do-projeto)
6. [Documentação da API](#-documentação-da-api)

---

## 🚀 Início Rápido

### Usando o Supabase do TCC (Padrão)

Se você apenas quer testar o app:

1. **Clone o repositório**
   ```bash
   git clone https://github.com/victor-alca/memento-frontend.git
   cd memento-frontend
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Execute o app**
   ```bash
   flutter run
   ```

O app já está configurado para conectar ao Supabase usado no TCC. Você pode começar a usar imediatamente!

---

## 🛠️ Instalação e Configuração

### 1. Frontend (Flutter)

#### Pré-requisitos

- **Flutter SDK** 3.7.2 ou superior
  - [Download e instalação](https://docs.flutter.dev/get-started/install)
  - Verifique: `flutter --version`

- **Android Studio** (para desenvolvimento Android)
  - [Download](https://developer.android.com/studio)
  - Configure o Android SDK

- **Xcode** (para desenvolvimento iOS - apenas macOS)
  - [Download na App Store](https://apps.apple.com/br/app/xcode/id497799835)

#### Passos de Instalação

1. **Clone o repositório**
   ```bash
   git clone https://github.com/victor-alca/memento-frontend.git
   cd memento-frontend
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Verifique dispositivos disponíveis**
   ```bash
   flutter devices
   ```

4. **Execute em modo debug**
   ```bash
   # Android
   flutter run

   # iOS (apenas macOS)
   flutter run -d ios
   ```

---

### 2. Backend (Supabase)

Se você quer criar seu próprio backend Supabase:

#### Passo 1: Criar Projeto no Supabase

1. Acesse [supabase.com](https://supabase.com)
2. Crie uma conta ou faça login
3. Clique em **"New Project"**
4. Preencha:
   - **Name**: memento-backend
   - **Database Password**: (anote essa senha!)
   - **Region**: escolha a mais próxima
5. Aguarde o provisionamento (~2 minutos)

#### Passo 2: Executar Script SQL

1. No painel do Supabase, vá em **SQL Editor** (menu lateral)
2. Clique em **"New query"**
3. Copie todo o conteúdo do arquivo [`supabase.md`](./supabase.md)
4. Cole no editor SQL
5. Clique em **"Run"** (ou pressione Ctrl/Cmd + Enter)

O script irá criar:
- ✅ Todas as tabelas (users, patients, doctors, tests, patient_tests, doctor_access)
- ✅ Sequências e constraints
- ✅ Funções RPC (search_user_by_email, get_doctor_patients, etc)
- ✅ Triggers automáticos
- ✅ Políticas de segurança (Row Level Security)
- ✅ Dados iniciais (3 tipos de testes)

#### Passo 3: Obter Credenciais

1. No Supabase, vá em **Settings** → **API**
2. Anote:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

#### Passo 4: Configurar no Flutter

Edite o arquivo `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'SUA_PROJECT_URL_AQUI',
  anonKey: 'SUA_ANON_KEY_AQUI',
);
```

**Exemplo:**
```dart
await Supabase.initialize(
  url: 'https://abcdefgh.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODQwMDAwMDAsImV4cCI6MTg0MTk5OTk5OX0.XXXXX',
);
```

#### Passo 5: Configurar Deep Links (Opcional)

Para funcionalidades de confirmação de acesso e recuperação de senha:

1. No Supabase, vá em **Authentication** → **URL Configuration**
2. Em **Redirect URLs**, adicione:
   ```
   io.supabase.memento://**
   ```
3. Clique em **Save**

---

## 📦 Build do APK

### Android (APK/AAB)

#### Debug APK (para testes)
```bash
flutter build apk --debug
```
📁 Output: `build/app/outputs/flutter-apk/app-debug.apk`

#### Release APK (para distribuição)
```bash
flutter build apk --release
```
📁 Output: `build/app/outputs/flutter-apk/app-release.apk`

#### App Bundle (para Google Play Store)
```bash
flutter build appbundle --release
```
📁 Output: `build/app/outputs/bundle/release/app-release.aab`

#### Instalar APK no dispositivo
```bash
# Via USB (ative "Depuração USB" no Android)
flutter install

# Ou manualmente
adb install build/app/outputs/flutter-apk/app-release.apk
```

### iOS (IPA)

```bash
flutter build ios --release
```

Para gerar o IPA, abra o projeto no Xcode:
```bash
open ios/Runner.xcworkspace
```

---

## 📧 Configuração de Email SMTP

Por padrão, o Supabase limita envio de emails para **3-4 por hora** no plano gratuito. Para enviar mais emails (confirmações, boas-vindas, recuperação de senha), configure um provedor SMTP externo.

### Opções de Provedores SMTP

| Provedor | Emails Grátis/Dia | Configuração |
|----------|-------------------|--------------|
| **SendGrid** | 100/dia | [Guia](https://sendgrid.com/docs/for-developers/sending-email/integrations/) |
| **Mailgun** | 100/dia | [Guia](https://documentation.mailgun.com/en/latest/quickstart.html) |
| **AWS SES** | 200/dia (sandbox) | [Guia](https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp.html) |

### Configurar SMTP no Supabase

1. No Supabase, vá em **Settings** → **Auth** → **SMTP Settings**

2. Ative **"Enable Custom SMTP"**

3. Preencha as credenciais:

   **Exemplo com Gmail** (requer senha de app):
   ```
   Host: smtp.gmail.com
   Port: 587
   Username: seu.email@gmail.com
   Password: xxxx xxxx xxxx xxxx (senha de app)
   Sender name: Memento
   Sender email: seu.email@gmail.com
   ```

   **Exemplo com SendGrid**:
   ```
   Host: smtp.sendgrid.net
   Port: 587
   Username: apikey
   Password: SG.xxxxxxxxxxxxxxxxxxxx (API Key)
   Sender name: Memento
   Sender email: noreply@seudominio.com
   ```

4. Clique em **Save**

5. Teste enviando um email de recuperação de senha pelo app

### Configurar Senha de App (Gmail)

Se usar Gmail:

1. Acesse [myaccount.google.com/security](https://myaccount.google.com/security)
2. Ative **"Verificação em duas etapas"**
3. Vá em **"Senhas de app"**
4. Gere uma senha para "Email"
5. Use essa senha de 16 caracteres no Supabase

---

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                          # Entry point
├── app/
│   ├── app.dart                       # App widget
│   ├── config/                        # Configurações
│   ├── provider/                      # State management
│   ├── router/                        # Rotas e navegação
│   └── theme/                         # Temas e estilos
├── core/
│   ├── services/                      # Serviços globais (email)
│   ├── utils/                         # Utilitários
│   └── widgets/                       # Widgets reutilizáveis
└── features/
    ├── auth/                          # Autenticação
    │   ├── models/                    # UserModel
    │   ├── service/                   # AuthService
    │   └── presentation/
    │       └── pages/                 # Login, SignUp, ForgotPassword
    ├── account/                       # Configurações de conta
    │   └── presentation/
    │       ├── pages/                 # EditAccount, ChangePassword
    │       └── service/               # AccountService
    ├── patients/                      # Gestão de pacientes
    │   ├── models/                    # PatientModel
    │   ├── service/                   # PatientService (RPC calls)
    │   └── presentation/
    │       ├── pages/                 # PatientsList, AddPatient, Confirm
    │       └── widgets/               # PatientOptionsDialog
    └── tests/                         # Testes cognitivos
        ├── presentation/
        │   ├── models/                # ResultadoTesteArgs
        │   ├── pages/                 # Stroop, TMT A/B, Memória
        │   │   ├── stroop_test.dart
        │   │   ├── teste_tmt_a.dart
        │   │   ├── teste_tmt_b.dart
        │   │   ├── teste_memoria.dart
        │   │   ├── resultado_teste.dart
        │   │   └── line_chart.dart    # Dashboard/histórico
        │   └── services/
        │       └── test_result_service.dart
```

### Arquitetura

- **Padrão**: Feature-first + Clean Architecture (simplificado)
- **State Management**: Provider
- **Navegação**: go_router
- **Database**: Supabase (PostgreSQL + Row Level Security)
- **Auth**: Supabase Auth (JWT)

---

## 📚 Documentação da API

A especificação completa da API está em [`especificacao.md`](./especificacao.md).

### Principais Endpoints

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/auth/v1/signup` | POST | Criar conta |
| `/auth/v1/token` | POST | Login |
| `/auth/v1/recover` | POST | Recuperar senha |
| `/rest/v1/rpc/get_doctor_patients` | POST | Listar pacientes do médico |
| `/rest/v1/rpc/search_user_by_email` | POST | Buscar paciente por email |
| `/rest/v1/rpc/confirm_patient_access` | POST | Confirmar vínculo médico-paciente |
| `/rest/v1/patient_tests` | POST | Salvar resultado de teste |
| `/rest/v1/patient_tests` | GET | Listar resultados de testes |

### Tipos de Testes

| ID | Nome | Descrição | Métrica |
|----|------|-----------|---------|
| 1 | Stroop Test | Teste de cores e palavras | Acertos (50 itens) |
| 2 | Trail Making Test | Conectar números/letras | Tempo total |
| 3 | Memória Verbal | Recordação de palavras | Acertos (20 palavras) |

---

## 🔧 Troubleshooting

### Erro: "Bad state: Supabase has not been initialized"

**Solução**: Verifique se `Supabase.initialize()` está sendo chamado em `main.dart` antes de `runApp()`.

### Erro: "Invalid JWT"

**Solução**: O token expirou (1 hora de validade). Faça logout e login novamente.

### Emails não estão sendo enviados

**Solução**: 
1. Verifique se configurou SMTP customizado no Supabase
2. Limite padrão é 3-4 emails/hora sem SMTP configurado
3. Veja seção [Configuração de Email SMTP](#-configuração-de-email-smtp)

### Erro ao conectar no Supabase

**Solução**: Verifique se a URL e anon key em `main.dart` estão corretas.

### Build falha no Android

**Solução**:
```bash
flutter clean
flutter pub get
flutter build apk --release
```
---

**Última atualização**: Novembro 2025
