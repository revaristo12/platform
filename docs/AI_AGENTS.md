# 🤖 Arquitetura dos Agentes de IA

Este documento descreve a arquitetura e funcionamento dos agentes de IA da plataforma.

---

## 📋 Visão Geral

O sistema possui dois agentes principais que trabalham em conjunto:

1. **Agente de Transcrição** - Converte áudio em texto
2. **Agente de Análise** - Analisa o texto e gera insights

---

## 🎙️ Agente de Transcrição

### Responsabilidades

- Captura áudio em tempo real das reuniões
- Transcreve áudio para texto usando Whisper
- Identifica falantes (diarização)
- Armazena transcrições com timestamps

### Fluxo de Funcionamento

```
[Áudio WebRTC] 
    ↓
[Captura Stream]
    ↓
[Buffer de Áudio (chunks)]
    ↓
[Whisper API/Local]
    ↓
[Texto Transcrito]
    ↓
[Identificação de Falante]
    ↓
[PostgreSQL + Redis]
```

### Implementação Sugerida

**Localização:** `backend/app/agents/transcription_agent.py`

```python
class TranscriptionAgent:
    """
    Agente responsável por transcrição de áudio
    """
    
    def __init__(self):
        self.whisper_model = whisper.load_model("base")
        self.audio_buffer = []
        self.is_transcribing = False
    
    async def process_audio_chunk(self, audio_data, room_id):
        """
        Processa chunk de áudio e transcreve
        """
        # 1. Adiciona ao buffer
        self.audio_buffer.append(audio_data)
        
        # 2. Quando buffer está cheio (ex: 3 segundos)
        if len(self.audio_buffer) >= CHUNK_SIZE:
            audio_segment = self.concatenate_chunks()
            
            # 3. Envia para Celery task (assíncrono)
            transcribe_task.delay(
                audio_segment,
                room_id
            )
            
            # 4. Limpa buffer
            self.audio_buffer.clear()
    
    def transcribe(self, audio_path):
        """
        Transcreve áudio usando Whisper
        """
        result = self.whisper_model.transcribe(
            audio_path,
            language="pt",
            task="transcribe"
        )
        
        return {
            "text": result["text"],
            "segments": result["segments"],
            "language": result["language"]
        }
    
    def identify_speaker(self, audio_segment):
        """
        Identifica falante usando diarização
        (implementar com pyannote.audio)
        """
        pass
```

### Celery Task

**Localização:** `backend/app/agents/tasks/transcription.py`

```python
@celery_app.task
def transcribe_task(audio_data, room_id):
    """
    Task assíncrona de transcrição
    """
    # 1. Salva áudio temporário
    temp_path = save_temp_audio(audio_data)
    
    # 2. Transcreve
    agent = TranscriptionAgent()
    result = agent.transcribe(temp_path)
    
    # 3. Salva no banco
    for segment in result["segments"]:
        Transcription.create(
            room_id=room_id,
            text=segment["text"],
            start_time=segment["start"],
            end_time=segment["end"],
            confidence=segment.get("confidence")
        )
    
    # 4. Notifica via WebSocket
    notify_new_transcription(room_id, result)
    
    # 5. Trigger análise se necessário
    if should_trigger_analysis():
        analysis_task.delay(room_id)
    
    # 6. Limpa arquivo temporário
    os.remove(temp_path)
```

### Otimizações

1. **Streaming Transcription**
   - Usar buffer circular
   - Transcrever em chunks pequenos (2-3 segundos)
   - Combinar resultados com overlap

2. **Local vs API**
   - Local: Whisper rodando no container (mais lento, sem custo)
   - API: OpenAI Whisper API (mais rápido, com custo)
   - Configurável via `.env`

3. **Diarização de Falantes**
   - Usar `pyannote.audio`
   - Treinar modelo customizado se necessário
   - Armazenar embeddings de voz

---

## 🧠 Agente de Análise

### Responsabilidades

- Lê transcrições acumuladas
- Analisa contexto e identifica:
  - Riscos e problemas
  - Decisões tomadas
  - Gaps de governança
  - Ações necessárias
- Gera insights e recomendações
- Avalia nível de criticidade

### Fluxo de Funcionamento

```
[Transcrições acumuladas]
    ↓
[Trigger de Análise]
    ↓
[Agregação de Texto]
    ↓
[Prompt Engineering]
    ↓
[Claude/GPT API]
    ↓
[Parsing de Resposta]
    ↓
[Estruturação de Insights]
    ↓
[PostgreSQL + Notificações]
```

### Implementação Sugerida

**Localização:** `backend/app/agents/analysis_agent.py`

```python
class AnalysisAgent:
    """
    Agente de análise com IA para governança e crises
    """
    
    def __init__(self):
        self.llm = self.initialize_llm()
        self.system_prompt = self.load_system_prompt()
    
    def initialize_llm(self):
        """
        Inicializa Claude ou GPT
        """
        if settings.USE_CLAUDE:
            from anthropic import Anthropic
            return Anthropic(api_key=settings.ANTHROPIC_API_KEY)
        else:
            from openai import OpenAI
            return OpenAI(api_key=settings.OPENAI_API_KEY)
    
    async def analyze_meeting(self, room_id):
        """
        Analisa reunião completa
        """
        # 1. Busca transcrições
        transcriptions = await self.get_transcriptions(room_id)
        
        # 2. Prepara contexto
        context = self.prepare_context(transcriptions)
        
        # 3. Analisa com IA
        analysis = await self.run_analysis(context)
        
        # 4. Estrutura resultados
        structured = self.structure_analysis(analysis)
        
        # 5. Salva no banco
        await self.save_analysis(room_id, structured)
        
        # 6. Envia notificações se necessário
        if structured["risk_level"] in ["high", "critical"]:
            await self.notify_stakeholders(room_id, structured)
        
        return structured
    
    def load_system_prompt(self):
        """
        Carrega prompt do sistema
        """
        return """
        Você é um especialista em gestão de crises, governança corporativa 
        e análise de riscos empresariais. Sua função é analisar transcrições 
        de reuniões e identificar:
        
        1. RISCOS E PROBLEMAS
           - Identificar riscos mencionados
           - Avaliar gravidade (baixa, média, alta, crítica)
           - Classificar tipo (operacional, financeiro, reputacional, etc)
        
        2. DECISÕES TOMADAS
           - Listar decisões explícitas
           - Identificar responsáveis
           - Notar prazos mencionados
        
        3. GAPS DE GOVERNANÇA
           - Processos inexistentes ou falhos
           - Falta de controles
           - Problemas de comunicação
        
        4. AÇÕES NECESSÁRIAS
           - Action items identificados
           - Responsáveis sugeridos
           - Priorização
        
        5. RECOMENDAÇÕES
           - Planos de mitigação
           - Melhorias de processo
           - Controles a implementar
        
        Forneça a análise em formato JSON estruturado.
        """
    
    def prepare_context(self, transcriptions):
        """
        Prepara contexto para análise
        """
        # Agrupa por falante
        speakers_text = {}
        for trans in transcriptions:
            speaker = trans.speaker_label or "Unknown"
            if speaker not in speakers_text:
                speakers_text[speaker] = []
            speakers_text[speaker].append(trans.text)
        
        # Formata contexto
        context = "=== TRANSCRIÇÃO DA REUNIÃO ===\n\n"
        for speaker, texts in speakers_text.items():
            context += f"{speaker}:\n"
            context += "\n".join(texts)
            context += "\n\n"
        
        return context
    
    async def run_analysis(self, context):
        """
        Executa análise com LLM
        """
        if isinstance(self.llm, Anthropic):
            # Claude
            response = self.llm.messages.create(
                model="claude-3-opus-20240229",
                max_tokens=4096,
                system=self.system_prompt,
                messages=[
                    {
                        "role": "user",
                        "content": f"{context}\n\nAnalise esta reunião:"
                    }
                ]
            )
            return response.content[0].text
        else:
            # GPT
            response = self.llm.chat.completions.create(
                model="gpt-4-turbo-preview",
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": f"{context}\n\nAnalise:"}
                ]
            )
            return response.choices[0].message.content
    
    def structure_analysis(self, raw_analysis):
        """
        Estrutura análise em formato padrão
        """
        # Parse JSON da resposta
        analysis = json.loads(raw_analysis)
        
        return {
            "risks": analysis.get("risks", []),
            "decisions": analysis.get("decisions", []),
            "governance_gaps": analysis.get("governance_gaps", []),
            "action_items": analysis.get("action_items", []),
            "recommendations": analysis.get("recommendations", []),
            "risk_level": self.calculate_risk_level(analysis),
            "summary": analysis.get("summary", ""),
            "key_topics": analysis.get("key_topics", [])
        }
```

### Celery Task

**Localização:** `backend/app/agents/tasks/analysis.py`

```python
@celery_app.task
def analysis_task(room_id):
    """
    Task assíncrona de análise
    """
    agent = AnalysisAgent()
    
    try:
        # Executa análise
        result = asyncio.run(
            agent.analyze_meeting(room_id)
        )
        
        # Notifica usuários via WebSocket
        notify_new_analysis(room_id, result)
        
        return result
        
    except Exception as e:
        logger.error(f"Error in analysis: {e}")
        raise
```

### Triggers de Análise

A análise pode ser disparada por:

1. **Intervalo de Tempo** (ex: a cada 5 minutos)
2. **Número de Palavras** (ex: a cada 500 palavras)
3. **Palavras-chave** (ex: "crise", "risco", "problema")
4. **Manual** (botão no frontend)
5. **Fim da Reunião**

```python
def should_trigger_analysis(room_id):
    """
    Decide se deve disparar análise
    """
    last_analysis = get_last_analysis(room_id)
    new_transcriptions = get_transcriptions_since(
        room_id, 
        last_analysis.created_at
    )
    
    # Trigger por palavras
    word_count = sum(len(t.text.split()) for t in new_transcriptions)
    if word_count >= 500:
        return True
    
    # Trigger por tempo
    time_since = datetime.now() - last_analysis.created_at
    if time_since.total_seconds() >= 300:  # 5 minutos
        return True
    
    # Trigger por palavras-chave
    keywords = ["crise", "risco", "urgente", "problema crítico"]
    text = " ".join(t.text for t in new_transcriptions).lower()
    if any(kw in text for kw in keywords):
        return True
    
    return False
```

---

## 🔄 Integração dos Agentes

### Fluxo Completo

```
[Usuário fala na reunião]
           ↓
[WebRTC Stream → Backend]
           ↓
[TranscriptionAgent.process_audio_chunk()]
           ↓
[Celery: transcribe_task]
           ↓
[Salva no DB + Notifica WebSocket]
           ↓
[Verifica: should_trigger_analysis()?]
           ↓ (se sim)
[Celery: analysis_task]
           ↓
[AnalysisAgent.analyze_meeting()]
           ↓
[Salva insights + Notifica]
           ↓
[Dashboard atualizado em tempo real]
```

---

## 🎛️ Configurações

### `.env`

```env
# Transcrição
WHISPER_MODEL=base              # tiny, base, small, medium, large
TRANSCRIPTION_LANGUAGE=pt
ENABLE_SPEAKER_DIARIZATION=True
MIN_SPEAKERS=1
MAX_SPEAKERS=10

# Análise
AI_ANALYSIS_ENABLED=True
AI_ANALYSIS_INTERVAL=300        # segundos
AI_ANALYSIS_MIN_WORDS=100
USE_CLAUDE=True                 # True para Claude, False para GPT
CLAUDE_MODEL=claude-3-opus-20240229
OPENAI_MODEL=gpt-4-turbo-preview
```

---

## 📊 Exemplos de Output

### Transcrição

```json
{
  "id": "uuid",
  "room_id": "uuid",
  "speaker_label": "Speaker_1",
  "text": "Estamos enfrentando um problema crítico...",
  "confidence": 0.95,
  "start_time": 125.3,
  "end_time": 128.7,
  "created_at": "2024-01-15T10:30:00Z"
}
```

### Análise

```json
{
  "id": "uuid",
  "room_id": "uuid",
  "risk_level": "high",
  "summary": "Reunião identificou crise operacional...",
  "risks": [
    {
      "description": "Sistema de pagamentos instável",
      "severity": "high",
      "type": "operational",
      "mentioned_at": "10:25"
    }
  ],
  "decisions": [
    {
      "decision": "Contratar empresa terceirizada",
      "responsible": "João Silva",
      "deadline": "2024-01-20"
    }
  ],
  "governance_gaps": [
    "Falta de processo de backup",
    "Comunicação inadequada entre times"
  ],
  "action_items": [
    {
      "action": "Implementar monitoramento 24/7",
      "priority": "critical",
      "responsible": "TI",
      "deadline": "Imediato"
    }
  ],
  "recommendations": [
    "Estabelecer comitê de crise",
    "Criar plano de contingência",
    "Revisar SLAs com fornecedores"
  ],
  "created_at": "2024-01-15T10:35:00Z"
}
```

---

## 🚀 Próximos Passos

1. Implementar `TranscriptionAgent`
2. Implementar `AnalysisAgent`
3. Criar Celery tasks
4. Testar com áudio real
5. Ajustar prompts para melhor qualidade
6. Implementar diarização de falantes
7. Criar dashboard de visualização

---

**Documentação técnica dos agentes de IA - Meeting AI Platform**
